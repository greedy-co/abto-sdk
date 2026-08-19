<p align="right">
  <a href="./README.md">한국어</a> · <strong>English</strong>
</p>

<div align="center">
  <img src="./assets/abto-icon.svg" width="96" alt="ABTO icon">
  <br/>
  <h1>ABTO SDK</h1>
  <p><strong>Connect product behavior with AI cost, latency, and quality in one observable flow.</strong></p>
  <p><sub>Browser, mobile, and server SDKs—plus one integration Skill for coding agents.</sub></p>
  <p>
    <a href="https://github.com/greedy-co/abto-sdk/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/greedy-co/abto-sdk/ci.yml?branch=main&style=flat-square&label=SDK%20CI" alt="SDK CI"></a>
    <a href="https://github.com/greedy-co/abto-sdk/releases/latest"><img src="https://img.shields.io/github/v/release/greedy-co/abto-sdk?style=flat-square&label=release" alt="Latest release"></a>
    <a href="https://github.com/greedy-co/abto-sdk/releases"><img src="https://img.shields.io/github/release-date/greedy-co/abto-sdk?style=flat-square&label=released" alt="Release date"></a>
    <a href="https://docs.abto.app/en/"><img src="https://img.shields.io/badge/docs-docs.abto.app-2563eb?style=flat-square" alt="Documentation"></a>
    <a href="./LICENSE"><img src="https://img.shields.io/badge/license-MIT-22c55e?style=flat-square" alt="MIT License"></a>
  </p>
</div>

<p align="center">
  <a href="#quick-start">Quick start</a> ·
  <a href="#install-manually">Choose an SDK</a> ·
  <a href="#connect-the-flow">How it connects</a> ·
  <a href="#keys-and-security-boundaries">Security</a> ·
  <a href="#docs-and-support">Docs</a>
</p>

> AI calls happen on the server. The user behavior that tells you whether those calls worked happens in the product. ABTO SDK connects both sides with `device_id`, `trace_id`, and `request_id`.

```text
User behavior ── Event SDK ───────────────┐
                                          ├── ABTO ── cost · latency · quality
LLM calls ────── Calling SDK ── Gateway ─┘
                   device_id · trace_id · request_id
```

## Quick start

### Let your coding agent integrate ABTO

The ABTO Skill inspects your runtime and package manager, installs only the SDKs your project needs, and runs the build and a minimal integration check. Installing the Skill requires Node.js 22.20 or later.

#### Codex

```bash
npx --yes skills@latest add https://github.com/greedy-co/abto-sdk/tree/main/abto \
  --skill abto \
  --global \
  --agent codex \
  --copy \
  --yes
```

#### Claude Code

```bash
npx --yes skills@latest add https://github.com/greedy-co/abto-sdk/tree/main/abto \
  --skill abto \
  --global \
  --agent claude-code \
  --copy \
  --yes
```

Start a new agent session and ask:

```text
Integrate ABTO into this project and verify that the expected data reaches ABTO.
```

The agent keeps Event Keys and Calling Keys in the correct runtime and waits for you whenever real credentials or permissions are required. See the [ABTO Skill installation guide](./abto/references/skill-installation.md) for verification, updates, removal, and troubleshooting.

## Install manually

The SDK's role and key boundary depend on where it runs. Use an **Event SDK** in the browser or a mobile app to capture user behavior and outcomes. Use a **Calling SDK** on the server to route model requests through the Gateway. A complete integration can use both client and server SDKs.

### Browser SDK

Capture page interactions, navigation, and custom events. Put only an Event Key in the browser bundle—never a Calling Key or provider key.

| Runtime | Responsibility | Install | Distribution |
| --- | --- | --- | --- |
| Browser JavaScript | Events and autocapture | `npm install @abto-app/event` | [![npm version](https://img.shields.io/npm/v/@abto-app/event?style=flat-square&label=npm)](https://www.npmjs.com/package/@abto-app/event) |

See [`@abto-app/event`](./packages/browser/javascript) for package documentation and usage.

### Mobile SDKs

Capture product events and user outcomes in native apps. Mobile SDKs use only an Event Key and leave model calls to your server.

| Runtime | Package | Install | Distribution |
| --- | --- | --- | --- |
| Flutter / Dart | [`abto`](./packages/mobile/dart) | `dart pub add abto` | [![pub.dev version](https://img.shields.io/pub/v/abto?style=flat-square&label=pub.dev)](https://pub.dev/packages/abto) |
| Android / Kotlin | [`app.abto:abto-app`](./packages/mobile/android) | `implementation("app.abto:abto-app:0.1.4")` | [![Maven Central version](https://img.shields.io/maven-central/v/app.abto/abto-app?style=flat-square&label=Maven%20Central)](https://central.sonatype.com/artifact/app.abto/abto-app/0.1.4) |
| iOS / macOS | [`AbtoApp`](./packages/mobile/swift) | Swift Package Manager | [![SwiftPM tag](https://img.shields.io/github/v/tag/greedy-co/abto-sdk?filter=swift-v*&style=flat-square&label=SwiftPM)](https://github.com/greedy-co/abto-sdk/releases?q=swift) |

The Android artifact is a pure Kotlin/JVM JAR with no `android.*` dependency. In Android apps, adapt the existing `SharedPreferences` store to `AbtoKeyValueStore`.

Add the repository as a Swift Package:

```swift
.package(
    url: "https://github.com/greedy-co/abto-sdk.git",
    from: "0.1.2"
)
```

The current Dart SDK does not support Flutter Web. Use the Browser JavaScript SDK at that boundary.

### Server SDKs

Route server-side LLM requests through the ABTO Gateway and propagate `device_id`, `trace_id`, and `request_id` context. Keep Calling Keys and provider keys in server-side secret storage only.

| Runtime | Responsibility | Install | Distribution |
| --- | --- | --- | --- |
| Node.js | Gateway calls and request context | `npm install @abto-app/calling openai` | [![npm version](https://img.shields.io/npm/v/@abto-app/calling?style=flat-square&label=npm)](https://www.npmjs.com/package/@abto-app/calling) |
| Python | Gateway calls and request context | `python -m pip install "abto[openai]"` | [![PyPI version](https://img.shields.io/pypi/v/abto?style=flat-square&label=PyPI)](https://pypi.org/project/abto/) |

See the [Node.js Calling SDK](./packages/server/javascript) and [Python Calling SDK](./packages/server/python) for package-specific usage.

## Connect the flow

ABTO joins client events and server-side model calls through shared identifiers.

1. Forward the client's stable `device_id` with the related server request.
2. Name the product surface with a dot-separated `nodeKey`, such as `support.reply`.
3. Use one `trace_id` for the model calls triggered by one user action.
4. Attach the Gateway's `x-abto-request-id` response header to the rendered result and the user's outcome.

The Gateway is the source of truth for provider execution, token usage, cost, latency, retries, variant assignment, and `request_id`. Event and Calling SDKs do not estimate those facts independently.

| Component | What it does | What it does not do |
| --- | --- | --- |
| Event SDK | Captures user behavior, product events, and response outcomes | Calls providers or stores server secrets |
| Calling SDK | Routes LLM requests through the Gateway and propagates request context | Captures browser events |
| ABTO Skill | Automates SDK selection, installation, configuration, and verification | Creates keys or changes secrets without approval |

## Keys and security boundaries

| Key | Client bundle | Purpose |
| --- | :---: | --- |
| Event Key (`ek-abto-…`) | Allowed | Browser and app event collection |
| Calling Key (`ck-abto-…`) | Never | Server-to-Gateway authentication |
| Provider key | Never | Upstream provider authentication |

Keep Calling Keys and provider keys in server-side secret storage only. The Browser Event SDK's default privacy settings keep prompt and response capture at metadata level and mask DOM text and input values. Enable full content capture only after reviewing the data policy and approving it explicitly.

## Repository layout and releases

```text
packages/
├── browser/javascript/   # @abto-app/event
├── server/
│   ├── javascript/       # @abto-app/calling
│   └── python/           # abto
└── mobile/
    ├── dart/             # abto
    ├── android/          # app.abto:abto-app
    └── swift/            # AbtoApp

abto/
├── SKILL.md              # unified Agent Skill
└── references/           # runtime integration and verification guides
```

SDKs on the same `major.minor` line implement the same capability contract. Each SDK advances its patch version and release tag independently—for example, `event-js-v0.1.1`, `calling-python-v0.1.3`, and `swift-v0.1.1`.

## Docs and support

| Topic | Link |
| --- | --- |
| All documentation | [docs.abto.app](https://docs.abto.app/en/) |
| Browser JavaScript | [Setup and API guide](https://docs.abto.app/en/sdk/javascript/browser/) |
| Node.js | [Setup and API guide](https://docs.abto.app/en/sdk/javascript/server/) |
| Python | [Setup and API guide](https://docs.abto.app/en/sdk/python/) |
| Flutter / Dart | [Setup and API guide](https://docs.abto.app/en/sdk/flutter/) |
| Android / Kotlin | [Setup and API guide](https://docs.abto.app/en/sdk/android/) |
| iOS / macOS | [Setup and API guide](https://docs.abto.app/en/sdk/ios/) |
| Report a problem | [GitHub Issues](https://github.com/greedy-co/abto-sdk/issues) |

Before contributing, read the README and test commands in the SDK directory you plan to change. Every pull request runs public-repository safety checks; SDK changes also trigger validation for the affected runtime.

## License

The SDK source in this repository is available under the [MIT License](./LICENSE).
