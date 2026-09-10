# abto (Flutter/Dart)

ABTO Browser SDK(`packages/browser/javascript`)와 동일한 이벤트 계약을 따르는 Dart SDK.
코어는 순수 Dart(`dart:io`)라 Flutter 의존이 없다 — Flutter 앱에서 그대로 import 해서 쓰고,
검증은 `dart test`로 어디서든 실행할 수 있다. 플랫폼 채널 없이 Dart 패키지 하나로
Flutter가 지원하는 iOS, Android, 데스크톱 및 서버 환경에서 사용할 수 있다.

Analytics 수신 계약(`event_id`·`device_id`·`event_name`·`occurred_at`·`extra_json`)에 맞춰
`POST {endpoint} {"batch": […]}` + `Authorization: Bearer <projectKey>` 로 배치 전송한다.

## 사용

```dart
import 'package:abto/abto.dart';

final abto = AbtoClient(
  AbtoConfig(
    projectKey: 'ek-abto-…',
    endpoint: 'https://api.abto.app/v1/collect/events', // 생략 시 기본값
    environment: AbtoEnvironment.production,
  ),
  store: SharedPreferencesStore(prefs), // Flutter 에선 어댑터 권장, 생략 시 인메모리
);

abto.identify('u_123', 't_1');

// 같은 AI 요청을 ABTO Gateway로 보낼 때 이 값을 x-abto-device-id로 전달
final gatewayDeviceId = abto.deviceId;

// LLM call 이전 event — 수동 capture
abto.capture(
  'checkout_completed',
  value: 49000,
  scale: 'KRW'
);

// LLM 호출 생애주기 — request_id 로 게이트웨이 비용/latency 와 조인
final trace = abto.startLlmTrace(featureId: 'resume.make', taskType: 'draft_generation');
trace.submitPrompt(prompt: '이력서 초안 작성해줘', language: 'ko');
trace.attachRequestIdFromHeaders(response.headers); // x-abto-request-id
trace.markResponseVisible(responseId: 'resp_1', timeToVisibleMs: 1200);
trace.captureOutcome('accepted', responseId: 'resp_1');

await abto.flush();
```

Flutter 영속화 어댑터 예 (shared_preferences):

```dart
class SharedPreferencesStore implements AbtoKeyValueStore {
  SharedPreferencesStore(this._prefs);
  final SharedPreferences _prefs;

  @override
  String? get(String key) => _prefs.getString(key);

  @override
  void set(String key, String value) => _prefs.setString(key, value);
}
```

- `anonymous_id`는 store 에 영속, `session_id`는 클라이언트 생성마다 갱신.
- `abto.deviceId`가 Analytics `device_id`다. Gateway의 `x-abto-device-id`에도 같은 값을 보내야 행동과 LLM 실행이 조인된다.
- `batchSize`는 Analytics 배치 한도와 같은 1~100만 허용한다.
- `event_name`은 Backend와 같은 UTF-16 기준 최대 200자다. 초과·공백·`$` 접두 이름은 enqueue 전에 거절한다.
- metric `value`는 유한한 수이면서 정수부 38자리·소수부 12자리 이하여야 한다. 범위를 벗어나면 해당 커스텀 이벤트를 경고 후 보내지 않는다.
- metric `scale`은 최대 16자이며, 빈 값이나 범위 밖의 값은 해당 커스텀 이벤트를 경고 후 보내지 않는다.
- `$`로 시작하는 property는 ABTO context 전용이라 사용자 입력에 포함되면 해당 커스텀 이벤트를 거절한다. `$lib`·`$environment`·식별자 context는 SDK가 자동으로 넣는다.
- LLM lifecycle helper(`submitPrompt`, `markResponseVisible`)는 기본 `metadata_only`이며 prompt·response 원문을 전송하지 않는다. Custom event property는 호출자가 넣은 값을 전송하므로 민감한 원문을 포함하지 않는다.
- 전송 실패는 앱으로 throw 되지 않고 내부 버퍼(최대 1000건)로 재적재된다.

## 검증

```sh
dart pub get
dart test                    # 단위 검증
ABTO_E2E=1 dart test         # + dev collector(:4870) 실전송 E2E
```

## Custom Event 입력

`event`만 필수이고, `value`·`scale`·`properties`는 모두 선택입니다. 생략한 `value`와 `scale`은 전송에도 포함하지 않습니다. `scale`은 빈 문자열도 허용하며, 생략하면 전송에서도 생략됩니다.
사용자 속성은 SDK 문맥과 함께 `extra_json`으로 전송됩니다.
단순 행동 건수는 `value: 1`, `scale: 'count'`로 기록합니다(Kotlin은 `=` 표기).

`properties` 값은 JSON 스칼라(문자열·유한한 수·불리언·null), 스칼라 배열, 스칼라 값으로 구성된 객체를 받습니다.
더 깊은 중첩, U+0000, 최상위 `$` 접두 키와 `value`·`scale` 키는 해당 커스텀 이벤트와 함께 거절합니다.
이벤트 ID·시각·기기/세션 ID·`$` 문맥은 SDK가 자동으로 추가합니다.

이 capture API는 1.0.0의 위치 인자 API를 대체합니다. 업그레이드 시 호출부를 바꿔야 하며, 기존 저장 이벤트의 해석은 유지됩니다.

추가 데이터 예시:

```dart
abto.capture(
  'checkout_completed',
  value: 49000,
  scale: 'KRW',
  properties: {'tier': 'pro'}
);
```
