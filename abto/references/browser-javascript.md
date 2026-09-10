# Browser JavaScript

## Contents

- [Install](#install)
- [Initialize the minimal core](#initialize-the-minimal-core)
- [Carry identity to an approved model call](#carry-identity-to-an-approved-model-call)
- [Add selected system events only](#add-selected-system-events-only)
- [Add selected custom events only](#add-selected-custom-events-only)
- [Identity lifecycle](#identity-lifecycle)
- [Privacy defaults](#privacy-defaults)

## Install

Use the repository's package manager:

```bash
npm install @abto-app/event
pnpm add @abto-app/event
yarn add @abto-app/event
```

Install only one way.
Do not switch package managers or create a second lockfile.

## Initialize the minimal core

For a new integration, initialize once at the client application root:

```ts
import { initAbto } from "@abto-app/event";

export const abto = initAbto({
  projectKey: publicEventKey,
  apiHost: "https://api.abto.app",
  environment: isProduction ? "production" : "development",
});
```

Initialization emits nothing on its own: it must not enqueue page, route, or DOM events.
This core provides persistent client identity and trace headers without defining a custom event.
Do not create an empty event registry merely to initialize the SDK.

Verify the empty outbox after initialization.
If the installed release enqueues anything on its own, follow [SDK defect handling](sdk-defect-handling.md) instead of adding a suppression flag.

Resolve `publicEventKey` through the framework's existing public configuration mechanism.
For example, use `NEXT_PUBLIC_` only in Next.js or `VITE_` only in Vite.
Do not initialize during server rendering.
Prevent duplicate initialization during hot reload or repeated component mounts.

If ABTO is already initialized, preserve and report its existing automatic event collection behavior.
Do not silently change live collection while adding Core identity and trace wiring.

## Carry browser identity and trace to an approved model call

Use the existing client request:

```ts
const trace = abto.startLlmTrace();

const response = await fetch("/api/support/reply", {
  method: "POST",
  headers: {
    "content-type": "application/json",
    ...trace.getHeaders(),
  },
  body: JSON.stringify({ message }),
});
```

`trace.getHeaders()` carries only the SDK device identifier to the backend.
Do not send a browser-selected feature ID, task type, surface, or user identifier.
At the approved model call, the backend applies the selected `featureId` through the Calling SDK context.
Starting the trace and forwarding its headers do not emit an event.
Do not call a provider directly from the browser with a provider credential.

## Add selected system events only

Add these methods only when the user selected their exact candidate IDs and trigger locations:

```ts
await trace.submitPrompt({ language: "ko" });

trace.attachRequestId(response);
await trace.markResponseRendered({ responseId: "response_123" });
await trace.captureResponseInteraction("accepted", {
  responseId: "response_123",
});
```

The public TypeScript literal union and JavaScript runtime accept exactly `copied`, `inserted`, `accepted`, `rejected`, `shared`, `downloaded`, `expanded`, `collapsed`, `rated_positive`, `rated_negative`, `regenerated`, and `aborted`.
An unsupported runtime value is warned and dropped before enqueueing.
Never cast around this guard or invent a system value; propose a user-selected custom event for a product-specific action.

Do not return or expose `x-abto-request-id` from the product backend solely to demonstrate integration.
Add that response path only when a selected supported system event consumes it.

## Add selected custom events only

Create or extend `abto.events.ts` only after the user selects at least one custom event:

```ts
import { defineEvents } from "@abto-app/event";

export const events = defineEvents({
  checkout_completed: { description: "Checkout completed" },
});
```

Pass the selected registry to the existing initialization and capture only at the approved trigger:

```ts
abto.capture("checkout_completed", { value: 49000, scale: "KRW" });
```

`value` and `scale` are both optional (an empty scale string is allowed). The flat capture object can also be omitted; omitted metrics are not sent, and all other fields automatically move into `extra_json`.
Use `{ value: 1, scale: 'count' }` for a simple action count.
Do not introduce a nested `properties` wrapper. Show only value and scale in the basic setup example; add other fields only when the product needs them.
Do not register custom event names beginning with `$`.
ABTO reserves that namespace for system context.
Do not claim request correlation for a custom event unless the current SDK API explicitly establishes it.

## Identity lifecycle

Call `identify()` only at the product's existing authenticated identity boundary.
Call `reset()` on logout.
Use `forgetDevice()` only for a user-requested local data reset.

## Privacy defaults

- Keep prompt and response capture at `metadata_only` for every selected system event.
- Do not add automatic DOM collection; instrument only customer-selected events with direct SDK calls.
- Keep DOM and input masking enabled for any existing automatic collection.
- Preserve `data-abto-no-capture` and `data-abto-sensitive` in an existing integration.
- Treat `data-abto-include` and full content capture as explicit policy changes requiring user approval.
- Never collect password, hidden, payment-card, secret, or authentication input values.
