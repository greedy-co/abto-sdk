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
from typing import Any, Callable, Dict, List, Mapping, MutableMapping, Optional, Tuple, Union
from urllib.parse import SplitResult, urlsplit

from .context import AbtoContext, create_trace_id, get_headers, with_context
from .policy_generated import (
    CIRCUIT_OPEN_SECONDS as _CIRCUIT_OPEN_SECONDS,
    DEFAULT_FALLBACK_TIMEOUT_SECONDS,
    DIRECT_HEADER_NAMES as _DIRECT_HEADER_NAMES,
    DIRECT_HEADER_PREFIXES as _DIRECT_HEADER_PREFIXES,
    DIRECT_PATH_SUFFIX as _DIRECT_PATH_SUFFIX,
    PROVIDER_IDS as _PROVIDERS,
    SAFE_GATEWAY_STATUSES as _SAFE_GATEWAY_STATUSES,
)

PUBLIC_GATEWAY_BASE_URL = "https://gateway.abto.app/v1"
_UNSET = object()
_RESOLVED_PROVIDER_HEADERS_KEY = "abto.resolved_provider_headers"
_RESOLVED_PROVIDER_HEADERS_TOKEN = object()
ProviderKeyValue = Union[str, Callable[[], Optional[str]]]
ProviderKeys = Mapping[str, ProviderKeyValue]


@dataclass(frozen=True)
class OpenAIDirectFallbackOptions:
    """Configure OpenAI direct fallback for safely identifiable Gateway failures.

    `base_url` is the OpenAI-compatible endpoint this application used before
    adopting ABTO, for example "https://api.openai.com/v1" or your own proxy.
    Direct fallback sends the request there, so it must be the destination you
    already trust with this key. It is required to enable fallback: there is no
    default, because guessing the destination would send provider credentials to
    a host the application never chose. The endpoint must accept the OpenAI
    request path and `Authorization: Bearer`.
    """

    base_url: Optional[str] = None
    enabled: Optional[bool] = None
    timeout_seconds: float = DEFAULT_FALLBACK_TIMEOUT_SECONDS
    on_timeout: bool = False


OpenAIDirectFallbackConfig = Union[bool, OpenAIDirectFallbackOptions]


@dataclass(frozen=True)
class _ResolvedFallback:
    enabled: bool
    timeout_seconds: float
    on_timeout: bool
    base_url: Optional[str] = None


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
        not math.isfinite(options.timeout_seconds)
        or options.timeout_seconds <= 0
    ):
        raise ValueError("[abto] fallback.timeout_seconds must be greater than 0.")
    requested = (
        options.enabled if options.enabled is not None else has_openai_key_source
    )
    off = _ResolvedFallback(
        enabled=False,
        timeout_seconds=float(options.timeout_seconds),
        on_timeout=options.on_timeout,
    )
    if not requested:
        return off
    if options.base_url is None:
        # Asking for fallback without naming the destination is a configuration
        # error, not a default to guess: the provider key would leave for a host
        # the application never chose.
        if config is not None:
            raise ValueError(
                "[abto] fallback.base_url is required to enable OpenAI direct fallback. "
                "Set it to the OpenAI-compatible endpoint this application used before ABTO."
            )
        # Nothing was configured, so stay off rather than inventing a destination.
        return off
    return _ResolvedFallback(
        enabled=True,
        timeout_seconds=float(options.timeout_seconds),
        on_timeout=options.on_timeout,
        base_url=_validated_direct_base_url(options.base_url),
    )


def _validated_direct_base_url(value: str) -> str:
    parsed = urlsplit(value)
    if (
        parsed.scheme not in {"http", "https"}
        or not parsed.hostname
        or parsed.username is not None
        or parsed.password is not None
    ):
        raise ValueError("[abto] fallback.base_url must be a valid http(s) URL.")
    return value.rstrip("/")


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
        for name in ("authorization", "x-abto-device-id", "x-abto-feature-id", "traceparent"):
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


def _direct_openai_url(
    value: Any, gateway_base_url: str, fallback_base_url: Optional[str]
) -> Optional[str]:
    if fallback_base_url is None:
        return None
    if _origin(value) != _origin(gateway_base_url):
        return None
    request_url = urlsplit(str(value))
    gateway_url = urlsplit(gateway_base_url)
    base_path = gateway_url.path.rstrip("/") + "/"
    if not request_url.path.startswith(base_path):
        return None
    suffix = request_url.path[len(base_path) :]
    if suffix != _DIRECT_PATH_SUFFIX:
        return None
    direct = f"{fallback_base_url}/{suffix}"
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
            or normalized.startswith(_DIRECT_HEADER_PREFIXES)
        ):
            direct[name] = value
    direct["Authorization"] = f"Bearer {openai_key}"
    return direct


def _safe_gateway_response(response: Any) -> bool:
    request_id = response.headers.get("x-abto-request-id")
    error_source = response.headers.get("x-abto-error-source")
    if request_id is None and response.status_code in _SAFE_GATEWAY_STATUSES:
        return True
    return (
        response.status_code == 503
        and request_id is not None
        and error_source is None
    )


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
                self._circuit.release_half_open_probe()
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
            return self._direct_client.send(
                direct_request,
                stream=stream,
            )

        def send(
            self,
            request: Any,
            *,
            stream: bool = False,
            auth: Any = httpx.USE_CLIENT_DEFAULT,
            follow_redirects: Any = httpx.USE_CLIENT_DEFAULT,
        ) -> Any:
            direct_url = _direct_openai_url(
                request.url, gateway_base_url, fallback.base_url
            )
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
                except (httpx.ConnectError, httpx.ConnectTimeout):
                    self._circuit.open()
                    raise
                except httpx.RequestError:
                    self._circuit.release_half_open_probe()
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
                if fallback.on_timeout:
                    self._circuit.open()
                    return self._send_direct(
                        request,
                        direct_url=direct_url,
                        openai_key=openai_key,
                        content=content,
                        stream=stream,
                    )
                self._circuit.release_half_open_probe()
                raise
            except httpx.PoolTimeout:
                self._circuit.release_half_open_probe()
                raise
            except httpx.RequestError:
                self._circuit.release_half_open_probe()
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
        # No implicit default: the destination that receives the Calling Key and
        # provider keys is named by the application, never guessed here.
        resolved_gateway_base_url = gateway_base_url or os.getenv("ABTO_GATEWAY_BASE_URL")
        if not resolved_gateway_base_url:
            raise ValueError(
                "[abto] gateway_base_url is required. Pass it explicitly or set "
                "ABTO_GATEWAY_BASE_URL."
            )
        self.gateway_base_url = _validated_gateway_url(resolved_gateway_base_url)
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

        Official OpenAI options are forwarded unchanged except for api_key,
        base_url, and http_client, which ABTO owns for trusted Gateway routing.
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
