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
abto.capture('checkout_started', properties: {'cart_size': 3});

// LLM 호출 생애주기 — request_id 로 게이트웨이 비용/latency 와 조인
final trace = abto.startLlmTrace(featureId: 'resume.make', taskType: 'draft_generation');
trace.submitPrompt(prompt: '이력서 초안 작성해줘', language: 'ko');
trace.attachRequestIdFromHeaders(response.headers); // x-abto-request-id
trace.markResponseVisible(responseId: 'resp_1', timeToVisibleMs: 1200);
trace.captureOutcome(AbtoResponseInteraction.accepted, responseId: 'resp_1');

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
- metric `value`는 유한한 수이면서 정수부 38자리·소수부 12자리 이하여야 한다. 범위를 벗어나면 이벤트는 보내되 top-level metric만 제외한다.
- metric `scale`은 최대 16자이며, 범위를 벗어나면 이벤트는 보내되 top-level metadata만 제외한다.
- `$`로 시작하는 property는 ABTO context 전용이라 사용자 입력에서 제외하며, `$lib`·`$environment`·식별자 context는 SDK가 덮어쓴다.
- 캡처는 기본 full — 브라우저 SDK 와 동일한 2026-07-02 정책.
- 전송 실패는 앱으로 throw 되지 않고 내부 버퍼(최대 1000건)로 재적재된다.

## 검증

```sh
dart pub get
dart test                    # 단위 검증
ABTO_E2E=1 dart test         # + dev collector(:4870) 실전송 E2E
```
