# ABTO Swift SDK

ABTO Browser SDK와 동일한 이벤트 계약을 따르는 iOS/macOS용 공개 Swift SDK.
envelope(`event_id`·`timestamp`·`source: "ios"`·`schema_version`·식별자)를 붙여
`POST {endpoint} {"batch": […]}` + `Authorization: Bearer <projectKey>` 로 배치 전송한다.

## 설치

Xcode에서 `File > Add Package Dependencies…`를 열고 다음 URL을 입력한다.

```text
https://github.com/greedy-co/abto-swift
```

`Package.swift`에서는 다음처럼 추가한다.

```swift
.package(url: "https://github.com/greedy-co/abto-swift.git", from: "0.0.1")
```

## 사용

```swift
import AbtoApp

let abto = try AbtoClient(
    projectKey: "pk_live_…",
    endpoint: "https://api.abto.ai/v1/events",  // 생략 시 기본값
    environment: .production
)

abto.identify(userId: "u_123", tenantId: "t_1")

// LLM call 이전 biz event — 수동 capture
abto.capture("checkout_started", properties: ["cart_size": 3])

// LLM 호출 생애주기 — request_id 로 게이트웨이 비용/latency 와 조인
let trace = abto.startLlmTrace(nodeId: "resume.make", taskType: "draft_generation")
trace.submitPrompt(prompt: "이력서 초안 작성해줘", language: "ko")
// 게이트웨이 응답을 받으면:
trace.attachRequestId(fromHeaders: httpResponse.allHeaderFields)  // x-request-id
trace.markResponseVisible(responseId: "resp_1", timeToVisibleMs: 1200)
trace.captureOutcome("accepted", responseId: "resp_1")

abto.flush()
```

- `anonymous_id`는 UserDefaults 에 영속(`AbtoKeyValueStore` 로 교체 가능), `session_id`는 클라이언트 생성마다 갱신.
- 캡처는 기본 full — 브라우저 SDK 와 동일한 2026-07-02 정책.
- 전송 실패는 절대 앱으로 throw 되지 않고 내부 버퍼(최대 1000건)로 재적재된다.

## 검증

XCTest 가 없는 Command Line Tools 환경도 지원하기 위해 검증은 실행 파일로 돈다:

```sh
swift run abto-sdk-checks                # 단위 검증
ABTO_E2E=1 swift run abto-sdk-checks    # + dev collector(:4870) 실전송 E2E
```
