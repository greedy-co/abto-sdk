# Mobile and native apps

Mobile SDKs use an Event Key and send product events to the Analytics event endpoint.
They do not route provider calls and must not receive a Calling Key or provider credential.

## Flutter and Dart

Require Dart 3.4 or later:

```bash
dart pub add abto
```

```dart
import "package:abto/abto.dart";

final abto = AbtoClient(
  AbtoConfig(
    projectKey: eventKey,
    endpoint: "https://api.abto.app/v1/collect/events",
    environment: AbtoEnvironment.production,
  ),
  store: appStore,
);
```

Provide an `AbtoKeyValueStore` backed by the application's existing secure preferences for persistent identity.
The package uses `dart:io` and does not support Flutter Web.

## Android and Kotlin

Use Maven Central and add the published Android/Kotlin package:

```kotlin
repositories {
    mavenCentral()
}

dependencies {
    implementation("app.abto:abto-app:0.2.0")
}
```

Provide an `AbtoKeyValueStore` backed by the application's existing `SharedPreferences`.

## iOS and macOS

Support iOS 14 or later and macOS 12 or later.
Add the public Swift Package:

```swift
.package(
    url: "https://github.com/greedy-co/abto-sdk.git",
    from: "0.2.0"
)
```

```swift
import AbtoApp

let abto = try AbtoClient(
    projectKey: eventKey,
    endpoint: "https://api.abto.app/v1/collect/events",
    environment: .production
)
```

Use the SDK's default `UserDefaults` identity store or provide the application's existing `AbtoKeyValueStore`.

## Common event flow

Use the SDK identity and trace headers without capturing an event during Core wiring.
Add the event-producing steps below only after the user selects their exact candidates:

```text
identify user
→ start LLM trace
→ send device_id and trace headers to the backend
→ optionally attach Gateway x-abto-request-id for a selected supported event
→ optionally capture the selected visible response or product outcome
→ flush selected events during a lifecycle-safe background opportunity
```

Use the SDK's `deviceId` as the Gateway `x-abto-device-id`.
Do not generate a separate server device identifier for the same app installation.
Do not create a placeholder product event merely to demonstrate the SDK.
Use `captureOutcome` only for the canonical interaction values exposed by the installed package: `copied`, `inserted`, `accepted`, `rejected`, `shared`, `downloaded`, `expanded`, `collapsed`, `rated_positive`, `rated_negative`, `regenerated`, and `aborted`.
Prefer `AbtoResponseInteraction.ACCEPTED` on Android, `.accepted` on Swift, and `AbtoResponseInteraction.accepted` on Dart when those typed APIs exist in the installed public version.
During the `0.x` compatibility window, legacy string calls remain accepted only when they match the same canonical list; unsupported values are warned and dropped before enqueueing.
When a product action has no exact match, propose a selected custom event instead of passing an arbitrary string.
Use platform lifecycle hooks that already exist in the application.
Do not block the UI thread while flushing.
