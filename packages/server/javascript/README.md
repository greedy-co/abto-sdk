# @abto-app/calling

The ABTO JavaScript Server SDK routes provider requests through the ABTO Gateway and carries request-scoped identity context and provider credentials. It is designed for Node.js servers.

It does not collect browser events, access the DOM, or use a public project key. Install `@abto-app/event` separately when the browser needs explicit customer-selected events.

## Install

```bash
pnpm add @abto-app/calling openai
```

## Quick start

```ts
import { initAbto } from '@abto-app/calling';
import type OpenAI from 'openai';

const abto = initAbto({
  abtoApiKey: process.env.ABTO_API_KEY,
  providerKeys: {
    openai: process.env.OPENAI_API_KEY,
  },
  gatewayBaseURL: 'https://gateway.abto.app/v1',
  deviceId: process.env.ABTO_DEVICE_ID,
});

const openai = await abto.openai<OpenAI>();
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
- Admission `503` with `x-abto-request-id` but no `x-abto-error-source`: treat it as a pre-provider failure and send the current request directly.
- Gateway timeout, ambiguous disconnect, or interrupted response body: return the original error and keep the direct circuit closed.
- `fallback.onTimeout: true`: replay the timed-out request directly, explicitly accepting duplicate execution and billing risk.
- `x-abto-error-source: provider|transport|internal`, deterministic `4xx` and `429`, or caller abort: do not fall back for the current request.

A safely classified failure, or an explicitly enabled timeout replay, opens the circuit for 30 seconds. New requests bypass the Gateway during that interval; afterward, one request probes Gateway recovery.

The direct path sends only the OpenAI key and OpenAI-safe headers such as `accept`, `content-type`, `idempotency-key`, `openai-*`, and `x-stainless-*`. It removes ABTO headers, the Calling Key, cookies, proxy credentials, and custom Gateway headers. Direct calls bypass Gateway policy, ABTO telemetry, and `request_id`.

The ABTO transport performs at most one Gateway decision and one direct send per official OpenAI SDK attempt. It returns direct responses and errors to the official SDK, which remains the only retry authority.

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
- `apiKey` is always the ABTO Calling Key.
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
