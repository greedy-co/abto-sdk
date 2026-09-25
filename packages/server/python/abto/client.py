"""Thin server facade: gateway baseURL + ABTO header injection.

It does not compute token/cost/latency. It routes provider SDK calls through the
ABTO Gateway and carries the x-abto-* identifiers from the current context.
"""

from __future__ import annotations

import math
import os
import threading
import time
from contextlib import contextmanager
from contextvars import ContextVar
from dataclasses import dataclass
from typing import Any, Callable, Dict, Iterator, List, Mapping, MutableMapping, Optional, Tuple, Union
from urllib.parse import SplitResult, urlsplit

from .borrowed_client import send_borrowed, _TransportAttempt
from .context import AbtoContext, create_trace_id, get_headers, with_context
from .policy_generated import (
    ERR_FALLBACK_BASE_URL_INVALID,
    ERR_FALLBACK_BASE_URL_REQUIRED,
    ERR_FALLBACK_OPENAI_KEY_REQUIRED,
    ERR_FALLBACK_TIMEOUT_POSITIVE,
    ERR_GATEWAY_BASE_URL_INVALID,
    ERR_GATEWAY_BASE_URL_REQUIRED,
    HEADER_DEVICE_ID,
    HEADER_FEATURE_ID,
    ERR_API_KEY_REQUIRED,
    ERR_API_KEY_INVALID_CHARACTERS,
    ERR_GATEWAY_ORIGIN_REFUSED,
    ERR_GATEWAY_REQUEST_URL_INVALID,
    ERR_PROVIDER_KEY_INVALID_CHARACTERS,
    CIRCUIT_OPEN_SECONDS as _CIRCUIT_OPEN_SECONDS,
    DEFAULT_FALLBACK_TIMEOUT_SECONDS,
    DIRECT_HEADER_NAMES as _DIRECT_HEADER_NAMES,
    DIRECT_HEADER_PREFIXES as _DIRECT_HEADER_PREFIXES,
    DIRECT_PATH_SUFFIX as _DIRECT_PATH_SUFFIX,
    PROVIDER_IDS as _PROVIDERS,
    SAFE_GATEWAY_STATUSES as _SAFE_GATEWAY_STATUSES,
    ERROR_SOURCE_GATEWAY as _ERROR_SOURCE_GATEWAY,
    HEADER_ERROR_SOURCE as _HEADER_ERROR_SOURCE,
)

PUBLIC_GATEWAY_BASE_URL = "https://gateway.abto.app/v1"
_UNSET = object()
ProviderKeyValue = Union[str, Callable[[], Optional[str]]]
ProviderKeys = Mapping[str, ProviderKeyValue]

# Resolve rotating keys once per attempt without exposing them on caller requests.
_provider_headers: ContextVar[Optional[Tuple[Any, Dict[str, str]]]] = ContextVar(
    "abto_provider_headers", default=None,
)


@contextmanager
def _provider_headers_scope(request: Any, headers: Optional[Dict[str, str]]) -> Iterator[None]:
    token = _provider_headers.set((request, headers) if headers is not None else None)
    try:
        yield
    finally:
        _provider_headers.reset(token)


def _provider_keys_from_env() -> Dict[str, Optional[str]]:
    """Default provider keys, read from ``<PROVIDER>_API_KEY`` for every provider the Gateway accepts.

    Derived from the generated id list so a new provider needs no edit here.
    """
    return {provider: os.getenv(f"{provider.upper()}_API_KEY") for provider in _PROVIDERS}


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
    # 끄는 길은 둘뿐이다: 생략하거나 False. 그 밖의 설정은 전부 "켜 달라"는 뜻으로 읽는다.
    if config is None or config is False:
        return _ResolvedFallback(
            enabled=False,
            timeout_seconds=DEFAULT_FALLBACK_TIMEOUT_SECONDS,
            on_timeout=False,
        )
    if config is True:
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
        raise ValueError(ERR_FALLBACK_TIMEOUT_POSITIVE)
    # 목적지를 추측하면 provider key 가 고객이 고르지 않은 호스트로 나간다.
    if options.base_url is None:
        raise ValueError(ERR_FALLBACK_BASE_URL_REQUIRED)
    # 목적지만 있고 보낼 키가 없으면 폴백은 성립하지 않는다. 조용히 꺼 두면 장애 때야 드러난다.
    if not has_openai_key_source:
        raise ValueError(ERR_FALLBACK_OPENAI_KEY_REQUIRED)
    return _ResolvedFallback(
        enabled=True,
        timeout_seconds=float(options.timeout_seconds),
        on_timeout=options.on_timeout,
        base_url=_validated_http_url(options.base_url, ERR_FALLBACK_BASE_URL_INVALID),
    )


def _validated_http_url(value: str, invalid_message: str) -> str:
    """http(s) absolute URL 만 통과시키고 끝의 slash 를 떼어 돌려준다.

    credential 이 박힌 URL 은 거절한다 — 그 자격 증명이 로그와 오류에 그대로 실린다.
    JavaScript 의 requireHttpURL 과 같은 규칙이며 오류 문구는 계약에서 생성한다.
    """
    parsed = urlsplit(value)
    if (
        parsed.scheme not in {"http", "https"}
        or not parsed.hostname
        or parsed.username is not None
        or parsed.password is not None
    ):
        raise ValueError(invalid_message)
    return value.rstrip("/")


def _origin(value: Any) -> Tuple[str, str, int]:
    parsed: SplitResult = urlsplit(str(value))
    if parsed.scheme not in {"http", "https"} or not parsed.hostname:
        raise ValueError(ERR_GATEWAY_REQUEST_URL_INVALID)
    default_port = 443 if parsed.scheme == "https" else 80
    return parsed.scheme, parsed.hostname.lower(), parsed.port or default_port


def _validated_api_key(value: str) -> str:
    resolved = value.strip()
    if not resolved:
        raise ValueError(ERR_API_KEY_REQUIRED)
    if "\r" in resolved or "\n" in resolved:
        raise ValueError(ERR_API_KEY_INVALID_CHARACTERS)
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
            raise ValueError(ERR_PROVIDER_KEY_INVALID_CHARACTERS.replace("{provider}", provider))
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

    gateway_origin = _origin(_validated_http_url(gateway_base_url, ERR_GATEWAY_BASE_URL_INVALID))
    trusted_api_key = _validated_api_key(api_key)

    def hook(request: Any) -> None:
        if _origin(request.url) != gateway_origin:
            raise ValueError(
                ERR_GATEWAY_ORIGIN_REFUSED
            )
        trusted_headers = get_headers()
        # Customer tracing owns its parent span and sampling flags; ABTO identity is additive.
        if any(name.lower() == "traceparent" for name in request.headers):
            trusted_headers.pop("traceparent", None)
        elif "traceparent" in trusted_headers:
            _remove_header(request.headers, "tracestate")
        for name in ("authorization", HEADER_DEVICE_ID, HEADER_FEATURE_ID):
            _remove_header(request.headers, name)
        for name in list(request.headers.keys()):
            if name.lower().startswith("x-abto-key-"):
                del request.headers[name]
        cached = _provider_headers.get()
        resolved_provider_headers = (
            cached[1] if cached is not None and cached[0] is request
            else resolve_provider_headers(provider_keys)
        )
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


def _destination_guard(request: Any, expected_url: Any) -> None:
    # Host can steer a virtual host even when the URL itself stays unchanged.
    # Use the URL type's authority formatting for ports and IPv6.
    if (
        _origin(request.url) != _origin(expected_url)
        or request.url.userinfo
        or request.headers.get("host", "").lower()
        != expected_url.netloc.decode("ascii").lower()
    ):
        raise ValueError("[abto] Request hooks must not change the configured destination.")


def _finalize_direct_request(request: Any, expected_url: Any, openai_key: str) -> None:
    _destination_guard(request, expected_url)
    headers = _direct_headers(request.headers, openai_key)
    # These describe the already-built HTTP body, not forwarded application
    # metadata. Removing them after build_request() breaks real HTTP/1 framing.
    for name in ("content-length", "transfer-encoding"):
        if name in request.headers:
            headers[name] = request.headers[name]
    request.headers.clear()
    request.headers.update(headers)
    request.headers["Host"] = expected_url.netloc.decode("ascii")


def _safe_gateway_response(response: Any) -> bool:
    """Report whether the Gateway ended this request before reaching a provider.

    Only such a 503 is safe to send to the fallback destination: the request never ran a
    model, so retrying it cannot duplicate execution or billing. A ``provider`` or
    ``transport`` source means the provider was already reached, so that response is
    returned as is. A 503 with no source header is treated the same way as ``gateway``:
    that is what the Gateway sent before this header existed.
    """
    request_id = response.headers.get("x-abto-request-id")
    error_source = response.headers.get(_HEADER_ERROR_SOURCE)
    if request_id is None and response.status_code in _SAFE_GATEWAY_STATUSES:
        return True
    return (
        response.status_code == 503
        and request_id is not None
        and error_source in (None, _ERROR_SOURCE_GATEWAY)
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


def _handle_gateway_error(
    error: BaseException, httpx: Any, circuit: _CircuitBreaker, *, on_timeout: bool,
    attempt: Optional[_TransportAttempt] = None,
) -> bool:
    """Update recovery state and report whether a direct fallback is allowed."""
    # A customer observer may raise the same HTTPX types after a completed call.
    if attempt is not None and (attempt.error is not error or attempt.response_received):
        circuit.release_half_open_probe()
        return False
    if isinstance(error, (httpx.ConnectError, httpx.ConnectTimeout)) or (
        on_timeout and isinstance(error, (httpx.ReadTimeout, httpx.WriteTimeout))
    ):
        circuit.open()
        return True
    # Pool exhaustion, customer errors and cancellation must propagate without replay.
    circuit.release_half_open_probe()
    return False


@contextmanager
def _gateway_header_timeout(
    request: Any, default_timeout: Any, header_timeout: Any
) -> Iterator[None]:
    caller_timeout = request.extensions.get("timeout", default_timeout)
    if header_timeout is not None:
        request.extensions["timeout"] = header_timeout
    try:
        yield
    finally:
        request.extensions["timeout"] = caller_timeout


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
    gateway_client: Any = None,
) -> Any:
    normal_timeout = (
        direct_timeout
        if direct_timeout is not _UNSET
        else gateway_client.timeout if gateway_client is not None
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

        def build_request(self, *args: Any, **kwargs: Any) -> Any:
            # Preserve current customer defaults and cookie updates, not a snapshot.
            if gateway_client is not None:
                return gateway_client.build_request(*args, **kwargs)
            return super().build_request(*args, **kwargs)

        def __exit__(self, *args: Any) -> None:
            self.close()

        def close(self) -> None:
            try:
                self._direct_client.close()
            finally:
                super().close()

        def _send_gateway(
            self, request: Any, *, attempt: Optional[_TransportAttempt] = None,
            provider_headers: Optional[Dict[str, str]] = None, **kwargs: Any,
        ) -> Any:
            # Redirects must not carry provider-key headers to another origin.
            kwargs["follow_redirects"] = False
            if gateway_client is None:
                with _provider_headers_scope(request, provider_headers):
                    return super().send(request, **kwargs)
            if self.is_closed:
                raise RuntimeError("Cannot send a request, as the client has been closed.")
            # Reject an already-invalid input before running customer hooks.
            if _origin(request.url) != _origin(gateway_base_url):
                raise ValueError(ERR_GATEWAY_ORIGIN_REFUSED)
            expected_url = request.url
            request.headers.update({k: v for k, v in get_headers().items()
                                    if k in (HEADER_DEVICE_ID, HEADER_FEATURE_ID)})

            def finalize(outgoing: Any) -> None:
                _destination_guard(outgoing, expected_url)
                with _provider_headers_scope(outgoing, provider_headers):
                    event_hooks["request"][0](outgoing)

            return send_borrowed(
                gateway_client, request, finalize, stream=kwargs.get("stream", False), attempt=attempt,
            )

        def _send_gateway_headers(
            self,
            request: Any,
            *,
            auth: Any,
            follow_redirects: Any,
            header_timeout: Any = None,
            provider_headers: Optional[Dict[str, str]] = None,
            attempt: Optional[_TransportAttempt] = None,
        ) -> Any:
            with _gateway_header_timeout(request, self.timeout.as_dict(), header_timeout):
                return self._send_gateway(
                    request,
                    stream=True,
                    provider_headers=provider_headers,
                    attempt=attempt,
                    auth=auth,
                    follow_redirects=follow_redirects,
                )

        @staticmethod
        def _finish_gateway_response(response: Any, *, stream: bool) -> Any:
            if not stream:
                try:
                    response.read()
                except BaseException:
                    response.close()
                    raise
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
            if gateway_client is not None:
                expected_url = direct_request.url
                # Customer logging hooks do not need the provider credential.
                direct_request.headers.pop("authorization", None)

                def finalize(outgoing: Any) -> None:
                    _finalize_direct_request(outgoing, expected_url, openai_key)

                return send_borrowed(gateway_client, direct_request, finalize, stream=stream)
            return self._direct_client.send(
                direct_request,
                stream=stream,
                auth=None,
                follow_redirects=False,
            )

        def send(
            self,
            request: Any,
            *,
            stream: bool = False,
            auth: Any = httpx.USE_CLIENT_DEFAULT,
            follow_redirects: Any = httpx.USE_CLIENT_DEFAULT,
        ) -> Any:
            if self.is_closed:
                raise RuntimeError("Cannot send a request, as the client has been closed.")
            direct_url = _direct_openai_url(
                request.url, gateway_base_url, fallback.base_url
            )
            eligible = (
                fallback.enabled
                and direct_url is not None
                and request.method == "POST"
            )

            if not eligible:
                return self._send_gateway(
                    request,
                    stream=stream,
                    auth=auth,
                    follow_redirects=follow_redirects,
                )

            provider_headers = resolve_provider_headers(provider_keys)
            openai_key = _openai_key_from_headers(provider_headers)
            attempt = _TransportAttempt() if gateway_client is not None else None
            if openai_key is None:
                try:
                    response = self._send_gateway_headers(
                        request,
                        auth=auth,
                        follow_redirects=follow_redirects,
                        attempt=attempt,
                        provider_headers=provider_headers,
                    )
                except BaseException as error:
                    _handle_gateway_error(error, httpx, self._circuit, on_timeout=False, attempt=attempt)
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
                    provider_headers=provider_headers,
                    attempt=attempt,
                )
            except BaseException as error:
                if not _handle_gateway_error(error, httpx, self._circuit, on_timeout=fallback.on_timeout, attempt=attempt):
                    raise
                return self._send_direct(
                    request,
                    direct_url=direct_url,
                    openai_key=openai_key,
                    content=content,
                    stream=stream,
                )

            if _safe_gateway_response(response):
                self._circuit.open()
                response.close()
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
        self._provider_keys = provider_keys if provider_keys is not None else _provider_keys_from_env()
        # No implicit default: the destination that receives the Calling Key and
        # provider keys is named by the application, never guessed here.
        resolved_gateway_base_url = gateway_base_url or os.getenv("ABTO_GATEWAY_BASE_URL")
        if not resolved_gateway_base_url:
            raise ValueError(ERR_GATEWAY_BASE_URL_REQUIRED)
        self.gateway_base_url = _validated_http_url(resolved_gateway_base_url, ERR_GATEWAY_BASE_URL_INVALID)
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

    def openai_options(self, **client_kwargs: Any) -> Dict[str, Any]:
        """Return sync OpenAI-compatible options without importing OpenAI.

        Use with ``ChatOpenAI(**abto.openai_options())`` or ``OpenAI``.
        Close the returned http_client at application shutdown. A supplied
        http_client is borrowed and remains owned by its caller.
        """
        return self._openai_options(False, client_kwargs)

    def async_openai_options(self, **client_kwargs: Any) -> Dict[str, Any]:
        """Return AsyncOpenAI-compatible options with native async HTTPX I/O.

        For LangChain, pass the returned http_client as http_async_client.
        Await its aclose() at shutdown; supplied clients remain caller-owned.
        """
        return self._openai_options(True, client_kwargs)

    def _openai_options(self, asynchronous: bool, client_kwargs: Dict[str, Any]) -> Dict[str, Any]:
        try:
            import httpx
        except ImportError as exc:  # pragma: no cover - optional dependency
            raise ImportError("ABTO OpenAI options require httpx: pip install 'abto[httpx]'") from exc
        options = dict(client_kwargs)
        customer_client = options.pop("http_client", None)
        expected = httpx.AsyncClient if asynchronous else httpx.Client
        if customer_client is not None and not isinstance(customer_client, expected):
            # OpenAI 3 also accepts HTTPX 2 clients. Reuse their matching I/O
            # types without making that optional transport a core dependency.
            try:
                import httpx2
            except ImportError:
                httpx2 = None
            alternative = (httpx2.AsyncClient if asynchronous else httpx2.Client) if httpx2 else None
            if alternative is None or not isinstance(customer_client, alternative):
                raise TypeError(f"[abto] http_client must be an {expected.__name__}.")
            httpx = httpx2
        builder = _build_fallback_http_client
        if asynchronous:
            from .async_client import _build_async_fallback_http_client
            builder = _build_async_fallback_http_client
        http_client = builder(
            httpx,
            gateway_base_url=self.gateway_base_url,
            api_key=self.api_key,
            provider_keys=self._provider_keys,
            fallback=self._fallback,
            circuit=self._fallback_circuit,
            gateway_client=customer_client,
            direct_timeout=options.get("timeout", _UNSET),
        )
        # Framework serialization sees only a placeholder; the request hook
        # injects credentials at dispatch, just like the JavaScript transport.
        options.update(api_key="abto-transport-placeholder", base_url=self.gateway_base_url, http_client=http_client)
        return options

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

        return OpenAI(**self.openai_options(**client_kwargs))


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
