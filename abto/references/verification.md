# Verification

## Approval and coverage gates

Before checking builds, verify the interaction record:

- The user confirmed the exact repository/runtime map before the first file edit.
- Every model-call search hit is represented in the LLM inventory or documented as a non-runtime false positive.
- Every inventory row ends as `wired`, `already wired`, `incompatible`, `ambiguous`, `user-excluded`, or `blocked-sdk-defect`.
- Every newly wired call matches a user-approved candidate ID, exact code location, and dot-separated `nodeKey`.
- Every approved call records its resolved Gateway and direct-fallback paths; no direct call is reported as Gateway-observed.
- No incompatible or ambiguous API was silently converted into OpenAI Chat Completions.
- Every event-related edit maps to a user-selected event candidate ID and exact trigger.
- Every ABTO-specific uncertainty is resolved through the official [ABTO Docs](https://docs.abto.app/) or remains explicitly unresolved without a guessed implementation.
- Every version-specific API used after a documentation lookup is verified against the customer's installed public package, types, and public source; any conflict is classified instead of hidden in generated glue.
- Every `blocked-sdk-defect` entry records the installed public package and version, released contract, sanitized reproduction, expected behavior, and actual behavior.
- Every suspected SDK defect checks compatible stable public releases before upstream source work or `blocked-sdk-defect` classification.
- Every defect resolved by a public update records the previous and installed versions and passes the original reproduction and approved integration path before becoming `wired`.
- Editing an upstream SDK repository or adding a temporary customer workaround has separate explicit approval.

Do not claim full LLM coverage while an unexplained hit or candidate remains.

## Local gates

Run the repository's existing gates for every changed runtime:

| Runtime | Minimum check |
|---|---|
| Browser or Node.js | dependency install, typecheck, tests, production build |
| Python | dependency install, tests, package or application import check |
| Flutter/Dart | `dart analyze`, `dart test` |
| Android/Kotlin | Gradle dependency resolution, `gradle check`, application build |
| iOS/macOS | Xcode build or `swift build` for the affected package |

Also verify:

- If the repository already manages a lockfile for the selected package manager, update that lockfile.
- Do not introduce a new lockfile convention only for the ABTO integration.
- One initialization exists per application runtime.
- A new Browser Core uses a compatible public SDK, omits the `autocapture` setting, and emits no automatic events before Event approval.
- A fixed Browser SDK integration does not retain an unnecessary `autocapture: { enabled: false }` compatibility guard.
- An existing Browser initialization retains and reports its previous automatic event collection behavior.
- Client bundles contain only an Event Key.
- Calling Keys and provider keys resolve only from server secret storage.
- The exact client device identifier reaches the corresponding server context and approved Gateway call.
- Client-supplied identity and trace values pass through existing request validation.
- No new server identity or per-request random device identifier replaces an available client device identifier.
- No custom event or property name starts with `$`.
- Event payloads do not include unapproved prompt, response, DOM text, form values, or secrets.
- A selected system event uses only its approved trigger and metadata.
- A response-interaction system event uses only a canonical value exposed by the installed SDK.
- A selected custom event has an explicit schema and only its approved capture locations.
- Every new event call names the user-selected candidate ID and exact product trigger; no automatic DOM collection substitutes for that call.
- When no event is selected, the diff contains no event schema, `capture` call, AI system-event call, or request-ID bridge.
- When a related supported event is selected, the Gateway `x-abto-request-id` reaches only that approved trigger location.
- Customer dependency directories, generated vendor code, and lockfile-resolved package contents remain unpatched.
- A defect-driven dependency update changes only the affected direct SDK and necessary lockfile resolution; a prerelease, incompatible runtime, or new major version has explicit approval.
- Customer repositories contain no new test scaffold created only to prove an SDK defect.
- An authorized upstream SDK correction includes the smallest SDK-owned regression check that reproduces the defect and passes the affected package's existing gates.
- A temporary customer workaround exists only with explicit approval, an isolated location, affected version range, defect ID, and removal condition.

Inspect the final diff and repository status without printing secret values.
Classify every changed file as `Core` or `Event <candidate ID>` and remove any unclassified demonstration, placeholder, wrapper, endpoint, abstraction, refactor, initialization, dependency, or lockfile.

## Bounded live check

Run a live check only when the user has authorized the target environment, credentials, and any paid model call.

### Event plane

Run this check only when the user selected an event:

1. Trigger one selected event with a non-sensitive test identifier.
2. Flush the SDK when the runtime requires it.
3. Confirm that ABTO accepted the event and that it appears under the intended project and environment.
4. For a selected request-correlated system event, confirm the approved `request_id` link.

### Calling plane

1. Send one minimal, low-cost approved Chat Completions request through the ABTO Gateway.
2. Confirm a successful response and a non-empty `x-abto-request-id`.
3. Confirm the request under the intended ABTO project.

Do not treat a local `2xx` from the product backend as proof that ABTO received data.
Do not send production traffic merely to complete a check.

## Report

Use exactly the three headings defined in [Discovery and reporting](discovery-and-reporting.md).
State:

- The confirmed repository map and selected SDKs.
- The complete LLM inventory with final status for every candidate.
- Core files and behavior changed, local commands, and results.
- Event candidates, selected or declined IDs, Event files changed, and privacy impact.
- A Core-versus-Event change ledger.
- A Mermaid diagram using the actual device, trace, Gateway, provider, and selected event paths.
- The resolved direct-fallback setting and any provider path without Gateway policy, ABTO telemetry, or `request_id`.
- The observed ABTO receiving surface or the exact reason a live check was skipped.
- The exact official ABTO Docs page and installed package coordinate and version used for any resolved knowledge gap.
- Each SDK defect's classification, previous and installed versions, checked public versions, customer impact, update or upstream changes, release state, and re-verification result.
