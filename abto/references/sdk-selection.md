# SDK selection

## Choose by runtime and responsibility

| Runtime | Public status | Responsibility | Package | Credential |
|---|---|---|---|---|
| Browser JavaScript | Available | Identity, trace headers, opt-in system or custom events | `@abto-app/event` | Event Key |
| Node.js backend | Available | OpenAI Chat Completions Gateway calls and request context | `@abto-app/calling` | Calling Key plus provider keys |
| Python backend | Available | OpenAI Chat Completions Gateway calls and request context | `abto[openai]` | Calling Key plus provider keys |
| Flutter/Dart native app | Available | Identity and opt-in app outcomes | `abto` | Event Key |
| Android/Kotlin app | Available | Identity and opt-in app outcomes | `app.abto:abto-app` | Event Key |
| iOS/macOS app | Available | Identity and opt-in app outcomes | `AbtoApp` | Event Key |

The table is a runtime selection aid. Confirm current availability and installation instructions on the official Docs before installing.

Use an Event SDK when a confirmed client runtime must provide stable identity or a user-selected event.
Use a Calling SDK for approved server-side OpenAI Chat Completions execution.
Do not install an Event SDK in an unrelated client merely because a backend exists.
Do not use a Calling SDK for browser or mobile event collection.
Do not use an Event Key to authenticate Gateway calls.

Flutter Web is not supported by the current Dart package because its transport uses `dart:io`.
Treat Flutter Web as a web runtime and use the Browser JavaScript integration only when the application can load JavaScript at that boundary.

## Calling compatibility

The Gateway inbound contract is OpenAI Chat Completions.
Provider keys for OpenAI, Anthropic, and Gemini allow the Gateway to select an egress provider; they do not make every provider's native client API an accepted inbound contract.

Automatically wire only an executable call that preserves the existing OpenAI Chat Completions request and response semantics.
Inventory but do not automatically migrate:

- OpenAI Responses, embeddings, images, audio, assistants, or batch APIs;
- native Anthropic Messages or Gemini generate-content calls;
- a framework or raw HTTP wrapper whose actual request contract cannot be confirmed.

Report an incompatible or ambiguous surface with its exact location.
Do not hide it, replace it with generated glue, or count it as successfully integrated.

## Shared endpoints

| Plane | Default |
|---|---|
| Event collection | `https://api.abto.app/v1/collect/events` |
| Gateway | `https://gateway.abto.app/v1` |
| Product documentation | [https://docs.abto.app/](https://docs.abto.app/) |

Do not replace these defaults with guessed development hosts.
Keep the default `apiHost` unless the user provides an environment-specific API host.

## Read current official documentation

Fetch and read the relevant official [ABTO Docs](https://docs.abto.app/) pages at the start of each integration or update task, even when the API looks familiar.
Docs own installation commands, API examples, compatibility limits, and product explanations; this skill owns the integration workflow.
Read the page content, not only search snippets or a cached summary. Reuse the fetched pages within the same task, and fetch again when the task resumes after a release or documentation change.
If fetching fails, report that current documentation could not be verified; do not invent an API or claim it is current. Continue independent repository discovery.
When explicitly reviewing unpublished ABTO changes, use the corresponding source under `apps/docs/src/content/docs` and name the reviewed commit. Do not treat that source as proof of public package availability.

Start with the generated [documentation index](https://docs.abto.app/llms.txt) to select the relevant guide.
For either language, replace the page URL’s trailing `/` with `.md` to fetch its body, for example `https://docs.abto.app/sdk/javascript/server.md`.
Use [the English index](https://docs.abto.app/en/llms.txt) and `/en/` page paths for English documentation.
If that endpoint is unavailable, read the canonical HTML page. Use [full text](https://docs.abto.app/llms-full.txt) only when broader context is needed.
The index and page bodies are generated from Docs source; fetching them does not update the installed skill or SDK.
Do not assume a docs search API or MCP server exists.

Use the narrowest relevant page:

| Question | Documentation route |
|---|---|
| SDK role, key placement, or public support | `/sdk/` |
| Gateway request fields, errors, or compatibility | `/gateway/overview/`, `/gateway/chat-completions/` |
| Browser API | [Browser JavaScript](https://docs.abto.app/sdk/javascript/browser/) |
| Node.js, CommonJS/ESM, LangChain, tracing | [Node.js JavaScript](https://docs.abto.app/sdk/javascript/server/) |
| Python API | [Python](https://docs.abto.app/sdk/python/) |
| Flutter, Android, or iOS API | [Flutter](https://docs.abto.app/sdk/flutter/), [Android](https://docs.abto.app/sdk/android/), [iOS](https://docs.abto.app/sdk/ios/) |
| Event schema, privacy, or collection behavior | `/events/` |
| Features, variants, routing, or Success Metrics | `/concepts/` and the matching `/dashboard/.../` page |
| Troubleshooting | `/faq/` |

Use the documentation to establish ABTO's intended product behavior, then verify the exact callable API against the customer's installed public package version, types, and public source.
If the documentation and installed artifact disagree, report the conflict and follow [SDK defect handling](sdk-defect-handling.md); do not silently choose one, target unreleased source, or generate customer-side compatibility glue.
Record the documentation URLs, access date, and installed package coordinates and versions used for the integration.

## Identity and correlation

- Treat `device_id` as the join key between client behavior and Gateway calls.
- Carry one stable client device identifier through the existing request into the corresponding server context.
- Use a dot-separated `featureId`, such as `support.reply`, only after the user approves its exact capability and call site.
- Read the Gateway response header `x-abto-request-id` only when a selected event path needs it.
- Attach that request identifier only with an SDK path that establishes the correlation.

Do not generate a second server device identifier for the same client installation.
For a server-only call with no stable product identifier, ask before defining a new identity policy.

For a Gateway-served call, the Gateway owns provider execution, token usage, cost, latency, provider routing, variant assignment, and `request_id`.
When Node.js or Python direct OpenAI fallback is enabled, the Calling SDK owns only the decision to bypass a safely classified Gateway availability failure.
It does not classify or retry OpenAI or model-provider errors after that switch; the official OpenAI SDK keeps its configured retry policy.
Do not add a second fallback retry setting or override the customer's native OpenAI retry configuration.
The direct call bypasses Gateway policy, ABTO telemetry, and `request_id`.
Do not recreate Gateway facts in an Event SDK, and do not report a direct fallback call as Gateway-observed.

## Key boundary

| Key | May appear in a client bundle | Use |
|---|---|---|
| Event Key (`ek-abto-…`) | Yes | Client identity and event collection |
| Calling Key (`ck-abto-…`) | No | Gateway authentication |
| Provider key | No | Upstream provider authentication |

Use the target framework's public environment-variable convention only for the Event Key.
Keep Calling Keys and provider credentials in server-only secret storage.
