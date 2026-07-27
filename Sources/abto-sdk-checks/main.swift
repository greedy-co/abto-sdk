import Foundation
import AbtoApp

// 프레임워크 없는 검증 러너 — 실패 시 exit 1.
// ABTO_E2E=1 이고 dev collector(:4870)가 떠 있으면 실제 전송까지 검증한다.

var failures = 0

func check(_ condition: Bool, _ name: String) {
    if condition {
        print("ok   \(name)")
    } else {
        failures += 1
        print("FAIL \(name)")
    }
}

func isUUIDv7(_ value: String) -> Bool {
    value.range(of: "^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$", options: .regularExpression) != nil
}

// init config validation
do {
    let config = try AbtoConfig(projectKey: "pk_test")
    check(config.endpoint.absoluteString == "https://api.abto.ai/v1/events", "default endpoint derived")
    check(config.environment == .production && config.debug == false, "production defaults")
    check(try AbtoConfig(projectKey: "pk", environment: .development).debug, "development turns debug on")
} catch {
    failures += 1
    print("FAIL valid config threw: \(error)")
}

do {
    _ = try AbtoConfig(projectKey: "  ")
    check(false, "empty projectKey rejected")
} catch {
    check("\(error)" == "[abto] projectKey is required. Check your init config.", "empty projectKey rejected")
}

do {
    _ = try AbtoConfig(projectKey: "pk", endpoint: "htp:/broken url")
    check(false, "malformed endpoint rejected")
} catch {
    check("\(error)".hasPrefix("[abto] endpoint is not a valid http(s) URL:"), "malformed endpoint rejected")
}

// context identity
let store = AbtoInMemoryStore()
let firstContext = AbtoContext(store: store)
let secondContext = AbtoContext(store: store)
check(firstContext.anonymousId == secondContext.anonymousId, "anonymous_id persists across clients")
check(isUUIDv7(firstContext.anonymousId), "anonymous_id uses UUIDv7")
check(isUUIDv7(firstContext.sessionId), "session_id uses UUIDv7")
check(firstContext.sessionId != secondContext.sessionId, "session_id rotates per client")

firstContext.identify(userId: "u_1", tenantId: "t_1")
check(firstContext.commonProperties()["user_id"] as? String == "u_1", "identify sets user_id")
let anonBefore = firstContext.anonymousId
firstContext.reset()
check(firstContext.commonProperties()["user_id"] == nil, "reset clears user_id")
check(firstContext.anonymousId != anonBefore, "reset rotates anonymous_id")

// trace request id join
do {
    let client = try AbtoClient(projectKey: "pk_test", store: AbtoInMemoryStore())
    let trace = client.startLlmTrace(nodeId: "smoke.demo")
    check(trace.traceId.range(of: "^[0-9a-f]{12}7[0-9a-f]{3}[89ab][0-9a-f]{15}$", options: .regularExpression) != nil, "trace_id uses UUIDv7 bits")
    check(trace.attachRequestId(fromHeaders: ["X-Request-Id": "req_1"]) == "req_1", "attachRequestId reads header case-insensitively")
    check(trace.requestId == "req_1", "requestId retained on trace")
}

// collector E2E (opt-in)
if ProcessInfo.processInfo.environment["ABTO_E2E"] == "1" {
    let client = try! AbtoClient(
        projectKey: "pk_smoke_ios",
        endpoint: "http://localhost:4870/v1/events",
        environment: .development,
        store: AbtoInMemoryStore()
    )
    client.identify(userId: "u_smoke_ios")
    let trace = client.startLlmTrace(nodeId: "smoke.ios", taskType: "smoke_test", surface: "sdk_checks")
    trace.submitPrompt(prompt: "iOS 스모크 프롬프트", language: "ko")
    trace.attach(requestId: "req_smoke_ios")
    trace.markResponseVisible(responseId: "resp_smoke_ios", responseText: "iOS 응답", timeToVisibleMs: 42)
    trace.captureOutcome("copied", responseId: "resp_smoke_ios")

    let done = DispatchSemaphore(value: 0)
    client.flush { done.signal() }
    check(done.wait(timeout: .now() + 10) == .success, "e2e flush to local collector completed")
} else {
    print("skip e2e (set ABTO_E2E=1 with dev collector running)")
}

if failures > 0 {
    print("\(failures) check(s) failed")
    exit(1)
}
print("all checks passed")
