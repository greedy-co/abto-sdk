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

Only rows marked Available have a verified public installation path.

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
Use a different host only when the user provides an environment-specific endpoint.

## Official documentation fallback

Consult the official [ABTO Docs](https://docs.abto.app/) first when ABTO product semantics or integration behavior is missing or uncertain.
When the current checkout is the ABTO monorepo, prefer the corresponding source under `apps/docs/src/content/docs` so the reviewed documentation version is explicit; otherwise use the published site.

Use the narrowest relevant page:

| Question | Documentation route |
|---|---|
| SDK role, key placement, or public support | `/sdk/` |
| Gateway request fields, errors, or compatibility | `/sdk/gateway-compatibility/` |
| Browser, server, Python, Flutter, Android, or iOS API | The matching `/sdk/.../` runtime page |
| Event schema, privacy, or collection behavior | `/events/` |
| Nodes, variants, routing, or Success Metrics | `/concepts/` and the matching `/dashboard/.../` page |
| Troubleshooting | `/faq/` |

Use the documentation to establish ABTO's intended product behavior, then verify the exact callable API against the customer's installed public package version, types, and public source.
If the documentation and installed artifact disagree, report the conflict and follow [SDK defect handling](sdk-defect-handling.md); do not silently choose one, target unreleased source, or generate customer-side compatibility glue.
Record the exact documentation page and installed package coordinate and version used to resolve the uncertainty.

## Identity and correlation

- Treat `device_id` as the join key between client behavior and Gateway calls.
- Carry one stable client device identifier through the existing request into the corresponding server context.
- Use a dot-separated `nodeKey`, such as `support.reply`, only after the user approves its exact capability and call site.
- Use one `trace_id` for one user action that can produce one or more model calls.
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
