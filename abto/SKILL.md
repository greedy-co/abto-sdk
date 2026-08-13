---
name: abto
description: Integrate and verify ABTO across browser JavaScript, Node.js, Python, Flutter/Dart, Android/Kotlin, and iOS/macOS. Use when selecting, installing, updating, or troubleshooting an ABTO Browser, App, or Server SDK; setting up event collection or Gateway calling; configuring Event or Calling Keys; linking device_id, trace_id, and request_id; or checking that data reaches the expected ABTO surface.
---

# ABTO

Use this as the single public ABTO integration skill.
Inspect the project, choose the smallest correct SDK set, preserve its existing conventions, configure credentials at the correct security boundary, and verify the integration from the application to the expected ABTO surface.

## Load the relevant references

1. Always read [SDK selection](references/sdk-selection.md).
2. Read only the implementation reference for the selected runtime:
   - Browser JavaScript: [Browser JavaScript](references/browser-javascript.md)
   - Node.js or Python backend: [Server](references/server.md)
   - Flutter/Dart, Android/Kotlin, or iOS/macOS: [Mobile](references/mobile.md)
3. Read [Verification](references/verification.md) before declaring the integration complete.
4. Read [Skill installation](references/skill-installation.md) only when installing, updating, removing, or troubleshooting this agent skill itself.

## Integration workflow

### 1. Inspect before editing

- Read the repository instructions, package manifests, lockfiles, application entry points, existing telemetry code, and environment-variable conventions.
- Identify every runtime boundary in a monorepo.
  A web client and its backend are separate integration targets even when they share a repository.
- Check for an existing ABTO dependency or initialization before adding another one.
- Preserve the package manager, framework lifecycle, formatting, and test commands already in use.
- Keep unrelated user changes intact.

### 2. Select the SDKs

- Treat [SDK selection](references/sdk-selection.md) as the installation availability source of truth.
- Do not add a dependency for a runtime marked Planned.
  Explain the missing public release and offer an available runtime boundary or an integration plan instead.
- Install an Event SDK in a browser or native app that observes user behavior.
- Install a Calling SDK on a backend that sends model requests through the ABTO Gateway.
- Install both only when the product has both client behavior and server-side model calls.
- Never import a Server SDK into a client bundle.
- Never install multiple Event SDKs in the same runtime unless the application genuinely has separate platform targets.

### 3. Establish the security boundary

- Obtain real values from the user or the ABTO dashboard. Never invent keys.
- Put Event Keys only in client-side configuration intended for public delivery.
- Put Calling Keys and provider credentials only in server secret storage.
- Reuse the project's secret-management mechanism.
  Do not add secrets to source files, examples, logs, screenshots, shell history, or committed environment files.
- Stop and request the missing key or permission when a live integration cannot proceed safely.

### 4. Pause at the observability decision gates

Treat a request to integrate ABTO as approval only for the basic integration:
the selected SDK dependency, minimal root initialization, and configuration that follows the existing application conventions.
It does not authorize a new `nodeKey`, custom event, event-schema change, or unrelated product-code change.

Complete the applicable gates in order.
Ask one question, stop, and wait for a direct reply before moving to the next gate.
Do not collect nodeKey and event approval in one question.
An existing explicit nodeKey or event remains unchanged unless the user asks to change it.

1. **Basic integration**
   - Install only the selected SDK and add its minimal initialization.
   - Do not refactor product behavior, add custom capture, or change existing instrumentation merely to demonstrate ABTO.
   - If the basic integration already exists, report that fact and begin at the applicable decision gate.
2. **nodeKey gate** (Calling SDK only)
   - After basic integration, inspect the model-call boundaries without editing them.
   - Present one smallest candidate: the user-facing capability, exact code location, and proposed dot-separated `nodeKey`.
   - If no safe candidate is identifiable, ask the user what capability to track, its purpose, and its code location. Then stop for the reply; do not select a model-call boundary yourself.
   - Ask one focused question, such as: “I found `<capability>` at `<path>` and propose `<nodeKey>`. Should I set that key there?” Then stop for the reply.
   - Do not add, rename, move, or infer a nodeKey from product terminology before confirmation.
3. **Event gate** (Event SDK only)
   - For an integration with both SDKs, begin this gate only after the nodeKey gate is settled.
     For an Event-only integration, begin it after basic integration.
   - Ask whether a user-observed outcome needs a custom event at all; do not assume that one is required.
   - If an event may be useful, present one candidate event name, trigger location, approved properties, and privacy impact.
   - If no safe outcome or trigger is identifiable, ask the user what outcome to track, why it matters, and where it occurs. Then stop for the reply; do not invent an event candidate.
   - Ask one separate question, such as: “Should I capture `<event>` at `<path>` with these properties?” Then stop for the reply.
   - Do not invent a conversion event, add `capture` calls, or change an event schema before confirmation.
   - If the user declines or leaves the decision open, keep the basic integration intact and report the event as a user-owned follow-up.

### 5. Install and wire

- Use the chosen runtime reference for the package coordinate and initialization API.
- Initialize an Event SDK once at the client application root.
- Add a confirmed nodeKey to each selected server request context with a stable `deviceId` and trace identifier.
- Pass the same device identifier from the client to the server when the product links user behavior to model calls.
- Only when the user has confirmed the related client outcome event, capture the Gateway `x-abto-request-id` and attach it at that event's approved trigger location.
- Add a confirmed custom event only at its approved trigger location; keep its name in the product's domain language and never begin it with `$`.
- Retain safe privacy defaults.
  Do not enable full prompt, response, DOM text, or input capture unless the user has explicitly approved the data policy.

### 6. Verify and report

- Run the project's typecheck, build, lint, and tests affected by the integration.
- Check the diff for client/server boundary violations and accidentally committed credentials.
- Run one bounded live event or model-call check only when the required credentials, environment, and any paid call are authorized.
- Confirm the expected ABTO receiving surface, not merely a successful local build.
- Report the selected SDKs, each completed or pending decision gate, changed files, commands run, observed ABTO result, and any remaining user-owned step.
