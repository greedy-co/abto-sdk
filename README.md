# ABTO SDKs

Public SDKs for connecting product behavior with LLM request cost, latency, and quality.
This repository contains the installable source for ABTO's six supported SDKs.

## Agent setup

Install the ABTO SDK skill globally for the coding agent you use.
Node.js 22.20 or later is required.

Codex:

```bash
npx --yes skills@1.5.20 add https://github.com/greedy-co/abto-sdk/tree/main/skills/abto-sdk \
  --skill abto-sdk \
  --global \
  --agent codex \
  --copy \
  --yes
```

Claude Code:

```bash
npx --yes skills@1.5.20 add https://github.com/greedy-co/abto-sdk/tree/main/skills/abto-sdk \
  --skill abto-sdk \
  --global \
  --agent claude-code \
  --copy \
  --yes
```

The skill inspects an application, selects the correct Browser, App, or Server SDK, keeps Event and Calling Keys at the correct security boundary, and verifies the integration.
See [`skills/abto-sdk/references/skill-installation.md`](skills/abto-sdk/references/skill-installation.md) for verification, update, removal, and troubleshooting commands.

## Install

| Runtime | Package | Install |
|---|---|---|
| Browser JavaScript | `@abto-app/event` | `npm install @abto-app/event` |
| Server JavaScript | `@abto-app/calling` | `npm install @abto-app/calling` |
| Server Python | `abto` | `pip install abto` |
| Flutter / Dart | `abto` | `dart pub add abto` |
| Android / Kotlin | `app.abto:abto-app` | `implementation("app.abto:abto-app:0.1.0")` |
| iOS / macOS | `AbtoApp` | Swift Package Manager URL: `https://github.com/greedy-co/abto-sdk` |

For Swift packages:

```swift
.package(url: "https://github.com/greedy-co/abto-sdk.git", from: "0.1.0")
```

See [docs.abto.app](https://docs.abto.app/) for setup and API guides.

## Repository layout

```text
packages/
├── browser/
│   └── javascript/
├── server/
│   ├── javascript/
│   └── python/
└── mobile/
    ├── dart/
    ├── android/
    └── swift/
skills/
└── abto-sdk/
```

Browser and Server JavaScript are separate packages with separate dependency and security boundaries.
Python is server-only.
Mobile SDKs share the same event contract but are released independently.

All SDKs on the same `major.minor` line implement the same capability contract.
Each SDK advances its own patch version and release tag, such as `event-js-v0.1.4` or `calling-python-v0.1.2`.
Swift releases also receive a SemVer `vX.Y.Z` tag for SwiftPM.

## License

The SDK source in this repository is licensed under the MIT License.
