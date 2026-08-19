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
    implementation("app.abto:abto-app:0.1.4")
}
```

Provide an `AbtoKeyValueStore` backed by the application's existing `SharedPreferences`.

## iOS and macOS

Support iOS 14 or later and macOS 12 or later.
Add the public Swift Package:

```swift
.package(
    url: "https://github.com/greedy-co/abto-sdk.git",
    from: "0.1.2"
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

```text
identify user
→ capture product event
→ start LLM trace
→ send device_id and trace headers to the backend
→ attach Gateway x-abto-request-id
→ capture the visible response and user outcome
→ flush during a lifecycle-safe background opportunity
```

Use the SDK's `deviceId` as the Gateway `x-abto-device-id`.
Do not generate a separate server device identifier for the same app installation.
Use platform lifecycle hooks that already exist in the application.
Do not block the UI thread while flushing.
