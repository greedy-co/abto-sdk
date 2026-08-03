# Browser JavaScript

## Install

Use the repository's package manager:

```bash
npm install @abto-app/event
pnpm add @abto-app/event
yarn add @abto-app/event
```

Install only one way.
Do not switch package managers or create a second lockfile.

## Define product events

Create or extend `abto.events.ts` as the product event schema:

```ts
import { defineEvents } from "@abto-app/event";

export const events = defineEvents({
  checkout_completed: {
    description: "Checkout completed",
    properties: {
      order_id: { type: "string", required: true },
      amount: { type: "number", required: true },
      currency: {
        type: "string",
        enum: ["KRW", "USD"],
        required: true,
      },
    },
  },
});
```

Do not register custom event or property names beginning with `$`.
ABTO reserves that namespace for system context.

## Initialize once

Initialize from the client application root:

```ts
import { initAbto } from "@abto-app/event";
import { events } from "./abto.events";

export const abto = initAbto({
  projectKey: publicEventKey,
  apiHost: "https://api.abto.app",
  environment: isProduction ? "production" : "development",
  events,
});
```

Resolve `publicEventKey` through the framework's existing public configuration mechanism.
For example, use `NEXT_PUBLIC_` only in Next.js or `VITE_` only in Vite.
Do not initialize during server rendering.
Prevent duplicate initialization during hot reload or repeated component mounts.

## Identify and capture

```ts
abto.identify("user_123", "tenant_123");

abto.capture("checkout_completed", {
  order_id: "order_123",
  amount: 49_000,
  currency: "KRW",
});
```

Call `reset()` on logout.
Use `forgetDevice()` only for a user-requested local data reset.

## Correlate a model call

```ts
const trace = abto.startLlmTrace({
  nodeId: "support.reply",
  taskType: "answer_generation",
  surface: "support_chat",
});

await trace.submitPrompt({ language: "ko" });

const response = await fetch("/api/support/reply", {
  method: "POST",
  headers: {
    "content-type": "application/json",
    ...trace.getHeaders(),
  },
  body: JSON.stringify({ message }),
});

trace.attachRequestId(response);
await trace.markResponseRendered({ responseId: "response_123" });
await trace.captureResponseInteraction("accepted", {
  responseId: "response_123",
});
```

Pass the trace headers to the application's backend.
Do not call a provider directly from the browser with a provider credential.

## Privacy defaults

- Keep prompt and response capture at `metadata_only`.
- Keep DOM and input masking enabled.
- Preserve `data-abto-no-capture` and `data-abto-sensitive`.
- Treat `data-abto-include` and full content capture as explicit policy changes requiring user approval.
- Never collect password, hidden, payment-card, secret, or authentication input values.
