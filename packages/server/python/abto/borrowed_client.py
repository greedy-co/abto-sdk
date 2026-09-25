"""Public transport boundary for borrowed HTTPX clients."""
from contextlib import contextmanager
from contextvars import ContextVar
from dataclasses import dataclass, field
from typing import Any, Callable, Iterator, Optional

# Context-local dispatch keeps unrelated calls on a shared client unchanged.
_DISPATCH_EXTENSION = "abto.http_dispatch"


@dataclass
class _TransportAttempt:
    error: Optional[BaseException] = None
    response_received: bool = False


@dataclass
class _Dispatch:
    request: Any
    finalize: Callable[[Any], None]
    attempt: Optional[_TransportAttempt] = None
    # Preserve JSON-compatible request extensions for customer loggers.
    marker: list = field(default_factory=list, repr=False)
    prepared: bool = False


_dispatch: ContextVar[Optional[_Dispatch]] = ContextVar("abto_http_dispatch", default=None)


@contextmanager
def _borrowed_dispatch(
    request: Any, finalize: Callable[[Any], None], attempt: Optional[_TransportAttempt],
) -> Iterator[_Dispatch]:
    dispatch = _Dispatch(
        request=request,
        finalize=finalize,
        attempt=attempt,
    )
    previous_dispatch = request.extensions.get(_DISPATCH_EXTENSION)
    # Only an opaque identity marker reaches customer hooks, never credentials.
    request.extensions[_DISPATCH_EXTENSION] = dispatch.marker
    token = _dispatch.set(dispatch)
    try:
        yield dispatch
    finally:
        _dispatch.reset(token)
        if previous_dispatch is None:
            request.extensions.pop(_DISPATCH_EXTENSION, None)
        else:
            request.extensions[_DISPATCH_EXTENSION] = previous_dispatch


def wrap_httpx_transport(transport: Any) -> Any:
    """Wrap an existing sync/async HTTPX (or HTTPX2) transport.

    Configure this wrapper when constructing a customer client, including each
    mounted transport. ABTO does not replace private client fields or hooks.
    Closing the wrapper closes the wrapped transport through the normal client
    lifecycle. Ordinary, non-ABTO requests pass through unchanged.
    """
    import httpx
    module = httpx
    if not isinstance(transport, (httpx.BaseTransport, httpx.AsyncBaseTransport)):
        try:
            import httpx2
        except ImportError:
            httpx2 = None
        if httpx2 is None or not isinstance(transport, (httpx2.BaseTransport, httpx2.AsyncBaseTransport)):
            raise TypeError("[abto] transport must be an HTTPX BaseTransport or AsyncBaseTransport.")
        module = httpx2

    def prepare(request: Any) -> Any:
        dispatch = _dispatch.get()
        if dispatch is None:
            return request
        if (
            request is not dispatch.request
            and request.extensions.get(_DISPATCH_EXTENSION) is not dispatch.marker
        ):
            return request
        # Credentials exist only on the wire copy, never in customer hooks,
        # response.request, send wrappers or the caller-owned request object.
        wire = module.Request(request.method, request.url, headers=request.headers,
                              stream=request.stream, extensions=dict(request.extensions))
        wire.extensions.pop(_DISPATCH_EXTENSION, None)
        dispatch.finalize(wire)
        dispatch.prepared = True
        return wire

    class SyncTransport(module.BaseTransport):
        def handle_request(self, request: Any) -> Any:
            wire = prepare(request)
            dispatch = _dispatch.get() if wire is not request else None
            attempt = dispatch.attempt if dispatch is not None else None
            try:
                response = transport.handle_request(wire)
            except module.RequestError as exc:
                if attempt is not None:
                    attempt.error = exc
                exc.request = request
                raise
            if attempt is not None:
                attempt.response_received = True
            response.request = request
            return response

        def close(self) -> None:
            transport.close()

    class AsyncTransport(module.AsyncBaseTransport):
        async def handle_async_request(self, request: Any) -> Any:
            wire = prepare(request)
            dispatch = _dispatch.get() if wire is not request else None
            attempt = dispatch.attempt if dispatch is not None else None
            try:
                response = await transport.handle_async_request(wire)
            except module.RequestError as exc:
                if attempt is not None:
                    attempt.error = exc
                exc.request = request
                raise
            if attempt is not None:
                attempt.response_received = True
            response.request = request
            return response

        async def aclose(self) -> None:
            await transport.aclose()

    # MockTransport implements both interfaces; preserve both capabilities.
    if isinstance(transport, module.BaseTransport) and isinstance(transport, module.AsyncBaseTransport):
        class Transport(SyncTransport, AsyncTransport):
            pass
        return Transport()
    return AsyncTransport() if isinstance(transport, module.AsyncBaseTransport) else SyncTransport()


def send_borrowed(
    client: Any, request: Any, finalize: Callable[[Any], None], *, stream: bool,
    attempt: Optional[_TransportAttempt] = None,
) -> Any:
    with _borrowed_dispatch(request, finalize, attempt) as dispatch:
        # The caller's send overrides and all HTTPX instrumentation stay active.
        # Gateway credentials own auth and must never follow redirects.
        response = client.send(request, stream=stream, auth=None, follow_redirects=False)
        if not dispatch.prepared:
            response.close()
            raise ValueError("[abto] Configure wrap_httpx_transport() on the supplied client's transport and mounts.")
        return response


async def send_borrowed_async(
    client: Any, request: Any, finalize: Callable[[Any], None], *, stream: bool,
    attempt: Optional[_TransportAttempt] = None,
) -> Any:
    with _borrowed_dispatch(request, finalize, attempt) as dispatch:
        response = await client.send(request, stream=stream, auth=None, follow_redirects=False)
        if not dispatch.prepared:
            await response.aclose()
            raise ValueError("[abto] Configure wrap_httpx_transport() on the supplied client's transport and mounts.")
        return response
