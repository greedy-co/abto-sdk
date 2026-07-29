# Verification

## Local gates

Run the repository's existing gates for every changed runtime:

| Runtime | Minimum check |
|---|---|
| Browser or Node.js | dependency install, typecheck, tests, production build |
| Python | dependency install, tests, package or application import check |
| Flutter/Dart | `dart analyze`, `dart test` |
| Android/Kotlin | Gradle compile/check for the affected module |
| iOS/macOS | Xcode build or `swift build` for the affected package |

Also verify:

- One lockfile changed for the selected package manager.
- One initialization exists per application runtime.
- Client bundles contain only an Event Key.
- Calling Keys and provider keys resolve only from server secret storage.
- No custom event or property name starts with `$`.
- Event payloads do not include unapproved prompt, response, DOM text, form values, or secrets.
- The client device identifier reaches the corresponding server context.
- The Gateway `x-request-id` reaches the related client outcome.

Inspect the final diff and repository status without printing secret values.

## Bounded live check

Run a live check only when the user has authorized the target environment, credentials,
and any paid model call.

### Event plane

1. Use a unique, valid custom event already declared by the product.
2. Capture the event with a non-sensitive test identifier.
3. Flush the SDK.
4. Confirm that ABTO accepted the event and that it appears under the intended project and environment.

### Calling plane

1. Send one minimal, low-cost request through the ABTO Gateway.
2. Confirm a successful response and a non-empty `x-request-id`.
3. Confirm the request under the intended ABTO project.
4. If a client outcome exists, attach the same request identifier and confirm correlation.

Do not treat a local `2xx` from the product backend as proof that ABTO received data.
Do not send production traffic merely to complete a check.

## Report

State:

- Selected SDKs and why each was selected.
- Package versions and configuration files changed.
- Local verification commands and results.
- Live event or request identifier without revealing credentials.
- The ABTO receiving surface checked.
- Any live check skipped because credentials, cost authorization, or environment access was unavailable.
