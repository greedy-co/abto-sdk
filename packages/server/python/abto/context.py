"""Request-scoped ABTO identifier context for the `abto` Python package.

Mirrors @abto-app/calling: carries the gateway identifier headers via
contextvars so outbound provider calls can attach them. The ABTO transport owns
only direct fallback for safely classified Gateway availability failures. It
does not classify or retry OpenAI or model-provider errors; the official OpenAI
SDK remains the retry authority. The gateway remains the source of truth for
token, cost, latency, request_id, and variant assignment.
"""

from __future__ import annotations

import contextvars
import secrets
from contextlib import contextmanager
from dataclasses import dataclass, replace
from typing import Any, Dict, Iterator, Optional

ABTO_HEADER = {
    "device_id": "x-abto-device-id",
    "feature_id": "x-abto-feature-id",
    "traceparent": "traceparent",
}


@dataclass(frozen=True)
class AbtoContext:
    """Device id, dot-separated feature id, and end-user action trace id."""

    device_id: Optional[str] = None
    feature_id: Optional[str] = None
    trace_id: Optional[str] = None


_current: contextvars.ContextVar[AbtoContext] = contextvars.ContextVar(
    "abto_context", default=AbtoContext()
)


def get_context() -> AbtoContext:
    return _current.get()


_UNSET = object()


@contextmanager
def with_context(
    device_id: Any = _UNSET,
    feature_id: Any = _UNSET,
    trace_id: Any = _UNSET,
) -> Iterator[AbtoContext]:
    patch = {
        k: v
        for k, v in dict(
            device_id=device_id, feature_id=feature_id, trace_id=trace_id
        ).items()
        if v is not _UNSET
    }
    merged = replace(_current.get(), **patch)
    token = _current.set(merged)
    try:
        yield merged
    finally:
        _current.reset(token)


def create_trace_id() -> str:
    """32-hex-char trace id, per W3C trace-context."""
    return secrets.token_hex(16)


def create_traceparent(trace_id: str) -> str:
    return f"00-{trace_id}-{secrets.token_hex(8)}-01"


def get_headers(ctx: Optional[AbtoContext] = None) -> Dict[str, str]:
    c = ctx if ctx is not None else _current.get()
    headers: Dict[str, str] = {}
    if c.device_id:
        headers[ABTO_HEADER["device_id"]] = c.device_id
    if c.feature_id:
        headers[ABTO_HEADER["feature_id"]] = c.feature_id
    if c.trace_id:
        headers[ABTO_HEADER["traceparent"]] = create_traceparent(c.trace_id)
    return headers
