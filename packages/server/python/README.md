# abto (Python)

The ABTO Python Server SDK is a thin Gateway helper. It carries request-scoped `x-abto-*` identifiers with `contextvars` and injects them into outbound provider requests through `httpx`. The Gateway owns tokens, cost, latency, `request_id`, and variant assignment.

This package is the Python counterpart of the Node.js `@abto-app/calling` package. npm and PyPI releases remain separate for each language.

## Install

```bash
pip install abto                 # Core context and header helpers
pip install "abto[openai]"       # OpenAI and httpx integration
```

## Quick start

```python
import os

from abto import init_abto

abto = init_abto(
    api_key=os.environ["ABTO_API_KEY"],
    gateway_base_url="https://gateway.abto.app/v1",
    provider_keys={
        "openai": os.environ["OPENAI_API_KEY"],
        # Include candidate keys for every provider the project may route to.
        # "anthropic": os.environ["ANTHROPIC_API_KEY"],
        # "gemini": os.environ["GEMINI_API_KEY"],
    },
)
openai = abto.openai()


def generate(device_id: str, trace_id: str):
    with abto.with_context(
        device_id=device_id,
        node_key="resume.make",
        trace_id=trace_id,
    ):
        return openai.chat.completions.create(
            model="gpt-4.1",
            messages=[{"role": "user", "content": "Create a resume draft"}],
        )
```

## Direct httpx usage

```python
import httpx
from abto import with_context

client = httpx.Client(event_hooks=abto.httpx_event_hooks())

with with_context(device_id="d1", node_key="resume.make"):
    client.post("https://gateway.abto.app/v1/...")  # Adds x-abto-* headers
```

## Header contract

```text
x-abto-device-id    optional; without it, user analytics and sticky assignment are unavailable
x-abto-node-key     required; "feature.node" dot notation, for example resume.make
traceparent         derived from trace_id; Gateway-deferred in Round 1
x-abto-key-openai   candidate provider key; add only the providers the project may route to
Authorization       required; Bearer ABTO Calling Key
```

The Gateway maps the Calling Key to `tenant_id`, creates `request_id` in the `x-abto-request-id` response header, assigns `variant_id`, and removes `x-abto-*` headers before provider egress.

## OpenAI direct fallback during Gateway outages

When an OpenAI provider key is available, direct fallback is enabled by default for Gateway failures that can be classified safely. It sends the original Chat Completions body and model to OpenAI and does not reproduce the Gateway's provider or model policy.

```python
from abto import OpenAIDirectFallbackOptions, init_abto

abto = init_abto(
    api_key=os.environ["ABTO_API_KEY"],
    provider_keys={
        "openai": os.environ["OPENAI_API_KEY"],
        "anthropic": os.getenv("ANTHROPIC_API_KEY"),
        "gemini": os.getenv("GEMINI_API_KEY"),
    },
    fallback=OpenAIDirectFallbackOptions(
        timeout_seconds=30,
        on_timeout=False,
    ),
)
```

Default behavior matches the JavaScript Calling SDK:

- DNS, connection-establishment, or TLS failure; pre-Gateway edge `502`, `503`, or `504`; or pre-provider admission `503`: send the current request directly to OpenAI.
- Gateway timeout, ambiguous disconnect, or interrupted response body: return the original error and keep the direct circuit closed.
- `on_timeout=True`: replay the timed-out request directly, explicitly accepting duplicate execution and billing risk.
- Provider, transport, or internal error, deterministic `4xx` or `429`: do not fall back for the current request.

The direct path sends only the OpenAI key and OpenAI-safe headers such as `accept`, `content-type`, `idempotency-key`, `openai-*`, and `x-stainless-*`. It removes ABTO headers, the Calling Key, cookies, proxy credentials, and custom Gateway headers. Direct calls bypass Gateway policy, ABTO telemetry, and `request_id`.

The ABTO transport performs at most one Gateway decision and one direct send per official OpenAI SDK attempt. It returns direct responses and errors to the official SDK, which remains the only retry authority.

Use `init_abto(..., fallback=False)` to disable direct fallback.

## OpenAI client options

`abto.openai(**kwargs)` forwards official OpenAI options such as `max_retries`, `timeout`, `organization`, `project`, `default_headers`, and `default_query` unchanged, except for the three values ABTO must own:

- `api_key` is the ABTO Calling Key.
- `base_url` is the configured ABTO Gateway URL.
- `http_client` is the ABTO routing client that enforces Gateway/direct-fallback boundaries.

Passing any of those three reserved arguments raises `ValueError` instead of silently discarding it.

`timeout_seconds` is an inactivity ceiling for each Gateway connection-pool wait, connect, write, and response-header-read stage. The body after the headers and direct requests retain `abto.openai(timeout=...)`.

There is no fallback retry count. `abto.openai(max_retries=...)` alone controls official OpenAI SDK retries and remains at the official default when omitted.

```python
openai = abto.openai(max_retries=2)
```

`max_retries` keeps the official OpenAI meaning: retries after the initial request. `0` means one total attempt and `1` means two. OpenAI and model-provider error policy belongs to the customer application and the official OpenAI SDK.

Anthropic and Gemini keys remain Gateway routing candidates. This SDK does not provide native direct fallback for those providers.

See the [full Python guide](https://docs.abto.app/en/sdk/python/).

## Public API

- `init_abto(api_key=None, gateway_base_url=None, provider_keys=None, fallback=None) -> Abto`
- `abto.openai(**kwargs)`
- `OpenAIDirectFallbackOptions`
- `abto.with_context(device_id=?, node_key=?, trace_id=?)`
- `abto.get_headers(ctx=None)` / `abto.create_trace_id()` / `abto.httpx_event_hooks()`
- Lower-level helpers: `with_context`, `get_context`, `get_headers`, `create_trace_id`, `create_traceparent`, `abto_request_hook`, `ABTO_HEADER`, and `AbtoContext`

## Development

```bash
pip install pytest
pytest
```
