---
name: abto-sdk
description: Install and integrate ABTO SDKs across browser JavaScript, Node.js, Python, Flutter/Dart, Android/Kotlin, and iOS/macOS. Use when selecting a Browser, App, or Server SDK; setting up ABTO event collection or Gateway calling; configuring Event or Calling Keys; linking device_id, trace_id, and request_id; troubleshooting an ABTO integration; or verifying that an ABTO SDK is wired correctly.
---

# ABTO SDK

Inspect the project, choose the smallest correct SDK set, preserve its existing conventions, configure credentials at the correct security boundary, and verify the integration.

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

### 4. Install and wire

- Use the chosen runtime reference for the package coordinate and initialization API.
- Initialize an Event SDK once at the client application root.
- Wrap each server request in ABTO request context with a stable `deviceId`, a dot-separated `nodeKey`, and a trace identifier.
- Pass the same device identifier from the client to the server when the product links user behavior to model calls.
- Capture the Gateway `x-request-id` and attach it to the related client outcome.
- Keep custom event names in the product's domain language. Do not create names beginning with `$`.
- Retain safe privacy defaults.
  Do not enable full prompt, response, DOM text, or input capture unless the user has explicitly approved the data policy.

### 5. Verify and report

- Run the project's typecheck, build, lint, and tests affected by the integration.
- Check the diff for client/server boundary violations and accidentally committed credentials.
- Run one bounded live event or model-call check only when the required credentials, environment, and any paid call are authorized.
- Confirm the expected ABTO receiving surface, not merely a successful local build.
- Report the selected SDKs, changed files, commands run, observed ABTO result, and any remaining user-owned step.
