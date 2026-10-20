"""Request-scoped ABTO identifier context for the `abto` Python package.

Mirrors @abto-app/calling: carries the gateway identifier headers via
contextvars so outbound provider calls can attach them. The ABTO transport owns
only direct fallback for safely classified Gateway availability failures. It
does not classify or retry OpenAI or model-provider errors; the official OpenAI
SDK remains the retry authority. The gateway remains the source of truth for
token, cost, latency, request_id, and variant assignment.
"""

from __future__ import annotations

from .policy_generated import HEADER_DEVICE_ID, HEADER_FEATURE_ID, HEADER_NODE_ID, HEADER_TRACE_ID

import contextvars
import secrets
import time
from contextlib import contextmanager
from dataclasses import dataclass, replace
from typing import Any, Dict, Iterator, Optional

ABTO_HEADER = {
    "device_id": HEADER_DEVICE_ID,
    "feature_id": HEADER_FEATURE_ID,
    "node_id": HEADER_NODE_ID,
    "trace_id": HEADER_TRACE_ID,
    "traceparent": "traceparent",
}


@dataclass(frozen=True)
class AbtoContext:
    """Device id, feature id, agent or workflow run id, and call site inside the feature."""

    device_id: Optional[str] = None
    feature_id: Optional[str] = None
    trace_id: Optional[str] = None
    node_id: Optional[str] = None


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
    node_id: Any = _UNSET,
) -> Iterator[AbtoContext]:
    patch = {
        k: v
        for k, v in dict(
            device_id=device_id, feature_id=feature_id, trace_id=trace_id, node_id=node_id
        ).items()
        if v is not _UNSET
    }
    parent = _current.get()
    # A node only has meaning inside its feature, so switching to another feature without a node drops the inherited one.
    if "feature_id" in patch and patch["feature_id"] != parent.feature_id and "node_id" not in patch:
        patch["node_id"] = None
    # The outermost scope opens one run; inner scopes inherit it, even when they pass an empty trace id.
    patch["trace_id"] = patch.get("trace_id") or parent.trace_id or create_trace_id()
    merged = replace(parent, **patch)
    token = _current.set(merged)
    try:
        yield merged
    finally:
        _current.reset(token)


def create_trace_id() -> str:
    """UUIDv7 as 32 hex chars, matching the trace ids every ABTO SDK generates."""
    # uuid.uuid7 only exists from Python 3.14, so this SDK (3.9+) fills the RFC 9562 bit layout itself.
    b = bytearray((time.time_ns() // 1_000_000).to_bytes(6, "big") + secrets.token_bytes(10))
    b[6] = (b[6] & 0x0F) | 0x70
    b[8] = (b[8] & 0x3F) | 0x80
    return b.hex()


def create_traceparent(trace_id: str) -> str:
    """Deprecated: the SDK no longer sends a derived traceparent; pass the id as trace_id."""
    return f"00-{trace_id}-{secrets.token_hex(8)}-01"


def get_headers(ctx: Optional[AbtoContext] = None) -> Dict[str, str]:
    scope = _current.get()
    c = ctx if ctx is not None else scope
    headers: Dict[str, str] = {}
    if c.device_id:
        headers[ABTO_HEADER["device_id"]] = c.device_id
    if c.feature_id:
        headers[ABTO_HEADER["feature_id"]] = c.feature_id
    if c.node_id:
        headers[ABTO_HEADER["node_id"]] = c.node_id
    # Explicit value first, then the active scope's run; outside any scope this call is its own run.
    # Outside a scope, OpenAI SDK retries rebuild the headers, so each attempt gets its own run. Wrap the run in with_context to keep one.
    headers[ABTO_HEADER["trace_id"]] = c.trace_id or scope.trace_id or create_trace_id()
    return headers
