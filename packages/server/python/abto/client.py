"""Thin server facade: gateway baseURL + ABTO header injection.

It does not compute token/cost/latency. It routes provider SDK calls through the
ABTO Gateway and carries the x-abto-* identifiers from the current context.
"""

from __future__ import annotations

import math
import os
import threading
import time
from dataclasses import dataclass
from email.utils import parsedate_to_datetime
from typing import Any, Callable, Dict, List, Mapping, MutableMapping, Optional, Tuple, Union
from urllib.parse import SplitResult, urlsplit

from .context import AbtoContext, create_trace_id, get_headers, with_context

DEFAULT_GATEWAY_BASE_URL = "https://gateway.abto.app/v1"
_OPENAI_BASE_URL = "https://api.openai.com/v1"
_CIRCUIT_OPEN_SECONDS = 30.0
_RETRYABLE_OPENAI_STATUSES = {408, 409, 429}
_DIRECT_HEADER_NAMES = {
    "accept",
    "content-type",
    "idempotency-key",
    "user-agent",
}
_UNSET = object()
_RESOLVED_PROVIDER_HEADERS_KEY = "abto.resolved_provider_headers"
_RESOLVED_PROVIDER_HEADERS_TOKEN = object()
ProviderKeyValue = Union[str, Callable[[], Optional[str]]]
ProviderKeys = Mapping[str, ProviderKeyValue]
_PROVIDERS = ("openai", "anthropic", "gemini")


@dataclass(frozen=True)
class OpenAIDirectFallbackOptions:
    """안전하게 판별 가능한 Gateway 장애의 OpenAI direct fallback 설정."""

    enabled: Optional[bool] = None
    max_retries: int = 2
    timeout_seconds: float = 30.0
    on_timeout: bool = False


OpenAIDirectFallbackConfig = Union[bool, OpenAIDirectFallbackOptions]


@dataclass(frozen=True)
class _ResolvedFallback:
    enabled: bool
    max_retries: int
    timeout_seconds: float
    on_timeout: bool


def _resolve_fallback(
    config: Optional[OpenAIDirectFallbackConfig],
    *,
    has_openai_key_source: bool,
) -> _ResolvedFallback:
    if isinstance(config, bool):
        options = OpenAIDirectFallbackOptions(enabled=config)
    elif config is None:
        options = OpenAIDirectFallbackOptions()
    elif isinstance(config, OpenAIDirectFallbackOptions):
        options = config
    else:
        raise TypeError(
            "[abto] fallback must be a bool or OpenAIDirectFallbackOptions."
        )
    if (
        not isinstance(options.max_retries, int)
        or isinstance(options.max_retries, bool)
        or options.max_retries < 0
        or options.max_retries > 5
    ):
        raise ValueError("[abto] fallback.max_retries must be an integer between 0 and 5.")
    if (
        not math.isfinite(options.timeout_seconds)
        or options.timeout_seconds <= 0
    ):
        raise ValueError("[abto] fallback.timeout_seconds must be greater than 0.")
    return _ResolvedFallback(
        enabled=options.enabled
        if options.enabled is not None
        else has_openai_key_source,
        max_retries=options.max_retries,
        timeout_seconds=float(options.timeout_seconds),
        on_timeout=options.on_timeout,
    )


def _validated_gateway_url(value: str) -> str:
    parsed = urlsplit(value)
    if (
        parsed.scheme not in {"http", "https"}
        or not parsed.hostname
        or parsed.username is not None
        or parsed.password is not None
    ):
        raise ValueError("[abto] gateway_base_url must be a valid http(s) URL.")
    return value.rstrip("/")


def _origin(value: Any) -> Tuple[str, str, int]:
    parsed: SplitResult = urlsplit(str(value))
    if parsed.scheme not in {"http", "https"} or not parsed.hostname:
        raise ValueError("[abto] Gateway request URL is invalid.")
    default_port = 443 if parsed.scheme == "https" else 80
    return parsed.scheme, parsed.hostname.lower(), parsed.port or default_port


def _validated_api_key(value: str) -> str:
    resolved = value.strip()
    if not resolved:
        raise ValueError("[abto] api_key or ABTO_API_KEY is required.")
    if "\r" in resolved or "\n" in resolved:
        raise ValueError("[abto] api_key contains invalid characters.")
    return resolved


def resolve_provider_headers(provider_keys: Optional[ProviderKeys] = None) -> Dict[str, str]:
    """Return Gateway candidate-key headers for the supported provider ids."""

    headers: Dict[str, str] = {}
    for provider in _PROVIDERS:
        source = (provider_keys or {}).get(provider)
        value = source() if callable(source) else source
        if value is None:
            continue
        trimmed = value.strip()
        if not trimmed:
            continue
        if "\r" in trimmed or "\n" in trimmed:
            raise ValueError(f"[abto] provider key for {provider} contains invalid characters.")
        headers[f"x-abto-key-{provider}"] = trimmed
    return headers


def _remove_header(headers: MutableMapping[str, str], name: str) -> None:
    for key in list(headers.keys()):
        if key.lower() == name.lower():
            del headers[key]


def abto_request_hook(
    gateway_base_url: str,
    *,
    api_key: str,
    provider_keys: Optional[ProviderKeys] = None,
) -> Callable[[Any], None]:
    """Inject trusted Gateway credentials and request context for one origin."""

    gateway_origin = _origin(_validated_gateway_url(gateway_base_url))
    trusted_api_key = _validated_api_key(api_key)

    def hook(request: Any) -> None:
        if _origin(request.url) != gateway_origin:
            raise ValueError(
                "[abto] Refusing to send ABTO context outside the configured Gateway origin."
            )
        trusted_headers = get_headers()
        for name in ("authorization", "x-abto-device-id", "x-abto-node-key", "traceparent"):
            _remove_header(request.headers, name)
        for name in list(request.headers.keys()):
            if name.lower().startswith("x-abto-key-"):
                del request.headers[name]
        extensions = getattr(request, "extensions", {})
        cached_provider_headers = extensions.pop(
            _RESOLVED_PROVIDER_HEADERS_KEY,
            _UNSET,
        )
        if (
            isinstance(cached_provider_headers, tuple)
            and len(cached_provider_headers) == 2
            and cached_provider_headers[0] is _RESOLVED_PROVIDER_HEADERS_TOKEN
        ):
            resolved_provider_headers = cached_provider_headers[1]
        else:
            resolved_provider_headers = resolve_provider_headers(provider_keys)
        for key, value in resolved_provider_headers.items():
            request.headers[key] = value
        for key, value in trusted_headers.items():
            request.headers[key] = value
        request.headers["Authorization"] = f"Bearer {trusted_api_key}"

    return hook


def _direct_openai_url(value: Any, gateway_base_url: str) -> Optional[str]:
    if _origin(value) != _origin(gateway_base_url):
        return None
    request_url = urlsplit(str(value))
    gateway_url = urlsplit(gateway_base_url)
    base_path = gateway_url.path.rstrip("/") + "/"
    if not request_url.path.startswith(base_path):
        return None
    suffix = request_url.path[len(base_path) :]
    if suffix != "chat/completions":
        return None
    direct = f"{_OPENAI_BASE_URL}/{suffix}"
    if request_url.query:
        direct += f"?{request_url.query}"
    return direct


def _openai_key_from_headers(headers: Mapping[str, str]) -> Optional[str]:
    for name, value in headers.items():
        if name.lower() == "x-abto-key-openai":
            resolved = value.strip()
            return resolved or None
    return None


def _direct_headers(headers: Mapping[str, str], openai_key: str) -> Dict[str, str]:
    direct: Dict[str, str] = {}
    for name, value in headers.items():
        normalized = name.lower()
        if (
            normalized in _DIRECT_HEADER_NAMES
            or normalized.startswith("openai-")
            or normalized.startswith("x-stainless-")
        ):
            direct[name] = value
    direct["Authorization"] = f"Bearer {openai_key}"
    return direct


def _safe_gateway_response(response: Any) -> bool:
    request_id = response.headers.get("x-request-id")
    error_source = response.headers.get("x-abto-error-source")
    if request_id is None and response.status_code in {502, 503, 504}:
        return True
    return (
        response.status_code == 503
        and request_id is not None
        and error_source is None
    )


def _retry_after_seconds(response: Any, attempt: int) -> float:
    raw = response.headers.get("retry-after")
    if raw is not None:
        try:
            return min(max(float(raw), 0.0), 60.0)
        except ValueError:
            try:
                date = parsedate_to_datetime(raw)
                return min(max(date.timestamp() - time.time(), 0.0), 60.0)
            except (TypeError, ValueError, OverflowError):
                pass
    return min(0.5 * (2**attempt), 8.0)


class _CircuitBreaker:
    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._opened_at: Optional[float] = None
        self._half_open = False

    def should_bypass(self) -> bool:
        with self._lock:
            if self._opened_at is None:
                return False
            if (
                time.monotonic() - self._opened_at < _CIRCUIT_OPEN_SECONDS
                or self._half_open
            ):
                return True
            self._half_open = True
            return False

    def open(self) -> None:
        with self._lock:
            self._opened_at = time.monotonic()
            self._half_open = False

    def close(self) -> None:
        with self._lock:
            self._opened_at = None
            self._half_open = False

    def release_half_open_probe(self) -> None:
        with self._lock:
            self._half_open = False


def _build_fallback_http_client(
    httpx: Any,
    *,
    gateway_base_url: str,
    api_key: str,
    provider_keys: Optional[ProviderKeys],
    fallback: _ResolvedFallback,
    gateway_transport: Any = None,
    direct_transport: Any = None,
    direct_timeout: Any = _UNSET,
    circuit: Optional[_CircuitBreaker] = None,
) -> Any:
    normal_timeout = (
        direct_timeout
        if direct_timeout is not _UNSET
        else httpx.Timeout(600.0, connect=5.0)
    )
    event_hooks = {
        "request": [
            abto_request_hook(
                gateway_base_url,
                api_key=api_key,
                provider_keys=provider_keys,
            )
        ]
    }

    class CircuitResponseStream(httpx.SyncByteStream):
        def __init__(self, stream: Any, circuit: _CircuitBreaker) -> None:
            self._stream = stream
            self._circuit = circuit

        def __iter__(self):
            try:
                yield from self._stream
            except httpx.RequestError:
                self._circuit.open()
                raise

        def close(self) -> None:
            self._stream.close()

    class GatewayFallbackClient(httpx.Client):
        def __init__(self) -> None:
            super().__init__(
                event_hooks=event_hooks,
                timeout=normal_timeout,
                transport=gateway_transport,
            )
            self._direct_client = httpx.Client(
                timeout=normal_timeout,
                transport=direct_transport,
            )
            self._circuit = circuit or _CircuitBreaker()
            self._fallback_timeout = httpx.Timeout(fallback.timeout_seconds)

        def close(self) -> None:
            try:
                self._direct_client.close()
            finally:
                super().close()

        def _send_gateway_headers(
            self,
            request: Any,
            *,
            auth: Any,
            follow_redirects: Any,
            header_timeout: Any = None,
        ) -> Any:
            caller_timeout = request.extensions.get(
                "timeout",
                self.timeout.as_dict(),
            )
            if header_timeout is not None:
                request.extensions["timeout"] = header_timeout
            try:
                response = super().send(
                    request,
                    stream=True,
                    auth=auth,
                    follow_redirects=follow_redirects,
                )
            finally:
                request.extensions["timeout"] = caller_timeout
            response.stream = CircuitResponseStream(
                response.stream,
                self._circuit,
            )
            return response

        @staticmethod
        def _finish_gateway_response(response: Any, *, stream: bool) -> Any:
            if not stream:
                response.read()
            return response

        def _send_direct(
            self,
            request: Any,
            *,
            direct_url: str,
            openai_key: str,
            content: bytes,
            stream: bool,
        ) -> Any:
            last_error: Optional[BaseException] = None
            for attempt in range(fallback.max_retries + 1):
                direct_request = self._direct_client.build_request(
                    request.method,
                    direct_url,
                    headers=_direct_headers(request.headers, openai_key),
                    content=content,
                    extensions={
                        "timeout": request.extensions.get(
                            "timeout",
                            self._direct_client.timeout.as_dict(),
                        )
                    },
                )
                try:
                    response = self._direct_client.send(
                        direct_request,
                        stream=stream,
                    )
                except httpx.RequestError as error:
                    last_error = error
                    if attempt >= fallback.max_retries:
                        raise
                    time.sleep(min(0.5 * (2**attempt), 8.0))
                    continue
                if (
                    attempt < fallback.max_retries
                    and (
                        response.status_code in _RETRYABLE_OPENAI_STATUSES
                        or response.status_code >= 500
                    )
                ):
                    response.close()
                    time.sleep(_retry_after_seconds(response, attempt))
                    continue
                return response
            if last_error is not None:
                raise last_error
            raise RuntimeError("[abto] OpenAI direct fallback failed.")

        def send(
            self,
            request: Any,
            *,
            stream: bool = False,
            auth: Any = httpx.USE_CLIENT_DEFAULT,
            follow_redirects: Any = httpx.USE_CLIENT_DEFAULT,
        ) -> Any:
            direct_url = _direct_openai_url(request.url, gateway_base_url)
            eligible = (
                fallback.enabled
                and direct_url is not None
                and request.method == "POST"
            )

            if not eligible:
                return super().send(
                    request,
                    stream=stream,
                    auth=auth,
                    follow_redirects=follow_redirects,
                )

            provider_headers = resolve_provider_headers(provider_keys)
            request.extensions[_RESOLVED_PROVIDER_HEADERS_KEY] = (
                _RESOLVED_PROVIDER_HEADERS_TOKEN,
                provider_headers,
            )
            openai_key = _openai_key_from_headers(provider_headers)
            if openai_key is None:
                try:
                    response = self._send_gateway_headers(
                        request,
                        auth=auth,
                        follow_redirects=follow_redirects,
                    )
                except httpx.PoolTimeout:
                    self._circuit.release_half_open_probe()
                    raise
                except httpx.RequestError:
                    self._circuit.open()
                    raise
                if _safe_gateway_response(response):
                    self._circuit.open()
                else:
                    self._circuit.close()
                return self._finish_gateway_response(
                    response,
                    stream=stream,
                )

            content = request.read()

            if self._circuit.should_bypass():
                return self._send_direct(
                    request,
                    direct_url=direct_url,
                    openai_key=openai_key,
                    content=content,
                    stream=stream,
                )

            try:
                response = self._send_gateway_headers(
                    request,
                    auth=auth,
                    follow_redirects=follow_redirects,
                    header_timeout=self._fallback_timeout.as_dict(),
                )
            except (httpx.ConnectError, httpx.ConnectTimeout):
                self._circuit.open()
                return self._send_direct(
                    request,
                    direct_url=direct_url,
                    openai_key=openai_key,
                    content=content,
                    stream=stream,
                )
            except (httpx.ReadTimeout, httpx.WriteTimeout):
                self._circuit.open()
                if fallback.on_timeout:
                    return self._send_direct(
                        request,
                        direct_url=direct_url,
                        openai_key=openai_key,
                        content=content,
                        stream=stream,
                    )
                raise
            except httpx.PoolTimeout:
                self._circuit.release_half_open_probe()
                raise
            except httpx.RequestError:
                self._circuit.open()
                raise

            if _safe_gateway_response(response):
                response.close()
                self._circuit.open()
                return self._send_direct(
                    request,
                    direct_url=direct_url,
                    openai_key=openai_key,
                    content=content,
                    stream=stream,
                )
            self._circuit.close()
            return self._finish_gateway_response(
                response,
                stream=stream,
            )

    return GatewayFallbackClient()


class Abto:
    def __init__(
        self,
        api_key: Optional[str] = None,
        gateway_base_url: Optional[str] = None,
        provider_keys: Optional[ProviderKeys] = None,
        fallback: Optional[OpenAIDirectFallbackConfig] = None,
    ) -> None:
        self.api_key = _validated_api_key(api_key or os.getenv("ABTO_API_KEY") or "")
        self._provider_keys = provider_keys if provider_keys is not None else {
            "openai": os.getenv("OPENAI_API_KEY"),
            "anthropic": os.getenv("ANTHROPIC_API_KEY"),
            "gemini": os.getenv("GEMINI_API_KEY"),
        }
        self.gateway_base_url = _validated_gateway_url(
            gateway_base_url
            or os.getenv("ABTO_GATEWAY_BASE_URL")
            or DEFAULT_GATEWAY_BASE_URL
        )
        self._fallback = _resolve_fallback(
            fallback,
            has_openai_key_source=self._provider_keys.get("openai") is not None,
        )
        self._fallback_circuit = _CircuitBreaker()

    def get_headers(self, ctx: Optional[AbtoContext] = None) -> Dict[str, str]:
        return get_headers(ctx)

    def with_context(self, **kwargs: Optional[str]):
        return with_context(**kwargs)

    def create_trace_id(self) -> str:
        return create_trace_id()

    def httpx_event_hooks(self) -> Dict[str, List[Callable[[Any], None]]]:
        return {
            "request": [
                abto_request_hook(
                    self.gateway_base_url,
                    api_key=self.api_key,
                    provider_keys=self._provider_keys,
                )
            ]
        }

    def openai(self, **client_kwargs: Any) -> Any:
        """Construct an OpenAI client pointed at the gateway with header injection.

        Requires the optional `openai` and `httpx` extras.
        """
        try:
            import httpx
            from openai import OpenAI
        except ImportError as exc:  # pragma: no cover - optional dependency
            raise ImportError("abto.openai() requires the 'openai' extra: pip install 'abto[openai]'") from exc

        reserved = {"api_key", "base_url", "http_client"}.intersection(client_kwargs)
        if reserved:
            names = ", ".join(sorted(reserved))
            raise ValueError(f"[abto] openai() does not allow overriding: {names}.")

        http_client = _build_fallback_http_client(
            httpx,
            gateway_base_url=self.gateway_base_url,
            api_key=self.api_key,
            provider_keys=self._provider_keys,
            fallback=self._fallback,
            circuit=self._fallback_circuit,
            direct_timeout=client_kwargs.get(
                "timeout",
                httpx.Timeout(600.0, connect=5.0),
            ),
        )
        client_kwargs["max_retries"] = 0
        return OpenAI(
            api_key=self.api_key,
            base_url=self.gateway_base_url,
            http_client=http_client,
            **client_kwargs,
        )


def init_abto(
    api_key: Optional[str] = None,
    gateway_base_url: Optional[str] = None,
    provider_keys: Optional[ProviderKeys] = None,
    fallback: Optional[OpenAIDirectFallbackConfig] = None,
) -> Abto:
    return Abto(
        api_key=api_key,
        gateway_base_url=gateway_base_url,
        provider_keys=provider_keys,
        fallback=fallback,
    )
