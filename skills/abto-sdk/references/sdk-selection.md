# SDK selection

## Choose by runtime and responsibility

| Runtime | Public status | Responsibility | Package | Credential |
|---|---|---|---|---|
| Browser JavaScript | Available | Autocapture, custom events, identity, client outcomes | `@abto-app/event` | Event Key |
| Node.js backend | Available | Gateway calls and request context | `@abto-app/calling` | Calling Key plus provider keys |
| Python backend | Available | Gateway calls and request context | `abto[openai]` | Calling Key plus provider keys |
| Flutter/Dart native app | Available | App events and client outcomes | `abto` | Event Key |
| Android/Kotlin app | Planned — do not install | App events and client outcomes | — | Event Key |
| iOS/macOS app | Available | App events and client outcomes | `AbtoApp` | Event Key |

Only rows marked Available have a verified public installation path.
For a Planned runtime, do not guess a package coordinate or install a local source snapshot.
Explain that the registry release is pending and propose an available boundary or a code-only plan.

Use an Event SDK for facts the client observes.
Use a Calling SDK for server-side model execution.
Do not use a Calling SDK for browser or mobile event collection.
Do not use an Event Key to authenticate Gateway calls.

Flutter Web is not supported by the current Dart package because its transport uses `dart:io`.
Treat Flutter Web as a web runtime and use the Browser JavaScript integration only when the application can load JavaScript at that boundary.

## Shared endpoints

| Plane | Default |
|---|---|
| Event collection | `https://api.abto.app/v1/collect/events` |
| Gateway | `https://gateway.abto.app/v1` |
| Product documentation | `https://docs.abto.app/` |

Do not replace these defaults with guessed development hosts.
Use a different host only when the user provides an environment-specific endpoint.

## Identity and correlation

- Treat `device_id` as the join key between client behavior and Gateway calls.
- Carry a stable device identifier from the client into the corresponding server request.
- Use a dot-separated `nodeKey`, such as `support.reply`, for the product feature node.
- Use one `trace_id` for one user action that can produce one or more model calls.
- Read the Gateway response header `x-request-id`.
- Attach that request identifier to the related client outcome.

The Gateway owns provider execution, token usage, cost, latency, retries, fallback facts, variant assignment, and `request_id`.
Do not recreate those facts in an Event or Calling SDK.

## Key boundary

| Key | May appear in a client bundle | Use |
|---|---|---|
| Event Key (`ek-abto-…`) | Yes | Event collection |
| Calling Key (`ck-abto-…`) | No | Gateway authentication |
| Provider key | No | Upstream provider authentication |

Use the target framework's public environment-variable convention only for the Event Key.
Keep Calling Keys and provider credentials in server-only secret storage.
