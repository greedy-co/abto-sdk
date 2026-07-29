# Server SDKs

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

Wrap each model call in request context:

```ts
const { data, response } = await abto.withContext(
  {
    deviceId,
    nodeKey: "support.reply",
    traceId,
  },
  async () => {
    const openai = await abto.openai();
    return openai.chat.completions
      .create({
        model: "gpt-4o-mini",
        messages: [{ role: "user", content: prompt }],
      })
      .withResponse();
  },
);

const requestId = response.headers.get("x-request-id");
```

Validate `deviceId`, `traceId`, and other client-supplied context using the application's
existing request validation.
Do not accept a Calling Key or provider key from a client request.

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

Wrap each model call in request context:

```python
with abto.with_context(
    device_id=device_id,
    node_key="support.reply",
    trace_id=trace_id,
):
    response = openai.chat.completions.with_raw_response.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
    )
    request_id = response.headers.get("x-request-id")
    completion = response.parse()
```

Use the framework's existing async or sync client pattern.
Do not introduce a second concurrency model only for ABTO.

## Direct fallback

The JavaScript and Python Calling SDKs can fall back directly to OpenAI for a bounded set of
safe Gateway failures when an OpenAI provider key is available.
This fallback does not reproduce Gateway routing, telemetry, policy, or `request_id`.
Keep the default policy unless the user explicitly accepts the duplicate-call risk of timeout fallback.
Do not claim that Anthropic or Gemini native direct fallback is supported.
