<p align="right">
  <a href="./README.md">한국어</a> · <strong>English</strong>
</p>

<div align="center">
  <h1>ABTO SDK</h1>
  <p><strong>Connect product behavior with AI cost, latency, and quality in one observable flow.</strong></p>
  <p><sub>Browser, server, and mobile SDKs—plus one integration Skill for coding agents.</sub></p>
  <p>
    <a href="https://github.com/greedy-co/abto-sdk/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/greedy-co/abto-sdk/ci.yml?branch=main&style=flat-square&label=SDK%20CI" alt="SDK CI"></a>
    <a href="https://docs.abto.app/"><img src="https://img.shields.io/badge/docs-docs.abto.app-2563eb?style=flat-square" alt="Documentation"></a>
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
npx --yes skills@1.5.20 add https://github.com/greedy-co/abto-sdk/tree/main/abto \
  --skill abto \
  --global \
  --agent codex \
  --copy \
  --yes
```

#### Claude Code

```bash
npx --yes skills@1.5.20 add https://github.com/greedy-co/abto-sdk/tree/main/abto \
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

Start with the SDK that matches one runtime and one responsibility. Use an **Event SDK** to observe user behavior in a browser or app. Use a **Calling SDK** when your server sends model requests.

| Runtime | Responsibility | Package | Install | Status |
| --- | --- | --- | --- | --- |
| Browser JavaScript | Events and autocapture | [`@abto-app/event`](https://www.npmjs.com/package/@abto-app/event) | `npm install @abto-app/event` | Available |
| Node.js | Gateway calls and request context | [`@abto-app/calling`](https://www.npmjs.com/package/@abto-app/calling) | `npm install @abto-app/calling openai` | Available |
| Python | Gateway calls and request context | [`abto`](https://pypi.org/project/abto/) | `python -m pip install "abto[openai]"` | Available |
| Flutter / Dart | App events | [`abto`](https://pub.dev/packages/abto) | `dart pub add abto` | Available |
| Android / Kotlin | App events | [`packages/mobile/android`](./packages/mobile/android) | Public Maven Central release pending | Planned |
| iOS / macOS | App events | [`AbtoApp`](./packages/mobile/swift) | Swift Package Manager | Available |

Add the package with Swift Package Manager:

```swift
.package(
    url: "https://github.com/greedy-co/abto-sdk.git",
    from: "0.1.1"
)
```

> The Android SDK source is public, but the Maven Central release is still pending. Do not guess a package coordinate or copy the source into an app. The current Dart SDK does not support Flutter Web; use the Browser JavaScript SDK at that boundary.

## Connect the flow

ABTO joins client events and server-side model calls through shared identifiers.

1. Forward the client's stable `device_id` with the related server request.
2. Name the product surface with a dot-separated `nodeKey`, such as `support.reply`.
3. Use one `trace_id` for the model calls triggered by one user action.
4. Attach the Gateway's `x-request-id` response header to the rendered result and the user's outcome.

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
    ├── android/          # public release pending
    └── swift/            # AbtoApp

abto/
├── SKILL.md              # unified Agent Skill
└── references/           # runtime integration and verification guides
```

SDKs on the same `major.minor` line implement the same capability contract. Each SDK advances its patch version and release tag independently—for example, `event-js-v0.1.1`, `calling-python-v0.1.3`, and `swift-v0.1.1`.

## Docs and support

| Topic | Link |
| --- | --- |
| All documentation | [docs.abto.app](https://docs.abto.app/) |
| Browser JavaScript | [Setup and API guide](https://docs.abto.app/sdk/javascript/browser/) |
| Node.js | [Setup and API guide](https://docs.abto.app/sdk/javascript/server/) |
| Python | [Setup and API guide](https://docs.abto.app/sdk/python/) |
| Flutter / Dart | [Setup and API guide](https://docs.abto.app/sdk/flutter/) |
| Android / Kotlin | [Public release status](https://docs.abto.app/sdk/android/) |
| iOS / macOS | [Setup and API guide](https://docs.abto.app/sdk/ios/) |
| Report a problem | [GitHub Issues](https://github.com/greedy-co/abto-sdk/issues) |

Before contributing, read the README and test commands in the SDK directory you plan to change. Every pull request runs public-repository safety checks; SDK changes also trigger validation for the affected runtime.

## License

The SDK source in this repository is available under the [MIT License](./LICENSE).
