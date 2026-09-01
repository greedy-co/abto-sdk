# Server SDKs

## Contents

- [Supported calling boundary](#supported-calling-boundary)
- [Node.js](#nodejs)
- [Python](#python)
- [Preserve and disclose direct fallback](#preserve-and-disclose-direct-fallback)
- [Add request correlation only when selected](#add-request-correlation-only-when-selected)
- [Validate and propagate context](#validate-and-propagate-context)

## Supported calling boundary

Automatically wire only confirmed OpenAI Chat Completions calls.
The Gateway may route that request to OpenAI, Anthropic, or Gemini with the corresponding provider key, but it does not accept those providers' native inbound request APIs.

Inventory and report OpenAI Responses or other OpenAI APIs, native Anthropic or Gemini clients, and ambiguous framework or raw HTTP wrappers.
Do not migrate them, generate an adapter, or change streaming and error semantics merely to increase the number of wired calls.

Initialize one shared ABTO client through the application's existing server configuration or provider-client module.
Create a small dedicated module only when no suitable module exists.

## Node.js

Require Node.js 18 or later.
Use the repository's package manager:

```bash
npm install @abto-app/calling openai
pnpm add @abto-app/calling openai
yarn add @abto-app/calling openai
```

Initialize with server-only secrets:

```ts
import { initAbto } from "@abto-app/calling";

const abto = initAbto({
  abtoApiKey: process.env.ABTO_API_KEY,
  providerKeys: {
    openai: process.env.OPENAI_API_KEY,
    anthropic: process.env.ANTHROPIC_API_KEY,
    gemini: process.env.GEMINI_API_KEY,
  },
  gatewayBaseURL: "https://gateway.abto.app/v1",
});
```

Wrap each approved call in its approved request context while preserving the existing completion return shape:

```ts
import type OpenAI from "openai";

const completion = await abto.withContext(
  {
    deviceId,
    featureId: "support.reply",
    traceId,
  },
  async () => {
    const openai = await abto.openai() as OpenAI;
    return openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [{ role: "user", content: prompt }],
    });
  },
);
```

## Python

Require Python 3.9 or later:

```bash
python -m pip install "abto[openai]"
```

Initialize with server-only secrets:

```python
import os
from abto import init_abto

abto = init_abto(
    api_key=os.environ["ABTO_API_KEY"],
    gateway_base_url="https://gateway.abto.app/v1",
    provider_keys={
        "openai": os.environ["OPENAI_API_KEY"],
        "anthropic": os.getenv("ANTHROPIC_API_KEY"),
        "gemini": os.getenv("GEMINI_API_KEY"),
    },
)
openai = abto.openai()
```

Wrap each approved call in its approved request context while preserving the existing completion return shape:

```python
with abto.with_context(
    device_id=device_id,
    feature_id="support.reply",
    trace_id=trace_id,
):
    completion = openai.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
    )
```

Use the framework's existing async or sync client pattern.
Do not introduce a second concurrency model only for ABTO.

## Preserve and disclose direct fallback

When an OpenAI key source is present, the current Node.js and Python Calling SDKs enable direct OpenAI fallback by default for safely classified Gateway failures.
Preserve the resolved setting during Core wiring unless the user explicitly approves changing the application's availability policy.
Do not set `fallback: false` or enable timeout replay merely to make ABTO reporting simpler.
The Calling SDK owns only Gateway-outage failover. Do not add Calling SDK retries or error classification for OpenAI or model-provider failures.
Preserve the customer's native OpenAI `maxRetries` or `max_retries` setting and SDK default.
Do not add a fallback attempt counter, translate retry semantics, or silently set native retries to zero.
An ambiguous timeout or disconnect must not become a direct replay unless the installed SDK exposes an explicit timeout-replay opt-in and the user approves it.

Preserve the rest of the official OpenAI client configuration too.
For Node.js, the Calling SDK owns `baseURL` and `apiKey` and keeps its ABTO wrapper as the outer `fetch`; a caller-provided `clientOptions.fetch` is the underlying transport and must not be deleted.
For Python, the Calling SDK owns `api_key`, `base_url`, and `http_client` and rejects those three reserved arguments; it forwards other `abto.openai(**kwargs)` unchanged.
Do not remove a customer's custom transport at the call site to make integration easier.
Record these documented exceptions, and follow SDK defect handling if the installed SDK silently drops another option.

Record the exact fallback setting and resolved native OpenAI retry setting for every approved call path.
Gateway-served calls receive Gateway policy, telemetry, and `request_id`; direct fallback calls do not.
Show both branches in the final inventory, summary, and Mermaid diagram when fallback is enabled.
If the user values complete ABTO observation over direct availability, present that tradeoff and obtain approval before disabling fallback.

## Add request correlation only when selected

Do not switch an approved call to a raw-response API during Core wiring.
Only when the user selects a supported system event that consumes the Gateway request identifier, read it at that approved call site.

Inside the existing Node.js `withContext` callback, retain the completion as `data`:

```ts
const { data: completion, response } = await openai.chat.completions
  .create(existingRequest)
  .withResponse();
const requestId = response.headers.get("x-abto-request-id");
```

Inside the existing Python `with_context` block, parse the same completion after reading the header:

```python
raw_response = openai.chat.completions.with_raw_response.create(**existing_request)
request_id = raw_response.headers.get("x-abto-request-id")
completion = raw_response.parse()
```

Pass that identifier through the product's existing response path only to the selected event trigger.
Do not create a parallel endpoint, response shape, or request-ID bridge solely for ABTO.

## Validate and propagate context

- Read client ABTO headers at the existing request boundary; do not create a parallel endpoint or body format just for ABTO.
- Validate `deviceId`, `traceId`, and other client-supplied context using the application's existing request validation.
- Pass the same validated device identifier to every approved model call caused by that client action.
- Do not accept a Calling Key or provider key from a client request.
- For a server-only call, reuse a clearly established stable product identifier or ask the user when none exists.
- Read `x-abto-request-id` only when a selected supported event path needs it, and return it only to that approved client trigger.
