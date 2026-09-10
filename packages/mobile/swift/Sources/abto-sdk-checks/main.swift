import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import AbtoApp

final class CaptureURLProtocol: URLProtocol, @unchecked Sendable {
    static let lock = NSLock()
    nonisolated(unsafe) static var events: [[String: Any]] = []
    override class func canInit(with request: URLRequest) -> Bool { request.url?.host == "capture.test" }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        var data = request.httpBody ?? Data()
        if let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var bytes = [UInt8](repeating: 0, count: 4096)
            while stream.hasBytesAvailable {
                let count = stream.read(&bytes, maxLength: bytes.count)
                if count <= 0 { break }
                data.append(contentsOf: bytes.prefix(count))
            }
        }
        let body = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        let batch = body["batch"] as! [[String: Any]]
        Self.lock.lock()
        Self.events.append(contentsOf: batch)
        Self.lock.unlock()
        let results = Dictionary(uniqueKeysWithValues: batch.map { ($0["event_id"] as! String, ["result": "ok"]) })
        let response = HTTPURLResponse(url: request.url!, statusCode: 202, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: try! JSONSerialization.data(withJSONObject: ["results": results]))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
URLProtocol.registerClass(CaptureURLProtocol.self)

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
covers("event.metric_non_finite_rejected")
check(abtoMetricValue(.infinity) == nil, "infinite metric omitted")
covers("event.metric_precision_enforced")
check(abtoMetricValue(1.0 / 3.0) == nil, "over-precision metric omitted")
check(abtoMetricValue(1e38) == nil, "over-range metric omitted")
check(abtoMetricValue(123.123456789012) == 123.123456789012, "bounded metric retained")
check(abtoScaleValue("KRW") == "KRW", "bounded metric scale retained")
covers("event.metric_scale_limit")
check(abtoScaleValue(String(repeating: "x", count: 17)) == nil, "oversized metric scale omitted")
check(abtoScaleValue(String(repeating: "🙂", count: 9)) == nil, "metric scale uses backend UTF-16 limit")

covers("event.reserved_name_rejected")
check(abtoEventNameIssue("pageview") != nil, "reserved system event name rejected by public capture")
covers("event.name_length_limit")
check(abtoEventNameIssue(String(repeating: "x", count: 201)) != nil, "overlong event name rejected before enqueue")
check(abtoEventNameIssue(String(repeating: "🙂", count: 101)) != nil, "event name limit uses backend UTF-16 units")

let protectedContext = AbtoContext(store: AbtoInMemoryStore())
protectedContext.identify(userId: "real-user", tenantId: "real-tenant")
let contextExtraJSON = abtoExtraJSON(
    systemProperties: [
        "$capture_mode": "full",
        "$response_id": "resp_1",
    ],
    envelope: ["feature_id": "feature.real"],
    context: protectedContext,
    environment: .production
)
check(contextExtraJSON["$environment"] as? String == "production", "SDK environment is namespaced")
check(contextExtraJSON["$user_id"] as? String == "real-user", "SDK user context is carried by the bag")
check(contextExtraJSON["$feature_id"] as? String == "feature.real", "SDK envelope is namespaced")
check(contextExtraJSON["$capture_mode"] as? String == "full", "LLM helper system properties retain their canonical keys")
check(contextExtraJSON["$response_id"] as? String == "resp_1", "LLM helper system properties retain response ids")
// Fields promoted to the wire top level leave no copy in the bag.
check(contextExtraJSON["$device_id"] == nil, "device id is not copied into extra_json")
check(contextExtraJSON["$anonymous_id"] == nil, "anonymous id is not copied into extra_json")
check(contextExtraJSON["$session_id"] == nil, "session id is not copied into extra_json")
check(contextExtraJSON["$trace_id"] == nil, "trace id is not copied into extra_json")

covers("event.properties_in_extra_json")
// Customer properties and SDK context share extra_json, while metric columns stay separate.
let customEventExtraJSON = abtoExtraJSON(
    systemProperties: [:], envelope: [:], context: protectedContext, environment: .production,
    properties: ["tier": "pro", "nullable": NSNull(), "tags": ["a"], "detail": ["enabled": true]]
)
check(customEventExtraJSON["tier"] as? String == "pro", "custom properties enter extra_json")
check(customEventExtraJSON["nullable"] is NSNull, "null custom property retained")
check(customEventExtraJSON["properties"] == nil, "no properties wrapper in extra_json")
check(abtoValidProperties(["tier": "pro", "nullable": NSNull(), "tags": ["a"], "detail": ["enabled": true]]), "shallow JSON property values accepted")
for properties: [String: Any] in [["$user_id": "spoof"], ["value": 3], ["scale": "x"], ["deep": ["nested": [:]]], ["bad": Double.nan], ["bad": Date()], ["bad": "\0"]] {
    check(!abtoValidProperties(properties), "invalid or reserved property rejected")
}

covers("event.promoted_fields_not_in_extra_json")
for promoted in ["value", "scale", "$device_id", "$anonymous_id", "$session_id", "$trace_id"] {
    check(customEventExtraJSON[promoted] == nil, "\(promoted) is not copied into extra_json")
}

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

// The public capture method must produce the agreed collector payload.
do {
    let client = try AbtoClient(projectKey: "ek_test", endpoint: "https://capture.test/v1/collect/events", store: AbtoInMemoryStore())
    client.capture("invalid_metric", value: .nan, scale: "count")
    client.capture("invalid_precision", value: 1.0 / 3.0, scale: "count")
    client.capture("invalid_scale", value: 1, scale: String(repeating: "x", count: 17))
    client.capture("invalid_properties", value: 1, scale: "count", properties: ["$user_id": "spoof"])
    client.capture("checkout_completed", value: 49000, scale: "KRW", properties: ["tier": "pro", "nullable": NSNull()])
    covers("event.optional_scale_preserved")
    client.capture("scale_omitted", value: 0)
    client.capture("scale_empty", value: 0, scale: "")
    covers("event.optional_metrics_preserved")
    client.capture("name_only")
    client.capture("properties_only", properties: ["tier": "pro"])
    client.capture("scale_only", scale: "KRW")
    client.capture("scale_only_empty", scale: "")
    let done = DispatchSemaphore(value: 0)
    client.flush { done.signal() }
    check(done.wait(timeout: .now() + 5) == .success, "custom capture flush completes")
    CaptureURLProtocol.lock.lock()
    let events = CaptureURLProtocol.events
    CaptureURLProtocol.lock.unlock()
    check(events.count == 7, "only valid custom captures reach transport")
    for name in ["name_only", "properties_only", "scale_only", "scale_only_empty"] {
        let event = events.first { $0["event_name"] as? String == name }!
        check(event["value"] == nil, "omitted value stays absent")
        if name == "scale_only" { check(event["scale"] as? String == "KRW", "scale without value is preserved") }
        else if name == "scale_only_empty" { check(event["scale"] as? String == "", "empty scale without value is preserved") }
        else { check(event["scale"] == nil, "omitted scale stays absent") }
        let extra = event["extra_json"] as! [String: Any]
        check(extra["value"] == nil && extra["scale"] == nil, "metrics are not copied into extra_json")
        if name == "properties_only" { check(extra["tier"] as? String == "pro", "properties without metrics are preserved") }
    }
    check(events.first { $0["event_name"] as? String == "scale_omitted" }?["scale"] == nil, "omitted scale stays absent")
    check(events.first { $0["event_name"] as? String == "scale_empty" }?["scale"] as? String == "", "empty scale is preserved")
    if let event = events.first {
        check(event["event_name"] as? String == "checkout_completed", "capture sends event_name")
        check(event["value"] as? Double == 49000, "capture sends supplied value")
        check(event["scale"] as? String == "KRW", "capture sends supplied scale")
        let extra = event["extra_json"] as! [String: Any]
        check(extra["tier"] as? String == "pro", "capture sends user properties in extra_json")
        check(extra["nullable"] is NSNull, "capture preserves JSON null")
        check(extra["value"] == nil && extra["scale"] == nil && extra["properties"] == nil, "capture has no metric or properties wrapper in extra_json")
    }
}
URLProtocol.unregisterClass(CaptureURLProtocol.self)

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
        projectKey: ProcessInfo.processInfo.environment["ABTO_E2E_KEY"] ?? "ek_smoke_ios",
        endpoint: ProcessInfo.processInfo.environment["ABTO_E2E_ENDPOINT"] ?? "http://localhost:4870/v1/collect/events",
        environment: .development,
        store: AbtoInMemoryStore()
    )
    client.capture("sdk_e2e_ios_currency", value: 49000, scale: "KRW", properties: ["tier": "pro"])
    client.capture("sdk_e2e_ios_omitted", value: 0)
    client.capture("sdk_e2e_ios_empty", value: 0, scale: "")
    client.capture("sdk_e2e_ios_name_only")
    client.capture("sdk_e2e_ios_properties_only", properties: ["tier": "pro"])
    client.capture("sdk_e2e_ios_scale_only", scale: "KRW")
    client.capture("sdk_e2e_ios_scale_only_empty", scale: "")
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
