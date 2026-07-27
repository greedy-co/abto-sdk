# ABTO SDKs

Public SDKs for connecting product behavior with LLM request cost, latency, and quality.
This repository contains the installable source for ABTO's six supported SDKs.

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
```

Browser and Server JavaScript are separate packages with separate dependency and
security boundaries. Python is server-only. Mobile SDKs share the same event contract
but are released independently.

All SDKs on the same `major.minor` line implement the same capability contract. Each
SDK advances its own patch version and release tag, such as `event-js-v0.1.4` or
`calling-python-v0.1.2`. Swift releases also receive a SemVer `vX.Y.Z` tag for SwiftPM.

## License

The SDK source in this repository is licensed under the MIT License.
