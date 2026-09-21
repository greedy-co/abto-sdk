# @abto-app/calling

Connect your Node.js AI calls to ABTO to track cost and response time, and change models or prompts from the dashboard.
Use this SDK on your server. To record user actions such as purchases, add `@abto-app/event` to your browser app.

## Install

```bash
pnpm add @abto-app/calling openai
```

## Quick start

Set `ABTO_CALLING_KEY` and `OPENAI_API_KEY` in your server environment. Use an ABTO Calling Key, not a browser Event Key.

```ts
import { initAbto } from '@abto-app/calling';
import type OpenAI from 'openai';

const abto = initAbto({
  abtoApiKey: process.env.ABTO_CALLING_KEY,
  providerKeys: {
    openai: process.env.OPENAI_API_KEY,
  },
  gatewayBaseURL: 'https://gateway.abto.app/v1',
});

const openai = await abto.openai<OpenAI>();
const reply = await abto.withContext(
  { featureId: 'support.reply' },
  () => openai.chat.completions.create({
    model: 'gpt-4.1-mini',
    messages: [{ role: 'user', content: 'How can I check my delivery status?' }],
  }),
);

console.log(reply.choices[0]?.message.content);
```

Find the `support.reply` call in Requests in your dashboard to check its response, cost, and response time.

## Connect LangChain

Connect your existing LangChain chain to ABTO to record AI calls and change models or prompts from the dashboard.
Add ABTO to your `ChatOpenAI` configuration, then name the feature when you invoke the model.

> **Check your SDK version first.** The published `1.1.1` release does not include `openaiOptions()`.
> This example requires a release that provides that method. To get started with the current public release, use the OpenAI example above.

Keep your existing `@langchain/openai` installation and add this setting where you create the model.
If you already have a `configuration` object, pass it to `abto.openaiOptions(configuration)`.

```ts
configuration: abto.openaiOptions(),
```

Here is a complete example. Set `ABTO_CALLING_KEY` and `OPENAI_API_KEY` in your server environment.

```ts
import { ChatOpenAI } from '@langchain/openai';
import { initAbto } from '@abto-app/calling';

const abto = initAbto({
  abtoApiKey: process.env.ABTO_CALLING_KEY,
  gatewayBaseURL: 'https://gateway.abto.app/v1',
  providerKeys: { openai: process.env.OPENAI_API_KEY },
});

const model = new ChatOpenAI({
  model: 'gpt-4.1-mini',
  configuration: abto.openaiOptions(),
});

const reply = await abto.withContext(
  { featureId: 'support.reply' },
  () => model.invoke('How can I check my delivery status?'),
);

console.log(reply.content);
```

Keep your other model options, `invoke()` calls, chains, parsers, and callbacks.
Requests travel from LangChain through the ABTO Gateway to the model provider.
After the call, look for the `support.reply` record in Requests in your dashboard.

### Connect calls to user actions

To connect a call to actions such as purchases, send the browser SDK's `getIdentity().deviceId` to your server.
Pass `{ featureId: 'support.reply', deviceId }` to `withContext`.
For background jobs, save and pass this value with the job data.

### Keep Langfuse and LangSmith

Keep your existing callbacks and tracing setup.
You do not need to replace your tracing tool to connect ABTO.

Your tracing tool records the request sent by your application.
If you change the model, prompt, or parameters in the dashboard, check the ABTO request record for what ran.
The model name shown by your tracing tool can also depend on its version.

<details>
<summary>Before you connect</summary>

- This example supports OpenAI Chat Completions. Streaming and the Responses API are not supported.
- The connection has been tested with `@langchain/openai` versions `0.2.7` and `1.5.13`. Check the call path and compatibility when using another version.
- With `@langchain/openai@0.2.7` and `langfuse-langchain@3.39.2`, create a Langfuse handler for each request. Sharing a handler across concurrent requests can combine their traces.
- Keep API keys and ABTO configuration on your server. ABTO keeps its Calling Key out of model settings, but does not automatically hide other secrets you add.
- Do not pass another router's URL or authentication headers unchanged. `openaiOptions()` changes the destination to ABTO; it does not chain multiple routers.
- Existing trace headers are preserved up to the Gateway. Tracing through to the provider and forwarding `organization` or `project` are not guaranteed.
- You can enable direct fallback to OpenAI during Gateway outages. Those calls bypass ABTO routing and call records.

</details>

## Use CommonJS

Replace the ABTO import in the example with the following line.
This requires an SDK release with CommonJS support.

```js
const { initAbto } = require('@abto-app/calling');
```

## Request context

```ts
import {
  getAbtoHeaders,
  runWithAbtoContext,
} from '@abto-app/calling';

await runWithAbtoContext(
  {
    deviceId: 'device_123',
    featureId: 'resume.make',
  },
  async () => {
    const headers = getAbtoHeaders();
    // Provider requests created here carry the same ABTO identifiers.
  },
);
```

The Gateway is the source of truth for provider requests and responses, tokens, cost, latency, `request_id`, and variant assignment. The Server SDK preserves the provider request body while routing it to the Gateway with trusted ABTO headers.
`featureId` is the customer- and SDK-facing Feature identifier. The SDK sends it to the Gateway as `x-abto-feature-id`.

## Preserve existing traces

ABTO keeps the `traceparent` and `tracestate` headers supplied by your tracing tool, including during direct fallback.
It adds feature and device information separately without replacing your trace ID.

This requires an SDK release with trace preservation; the published `1.1.1` release does not include it.
Keep your tracing tool's request header setup. ABTO does not configure tracing for you or connect traces through to the provider.

## OpenAI direct fallback during Gateway outages

This emergency path returns the request to the endpoint the application called before ABTO, so you name that destination in `fallback.baseURL` and there is no default. It does not reproduce the Gateway's provider or model assignment: the original Chat Completions body and `model` go to `<baseURL>/chat/completions`, so that endpoint must support the model and accept `Authorization: Bearer`. Enabling fallback without `baseURL` throws; configuring nothing leaves fallback off.

```ts
const abto = initAbto({
  abtoApiKey: process.env.ABTO_API_KEY,
  providerKeys: {
    openai: process.env.OPENAI_API_KEY,
    anthropic: process.env.ANTHROPIC_API_KEY,
    gemini: process.env.GEMINI_API_KEY,
  },
  fallback: {
    baseURL: 'https://api.openai.com/v1', // the address this code used before ABTO
    timeoutMs: 30_000, // Gateway response-header deadline
    onTimeout: false,  // Do not replay a timed-out request by default
  },
});
```

Default behavior:

- DNS, connection-establishment, or TLS failure: send the current request directly because the provider was not reached.
- Edge `502`, `503`, or `504` without `x-abto-request-id`: treat it as a pre-Gateway failure and send the current request directly.
- Admission `503` with `x-abto-request-id` and `x-abto-error-source: gateway` (or no source header): treat it as a pre-provider failure and send the current request directly.
- Gateway timeout, ambiguous disconnect, or interrupted response body: return the original error and keep the direct circuit closed.
- `fallback.onTimeout: true`: replay the timed-out request directly, explicitly accepting duplicate execution and billing risk.
- `x-abto-error-source: provider|transport`, deterministic `4xx` and `429`, or caller abort: do not fall back for the current request.

A safely classified failure, or an explicitly enabled timeout replay, opens the circuit for 30 seconds. New requests bypass the Gateway during that interval; afterward, one request probes Gateway recovery.

The direct path sends only the OpenAI key and OpenAI-safe headers such as `accept`, `content-type`, `idempotency-key`, `traceparent`, `tracestate`, `openai-*`, and `x-stainless-*`. It removes ABTO headers, the Calling Key, cookies, proxy credentials, and custom Gateway headers. Direct calls bypass Gateway policy, ABTO telemetry, and `request_id`.

The ABTO transport performs at most one Gateway decision and one direct send per client attempt. It returns direct responses and errors to the caller; the OpenAI SDK or owning framework retains its existing retry policy.

Disable direct fallback when required:

```ts
initAbto({
  // ...
  fallback: false,
});
```

## OpenAI client options

`clientOptions` keeps the official OpenAI SDK contract. ABTO preserves options such as `maxRetries`, `timeout`, `organization`, `project`, `defaultHeaders`, and `fetchOptions`, with these routing and credential rules:

- `baseURL` is always the configured ABTO Gateway URL.
- `apiKey` is a nonsecret placeholder; the wrapped `fetch` injects the actual Calling Key or direct-fallback provider key at dispatch.
- `fetch` is wrapped so ABTO can route safely. A caller-provided `fetch` remains the underlying transport instead of being discarded.

`fallback.baseURL` is required to enable direct fallback and has no default: it is the endpoint this application used before ABTO. **Leave it unset and there is no fallback — a Gateway outage makes the request fail outright.** Set it if the existing path should keep serving traffic after adoption. ABTO does not guess the destination, because the provider key leaves on that path; enabling fallback without it throws.

`fallback.timeoutMs` is the end-to-end limit from local dispatcher wait through Gateway response headers. Direct requests retain the OpenAI client's timeout.

There is no fallback retry count. `clientOptions.maxRetries` alone controls official OpenAI SDK retries and remains unset when the customer does not configure it.

```ts
const openai = await abto.openai({
  clientOptions: { maxRetries: 2 },
});
```

`maxRetries` keeps the official OpenAI meaning: retries after the initial request. `0` means one Gateway round trip and `1` means two. OpenAI and model-provider error policy belongs to the customer application and the official OpenAI SDK.

Note that `maxRetries` counts round trips, not provider invocations. Inside a single round trip the Gateway may retry along the same path — always for pre-send network failures (up to 2), and for transient provider failures (`429`, `500`, `502`, `503`, `504`, `529`) when the node retry policy opts in (up to 2). The `x-abto-attempt` response header reports which attempt produced the response. See [Retries happen at two layers](https://docs.abto.app/en/sdk/javascript/server/#retries-happen-at-two-layers).

Anthropic and Gemini keys remain Gateway routing candidates. This SDK does not provide native direct fallback for those providers.

See the [full Server JavaScript guide](https://docs.abto.app/en/sdk/javascript/server/).

## Public API

- `initAbto`
- `createAbtoOpenAI`
- `OpenAIDirectFallbackConfig`
- `OpenAIDirectFallbackOptions`
- `runWithAbtoContext`
- `getAbtoContext`
- `getAbtoHeaders`
- `createTraceId`
- `createTraceparent`

## Development

```bash
pnpm test
pnpm typecheck
pnpm build
```
