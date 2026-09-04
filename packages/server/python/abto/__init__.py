"""`abto` — ABTO server-side SDK for Python.

Thin gateway header helper: carries x-abto-* identifiers via contextvars and
injects them into outbound provider calls (httpx event hooks). The gateway owns
token, cost, latency, request_id, and variant assignment.
"""

from .client import (
    Abto,
    OpenAIDirectFallbackConfig,
    OpenAIDirectFallbackOptions,
    abto_request_hook,
    init_abto,
)
from .context import (
    ABTO_HEADER,
    AbtoContext,
    create_trace_id,
    create_traceparent,
    get_context,
    get_headers,
    with_context,
)

__version__ = "0.4.0"

__all__ = [
    "Abto",
    "init_abto",
    "abto_request_hook",
    "OpenAIDirectFallbackConfig",
    "OpenAIDirectFallbackOptions",
    "AbtoContext",
    "ABTO_HEADER",
    "with_context",
    "get_context",
    "get_headers",
    "create_trace_id",
    "create_traceparent",
    "__version__",
]
