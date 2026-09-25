# Server SDKs

## Contents

- [Supported calling boundary](#supported-calling-boundary)
- [Node.js](#nodejs)
- [LangChain](#langchain)
- [Python](#python)
- [Preserve and disclose direct fallback](#preserve-and-disclose-direct-fallback)
- [Add request correlation only when selected](#add-request-correlation-only-when-selected)
- [Validate and propagate context](#validate-and-propagate-context)

## Supported calling boundary

Automatically wire only confirmed OpenAI Chat Completions calls.
The Gateway may route that request to OpenAI, Anthropic, Gemini, DeepSeek, or Kimi with the corresponding provider key, but it does not accept those providers' native inbound request APIs.

Inventory and report OpenAI Responses or other OpenAI APIs, native Anthropic or Gemini clients, and ambiguous framework or raw HTTP wrappers.
Do not migrate them, generate an adapter, or change streaming and error semantics merely to increase the number of wired calls.

Initialize one shared ABTO client through the application's existing server configuration or provider-client module.
Create a small dedicated module only when no suitable module exists.

## Node.js

Read the current [Node.js JavaScript guide](https://docs.abto.app/sdk/javascript/server/) for installation, credentials, initialization, CommonJS/ESM usage, and request examples.
Adapt its example to the customer's package manager and existing configuration module; verify the installed SDK exports and the Node requirements of all selected dependencies.
Keep Calling Keys and provider keys on the server. Preserve the existing completion return shape and wrap only the approved call with its request context.

## LangChain

Read the LangChain and tracing sections of the current [Node.js JavaScript guide](https://docs.abto.app/sdk/javascript/server/) or [Python guide](https://docs.abto.app/sdk/python/), matching the application language.
Confirm that the customer's actual ChatOpenAI call uses Chat Completions and accepts client configuration.
Verify that the installed public Calling SDK exposes the documented configuration API before using it; if absent, check for a compatible published release rather than importing internal source or inventing an adapter.
Keep the customer's model options, custom fetch, invoke calls, chains, parsers, callbacks, tracing initialization, and retry policy.
Apply request context at invocation time rather than storing one user's device ID on a shared model.
Use Docs for version-specific tracing guidance; do not copy a fixed compatibility matrix into this skill.
Do not convert the customer's module system or silently chain a third-party router to complete the integration.

## Python

Read the current [Python guide](https://docs.abto.app/sdk/python/) for installation, credentials, initialization, and request examples.
Verify the installed public API and Python requirements, and keep the framework's existing sync or async pattern.
Do not introduce a second concurrency model only for ABTO.

## Preserve and disclose direct fallback

The current Node.js and Python Calling SDKs enable direct OpenAI fallback for safely classified Gateway failures when a fallback base URL is configured.
Naming that destination is what turns it on; there is no separate enable flag, and configuring nothing leaves it off.
A base URL with no OpenAI key source fails at init, because there would be no key to send along the direct path.
Never report fallback as active without confirming the configured base URL.
Preserve the resolved setting during Core wiring unless the user explicitly approves changing the application's availability policy.
Do not set `fallback: false` or enable timeout replay merely to make ABTO reporting simpler.
Direct fallback returns the request to the endpoint the application called before ABTO, so its destination is customer input, never a default.
Resolve and confirm the destination with the skill user during the existing LLM inventory approval, before applying configuration:

1. Trace each call's effective pre-ABTO endpoint through its client constructor, shared configuration, environment references, and installed provider SDK's precedence rules. Record its source location and configuration expression. An implicit provider SDK default counts as discovered only when the installed SDK and applicable overrides establish it; an API key or model name alone is not evidence of the endpoint.
2. **Destination found:** automatically prefill the proposed `fallback.baseURL` (JavaScript) or `fallback.base_url` (Python) from that existing configuration. Show the destination, evidence, and resulting fallback behavior, then ask the user to confirm it with the call IDs. Reuse environment/configuration references rather than hardcoding their resolved values; redact credentials in URLs and never ask the user to paste secrets.
3. **Destination missing or ambiguous:** ask which base URL that call should use for direct fallback, or whether the user explicitly wants no fallback. Do not substitute `https://api.openai.com/v1` from an example or silently leave fallback off. Keep the affected path pending until answered; continue independently approved paths.
4. Apply only the confirmed proposal or user-supplied destination. An existing explicit fallback choice, including disabled fallback, takes precedence over rediscovery; preserve it and do not ask again when already authorized in this task. A new proposal must not silently enable fallback or replace that choice.

Keep different destinations separate by call path and environment; do not reuse one discovered URL for every model client.
A third-party router URL alone does not establish compatibility: verify the installed Calling SDK can preserve its required protocol, credentials, and headers before offering it as an eligible fallback. If not, report the incompatibility and ask for a supported destination or no fallback; do not substitute a provider endpoint or invent a router adapter.
The automatic step prepares a reviewable configuration candidate, not an unconfirmed availability-policy change.
Preserve existing timeout and timeout-replay choices; do not copy `timeoutMs: 30_000` or `onTimeout: false` over customer settings merely because they appear in an example.
Tell the user plainly that without it there is no fallback: a Gateway outage makes those requests fail outright.
Setting any other fallback option without it fails at init; configuring nothing leaves fallback off.

The Calling SDK owns only Gateway-outage failover. Do not add Calling SDK retries or error classification for OpenAI or model-provider failures.
Preserve the customer's native OpenAI `maxRetries` or `max_retries` setting and SDK default.
Do not add a fallback attempt counter, translate retry semantics, or silently set native retries to zero.
An ambiguous timeout or disconnect must not become a direct replay unless the installed SDK exposes an explicit timeout-replay opt-in and the user approves it.

Preserve the rest of the official OpenAI client configuration too.
For Node.js, the Calling SDK owns `baseURL` and `apiKey` and keeps its ABTO wrapper as the outer `fetch`; a caller-provided `clientOptions.fetch` is the underlying transport and must not be deleted.
For Python, follow the current Docs for `openai_options()` and `async_openai_options()`: preserve supplied sync/async HTTP clients and their ownership, and close ABTO-created clients at application shutdown.
For customer clients, fetch the current [Python Docs](https://docs.abto.app/sdk/python.md) and check the installed `wrap_httpx_transport` API.
Find the client construction site and wrap its existing transport (including mounts); preserve TLS, proxy, timeout and observability settings.
Do not replace private client fields, bypass `send()`, or drop an environment proxy silently.
Keep manually configured logging outside the credential-injecting boundary.
Verify the customer send override and request/response hooks still run for success, error and configured fallback.
The `abto.openai(**kwargs)` factory owns `api_key`, `base_url`, and `http_client` and rejects those three reserved arguments.
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
- Validate `deviceId` and other client-supplied context using the application's existing request validation.
- Pass the same validated device identifier to every approved model call caused by that client action.
- Do not accept a Calling Key or provider key from a client request.
- For a server-only call, reuse a clearly established stable product identifier or ask the user when none exists.
- Read `x-abto-request-id` only when a selected supported event path needs it, and return it only to that approved client trigger.
