"""Native async HTTPX routing using the same policy as the sync client."""
from __future__ import annotations

from typing import Any, Dict, Optional

from .borrowed_client import send_borrowed_async, _TransportAttempt
from .client import (
    ProviderKeys, _CircuitBreaker, _ResolvedFallback, _UNSET,
    _provider_headers_scope,
    _direct_headers, _direct_openai_url, _openai_key_from_headers,
    _safe_gateway_response, abto_request_hook, resolve_provider_headers,
    _handle_gateway_error, _gateway_header_timeout,
    _origin, _destination_guard, _finalize_direct_request, ERR_GATEWAY_ORIGIN_REFUSED,
    get_headers, HEADER_DEVICE_ID, HEADER_FEATURE_ID,
)


def _build_async_fallback_http_client(
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
    hook = abto_request_hook(gateway_base_url, api_key=api_key, provider_keys=provider_keys)

    async def request_hook(request: Any) -> None:
        hook(request)

    event_hooks = {"request": [request_hook]}

    class GatewayFallbackClient(httpx.AsyncClient):
        def __init__(self) -> None:
            super().__init__(
                event_hooks=event_hooks,
                timeout=normal_timeout,
                transport=gateway_transport,
            )
            self._direct_client = httpx.AsyncClient(
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

        async def __aexit__(self, *args: Any) -> None:
            await self.aclose()

        async def aclose(self) -> None:
            try:
                await self._direct_client.aclose()
            finally:
                await super().aclose()

        async def _send_gateway(
            self, request: Any, *, attempt: Optional[_TransportAttempt] = None,
            provider_headers: Optional[Dict[str, str]] = None, **kwargs: Any,
        ) -> Any:
            # Redirects must not carry provider-key headers to another origin.
            kwargs["follow_redirects"] = False
            if gateway_client is None:
                with _provider_headers_scope(request, provider_headers):
                    return await super().send(request, **kwargs)
            if self.is_closed:
                raise RuntimeError("Cannot send a request, as the client has been closed.")
            if _origin(request.url) != _origin(gateway_base_url):
                raise ValueError(ERR_GATEWAY_ORIGIN_REFUSED)
            expected_url = request.url
            request.headers.update({k: v for k, v in get_headers().items()
                                    if k in (HEADER_DEVICE_ID, HEADER_FEATURE_ID)})

            def finalize(outgoing: Any) -> None:
                _destination_guard(outgoing, expected_url)
                with _provider_headers_scope(outgoing, provider_headers):
                    hook(outgoing)

            return await send_borrowed_async(
                gateway_client, request, finalize, stream=kwargs.get("stream", False), attempt=attempt,
            )

        async def _send_gateway_headers(
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
                return await self._send_gateway(
                    request,
                    stream=True,
                    provider_headers=provider_headers,
                    attempt=attempt,
                    auth=auth,
                    follow_redirects=follow_redirects,
                )

        @staticmethod
        async def _finish_gateway_response(response: Any, *, stream: bool) -> Any:
            if not stream:
                try:
                    await response.aread()
                except BaseException:
                    await response.aclose()
                    raise
            return response

        async def _send_direct(
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
                direct_request.headers.pop("authorization", None)

                def finalize(outgoing: Any) -> None:
                    _finalize_direct_request(outgoing, expected_url, openai_key)

                return await send_borrowed_async(gateway_client, direct_request, finalize, stream=stream)
            return await self._direct_client.send(
                direct_request,
                stream=stream,
                auth=None,
                follow_redirects=False,
            )

        async def send(
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
                return await self._send_gateway(
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
                    response = await self._send_gateway_headers(
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
                return await self._finish_gateway_response(
                    response,
                    stream=stream,
                )

            content = await request.aread()

            if self._circuit.should_bypass():
                return await self._send_direct(
                    request,
                    direct_url=direct_url,
                    openai_key=openai_key,
                    content=content,
                    stream=stream,
                )

            try:
                response = await self._send_gateway_headers(
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
                return await self._send_direct(
                    request,
                    direct_url=direct_url,
                    openai_key=openai_key,
                    content=content,
                    stream=stream,
                )

            if _safe_gateway_response(response):
                self._circuit.open()
                await response.aclose()
                return await self._send_direct(
                    request,
                    direct_url=direct_url,
                    openai_key=openai_key,
                    content=content,
                    stream=stream,
                )
            self._circuit.close()
            return await self._finish_gateway_response(
                response,
                stream=stream,
            )

    return GatewayFallbackClient()
