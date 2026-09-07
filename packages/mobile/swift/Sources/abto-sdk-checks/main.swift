import Foundation
import AbtoApp

// Framework-free verification runner that exits with status 1 on failure.
// Also verifies actual delivery when ABTO_E2E=1 and the development collector is running on port 4870.

nonisolated(unsafe) var failures = 0
nonisolated(unsafe) var covered = Set<String>()

func check(_ condition: Bool, _ name: String) {
    if condition {
        print("ok   \(name)")
    } else {
        failures += 1
        print("FAIL \(name)")
    }
}

/// 이 검증이 증명하는 공통 시나리오를 기록한다. 목록의 정본은 계약이다.
func covers(_ scenario: String) {
    if !abtoConformanceScenarios.contains(scenario) {
        failures += 1
        print("FAIL unknown conformance scenario: \(scenario)")
        return
    }
    covered.insert(scenario)
}

func checkConformanceCoverage() {
    let missing = abtoConformanceScenarios.filter {
        !covered.contains($0) && !abtoConformanceExemptions.contains($0)
    }
    for exempt in abtoConformanceExemptions {
        print("exempt \(exempt) — declared in contracts/client-sdk/conformance.schema.json")
    }
    if missing.isEmpty {
        print("ok   client conformance scenarios all covered")
    } else {
        failures += 1
        print("FAIL client conformance scenarios not covered: \(missing.joined(separator: ", "))")
    }
}

func isUUIDv7(_ value: String) -> Bool {
    value.range(of: "^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$", options: .regularExpression) != nil
}

check(
    AbtoResponseInteraction(rawValue: "copied") == .copied,
    "canonical response interaction is accepted at runtime"
)
check(
    AbtoResponseInteraction(rawValue: "retried") == nil,
    "unknown response interaction is rejected at runtime"
)

// init config validation
do {
    let config = try AbtoConfig(projectKey: "ek_test")
    check(config.endpoint.absoluteString == "https://api.abto.app/v1/collect/events", "default endpoint derived")
    check(config.environment == .production && config.debug == false, "production defaults")
    check(try AbtoConfig(projectKey: "ek", environment: .development).debug, "development turns debug on")
} catch {
    failures += 1
    print("FAIL valid config threw: \(error)")
}

do {
    covers("config.project_key_required")
    _ = try AbtoConfig(projectKey: "  ")
    check(false, "empty projectKey rejected")
} catch {
    check("\(error)" == abtoErrProjectKeyRequired, "empty projectKey rejected")
}

do {
    covers("config.endpoint_must_be_url")
    _ = try AbtoConfig(projectKey: "ek", endpoint: "htp:/broken url")
    check(false, "malformed endpoint rejected")
} catch {
    check("\(error)".hasPrefix(abtoErrEndpointInvalidPrefix), "malformed endpoint rejected")
}

do {
    covers("config.endpoint_requires_https")
    _ = try AbtoConfig(projectKey: "ek", endpoint: "http://collector.example/v1/collect/events")
    check(false, "production cleartext endpoint rejected")
} catch {
    check("\(error)" == abtoErrEndpointHTTPSRequired, "production cleartext endpoint rejected")
}

do {
    let config = try AbtoConfig(
        projectKey: "ek",
        endpoint: "http://127.0.0.1:4870/v1/collect/events",
        environment: .development
    )
    check(config.endpoint.scheme == "http", "development loopback endpoint accepted")
} catch {
    check(false, "development loopback endpoint accepted")
}

for invalidBatchSize in [0, 101] {
    do {
        covers("config.batch_size_range")
        _ = try AbtoConfig(projectKey: "ek", batchSize: invalidBatchSize)
        check(false, "batchSize \(invalidBatchSize) rejected")
    } catch {
        check("\(error)" == abtoErrBatchSizeRange, "batchSize \(invalidBatchSize) rejected")
    }
}

// context identity
let store = AbtoInMemoryStore()
let firstContext = AbtoContext(store: store)
let secondContext = AbtoContext(store: store)
covers("identity.anonymous_persists")
check(firstContext.anonymousId == secondContext.anonymousId, "anonymous_id persists across clients")
covers("identity.uuidv7")
check(isUUIDv7(firstContext.anonymousId), "anonymous_id uses UUIDv7")
check(isUUIDv7(firstContext.sessionId), "session_id uses UUIDv7")
covers("identity.session_rotates")
check(firstContext.sessionId != secondContext.sessionId, "session_id rotates per client")

firstContext.identify(userId: "u_1", tenantId: "t_1")
covers("identity.identify_and_reset")
check(firstContext.commonProperties()["user_id"] as? String == "u_1", "identify sets user_id")
firstContext.identify(userId: "u_2")
check(firstContext.commonProperties()["tenant_id"] == nil, "identify clears an omitted tenant_id")
let anonBefore = firstContext.anonymousId
firstContext.reset()
check(firstContext.commonProperties()["user_id"] == nil, "reset clears user_id")
check(firstContext.anonymousId != anonBefore, "reset rotates anonymous_id")

do {
    let client = try AbtoClient(projectKey: "ek_identity", store: AbtoInMemoryStore())
    let deviceBeforeReset = client.deviceId
    check(isUUIDv7(deviceBeforeReset), "client exposes Gateway attribution deviceId")
    check(isUUIDv7(client.sessionId), "client exposes sessionId")
    client.reset()
    check(client.deviceId != deviceBeforeReset, "client deviceId follows reset")
} catch {
    check(false, "client identity properties available")
}

check(abtoMetricValue(.nan) == nil, "NaN metric omitted")
covers("event.metric_non_finite_omitted")
check(abtoMetricValue(.infinity) == nil, "infinite metric omitted")
covers("event.metric_precision_enforced")
check(abtoMetricValue(1.0 / 3.0) == nil, "over-precision metric omitted")
check(abtoMetricValue(1e38) == nil, "over-range metric omitted")
check(abtoMetricValue(123.123456789012) == 123.123456789012, "bounded metric retained")
check(abtoScaleValue("KRW") == "KRW", "bounded metric scale retained")
covers("event.metric_scale_limit")
check(abtoScaleValue(String(repeating: "x", count: 17)) == nil, "oversized metric scale omitted")
check(abtoScaleValue(String(repeating: "🙂", count: 9)) == nil, "metric scale uses backend UTF-16 limit")

let eventNameClient = try! AbtoClient(projectKey: "ek_event_name", store: AbtoInMemoryStore())
covers("event.reserved_name_rejected")
check(!eventNameClient.capture("pageview"), "reserved system event name rejected by public capture")
covers("event.name_length_limit")
check(!eventNameClient.capture(String(repeating: "x", count: 201)), "overlong event name rejected before enqueue")
check(!eventNameClient.capture(String(repeating: "🙂", count: 101)), "event name limit uses backend UTF-16 units")

let protectedContext = AbtoContext(store: AbtoInMemoryStore())
protectedContext.identify(userId: "real-user", tenantId: "real-tenant")
let protectedExtraJSON = abtoExtraJSON(
    properties: [
        "environment": "customer-environment",
        "user_id": "customer-user",
        "$environment": "spoofed",
        "$user_id": "spoofed",
    ],
    systemProperties: [
        "$capture_mode": "full",
        "$response_id": "resp_1",
    ],
    envelope: ["feature_id": "feature.real"],
    context: protectedContext,
    environment: .production
)
check(protectedExtraJSON["environment"] as? String == "customer-environment", "customer environment retained")
check(protectedExtraJSON["user_id"] as? String == "customer-user", "customer user_id retained")
check(protectedExtraJSON["$environment"] as? String == "production", "SDK environment is namespaced")
check(protectedExtraJSON["$user_id"] as? String == "real-user", "SDK user context cannot be overwritten")
check(protectedExtraJSON["$feature_id"] as? String == "feature.real", "SDK envelope is namespaced")
check(protectedExtraJSON["$capture_mode"] as? String == "full", "LLM helper system properties retain their canonical keys")
check(protectedExtraJSON["$response_id"] as? String == "resp_1", "LLM helper system properties retain response ids")
check(!protectedExtraJSON.values.contains { ($0 as? String) == "spoofed" }, "customer reserved properties rejected")

let promptProperties = abtoPromptProperties(
    prompt: "prompt-canary",
    language: "ko",
    taskType: "answer"
)
check(promptProperties["$capture_mode"] as? String == "metadata_only", "prompt defaults to metadata-only")
check(promptProperties["$prompt_length_chars"] as? Int == 13, "prompt length metadata is retained")
covers("privacy.prompt_and_response_text_not_sent")
check(promptProperties["$prompt_text"] == nil, "prompt text is not transmitted")
let responseProperties = abtoResponseProperties(
    responseId: "response-1",
    responseText: "response-canary",
    timeToVisibleMs: 42
)
check(responseProperties["$capture_mode"] as? String == "metadata_only", "response defaults to metadata-only")
check(responseProperties["$output_length_chars"] as? Int == 15, "response length metadata is retained")
check(responseProperties["$response_text"] == nil, "response text is not transmitted")

// trace request id join
do {
    let client = try AbtoClient(projectKey: "ek_test", store: AbtoInMemoryStore())
    let trace = client.startLlmTrace(featureId: "smoke.demo")
    check(trace.featureId == "smoke.demo", "featureId retained on trace")
    check(trace.traceId.range(of: "^[0-9a-f]{12}7[0-9a-f]{3}[89ab][0-9a-f]{15}$", options: .regularExpression) != nil, "trace_id uses UUIDv7 bits")
    covers("transport.request_id_header_case_insensitive")
    check(trace.attachRequestId(fromHeaders: ["X-Abto-Request-Id": "req_1"]) == "req_1", "attachRequestId reads header case-insensitively")
    check(trace.requestId == "req_1", "requestId retained on trace")
}

// buffer cap: 상한을 넘기면 가장 오래된 것부터 버린다.
covers("transport.buffer_cap")
let burstOverflow = 10
let cappedBurst = abtoCapBuffer(Array(0..<(abtoMaxBufferedEvents + burstOverflow)))
check(cappedBurst.count == abtoMaxBufferedEvents, "burst retains at most the buffered event cap")
check(cappedBurst.first == burstOverflow, "burst drops the oldest events first")
check(abtoCapBuffer([1, 2, 3]) == [1, 2, 3], "under the cap the buffer is untouched")

// collector per-event retry
let retryResponse = """
{"results":{
  "retry-event":{"result":"retry","code":"storage_unavailable"},
  "ok-event":{"result":"ok"}
}}
""".data(using: .utf8)!
let retryIDs = abtoRetryEventIDs(
    responseData: retryResponse,
    eventIDs: ["retry-event", "ok-event", "missing-event"]
)
covers("transport.retry_marked_events_only")
check(retryIDs == Set(["retry-event", "missing-event"]), "202 response retains only retry or omitted events")
check(
    abtoRetryEventIDs(responseData: Data("not-json".utf8), eventIDs: ["retry-event"]) == nil,
    "malformed response retries the full batch"
)
let retryStartedAt = Date(timeIntervalSince1970: 1_000)
check(
    abtoRetryEligible(
        attempts: abtoMaxAttempts - 1,
        firstQueuedAt: retryStartedAt,
        now: retryStartedAt.addingTimeInterval(10)
    ),
    "retry remains eligible within attempt and age budgets"
)
check(
    !abtoRetryEligible(
        attempts: abtoMaxAttempts,
        firstQueuedAt: retryStartedAt,
        now: retryStartedAt.addingTimeInterval(10)
    ),
    "retry stops at the attempt budget"
)
covers("transport.attempt_budget_stops_retry")
check(
    !abtoRetryEligible(
        attempts: 1,
        firstQueuedAt: retryStartedAt,
        now: retryStartedAt.addingTimeInterval(abtoMaxEventAge + 1)
    ),
    "retry stops at the age budget"
)

// collector E2E (opt-in)
if ProcessInfo.processInfo.environment["ABTO_E2E"] == "1" {
    let client = try! AbtoClient(
        projectKey: "ek_smoke_ios",
        endpoint: "http://localhost:4870/v1/collect/events",
        environment: .development,
        store: AbtoInMemoryStore()
    )
    client.identify(userId: "u_smoke_ios")
    let trace = client.startLlmTrace(featureId: "smoke.ios", taskType: "smoke_test", surface: "sdk_checks")
    trace.submitPrompt(prompt: "iOS 스모크 프롬프트", language: "ko")
    trace.attach(requestId: "req_smoke_ios")
    trace.markResponseVisible(responseId: "resp_smoke_ios", responseText: "iOS 응답", timeToVisibleMs: 42)
    trace.captureOutcome(.copied, responseId: "resp_smoke_ios")

    let done = DispatchSemaphore(value: 0)
    client.flush { done.signal() }
    check(done.wait(timeout: .now() + 10) == .success, "e2e flush to local collector completed")
} else {
    print("skip e2e (set ABTO_E2E=1 with dev collector running)")
}

checkConformanceCoverage()

if failures > 0 {
    print("\(failures) check(s) failed")
    exit(1)
}
print("all checks passed")
