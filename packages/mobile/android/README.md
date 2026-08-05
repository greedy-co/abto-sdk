# abto-sdk-android

ABTO Browser SDK(`packages/browser/javascript`)와 동일한 이벤트 계약을 따르는 Kotlin SDK.
코어는 `android.*` 의존이 없는 순수 Kotlin/JVM 이라 JVM 어디서든 돌고,
Android 앱에서는 `AbtoKeyValueStore` 에 SharedPreferences 어댑터만 끼우면 된다.

Analytics 수신 계약(`event_id`·`device_id`·`event_name`·`occurred_at`·`extra_json`)에 맞춰
`POST {endpoint} {"batch": […]}` + `Authorization: Bearer <projectKey>` 로 배치 전송한다.
네트워크는 전용 데몬 스레드에서 돌아 메인 스레드 제약(NetworkOnMainThreadException)이 없다.

## 사용

```kotlin
import app.abto.sdk.*

val abto = AbtoClient(
    AbtoConfig(
        projectKey = "ek-abto-…",
        endpoint = "https://api.abto.app/v1/collect/events",  // 생략 시 기본값
        environment = AbtoEnvironment.PRODUCTION,
    ),
    store = SharedPreferencesStore(context.getSharedPreferences("abto", MODE_PRIVATE)),
)

abto.identify("u_123", "t_1")

// 같은 AI 요청을 ABTO Gateway로 보낼 때 이 값을 x-abto-device-id로 전달
val gatewayDeviceId = abto.deviceId

// LLM call 이전 event — 수동 capture
abto.capture("checkout_started", mapOf("cart_size" to 3))

// LLM 호출 생애주기 — request_id 로 게이트웨이 비용/latency 와 조인
val trace = abto.startLlmTrace(nodeId = "resume.make", taskType = "draft_generation")
trace.submitPrompt(prompt = "이력서 초안 작성해줘", language = "ko")
trace.attachRequestId(connection.headerFields)  // x-abto-request-id
trace.markResponseVisible(responseId = "resp_1", timeToVisibleMs = 1200)
trace.captureOutcome("accepted", responseId = "resp_1")

abto.flush()
```

Android 영속화 어댑터 예:

```kotlin
class SharedPreferencesStore(private val prefs: SharedPreferences) : AbtoKeyValueStore {
    override fun get(key: String): String? = prefs.getString(key, null)
    override fun set(key: String, value: String) = prefs.edit().putString(key, value).apply()
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
- 전송 실패는 앱으로 던지지 않고 내부 버퍼(최대 1000건)로 재적재된다.

## 설치

```kotlin
dependencies {
    implementation("app.abto:abto-app:0.1.2")
}
```

## 검증

Gradle 검증 러너를 사용한다:

```sh
gradle check                         # 단위 검증 + 패키징
ABTO_E2E=1 gradle sdkChecks          # + dev collector(:4870) 실전송 E2E
```
