import Foundation

private let abtoMetricAbsoluteLimit = 1e38
private let abtoMetricMaxFractionDigits = 12
private let abtoMaxScaleLength = 16
private let abtoEnvelopeContextKeys = [
    "trace_id": "$trace_id",
    "node_id": "$node_key",
    "node_key": "$node_key",
    "task_type": "$task_type",
    "surface": "$surface",
    "request_id": "$request_id",
    "response_id": "$response_id",
]

package func abtoMetricValue(_ value: Double?) -> Double? {
    guard let value, value.isFinite, value.magnitude < abtoMetricAbsoluteLimit else { return nil }
    let parts = String(value.magnitude).lowercased().split(
        separator: "e",
        maxSplits: 1,
        omittingEmptySubsequences: false
    )
    let coefficientParts = parts[0].split(
        separator: ".",
        maxSplits: 1,
        omittingEmptySubsequences: false
    )
    let fractionDigits = coefficientParts.count == 2
        ? coefficientParts[1].reversed().drop(while: { $0 == "0" }).count
        : 0
    let exponent = parts.count == 2 ? Int(parts[1]) ?? 0 : 0
    return max(0, fractionDigits - exponent) <= abtoMetricMaxFractionDigits ? value : nil
}

package func abtoScaleValue(_ value: String?) -> String? {
    guard let value, value.utf16.count <= abtoMaxScaleLength else { return nil }
    return value
}

package func abtoEventNameIssue(_ event: String, allowSystemEvent: Bool = false) -> String? {
    if event.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "must not be blank" }
    if event.contains("\0") { return "must not contain U+0000" }
    if event.hasPrefix("$") { return "must not start with $" }
    if !allowSystemEvent && abtoReservedEventNames.contains(event) {
        return "must not use an ABTO system event name"
    }
    if event.utf16.count > abtoEventNameMaxLength {
        return "must be at most \(abtoEventNameMaxLength) UTF-16 code units"
    }
    return nil
}

package func abtoExtraJSON(
    properties: [String: Any],
    systemProperties: [String: Any],
    envelope: [String: Any],
    context: AbtoContext,
    environment: AbtoEnvironment
) -> [String: Any] {
    var extraJSON = properties.filter { !$0.key.hasPrefix("$") }
    for (key, value) in systemProperties { extraJSON[key] = value }
    extraJSON["$lib"] = "ios"
    extraJSON["$environment"] = environment.rawValue
    extraJSON["$schema_version"] = abtoSchemaVersion
    extraJSON["$device_id"] = context.anonymousId
    extraJSON["$anonymous_id"] = context.anonymousId
    extraJSON["$session_id"] = context.sessionId
    if let userId = context.userId { extraJSON["$user_id"] = userId }
    if let tenantId = context.tenantId { extraJSON["$tenant_id"] = tenantId }
    for (key, item) in envelope {
        guard let contextKey = abtoEnvelopeContextKeys[key] else { continue }
        extraJSON[contextKey] = item
    }
    return extraJSON
}

package func abtoPromptProperties(
    prompt: String?,
    language: String?,
    taskType: String?
) -> [String: Any] {
    var properties: [String: Any] = ["$capture_mode": "metadata_only"]
    if let prompt { properties["$prompt_length_chars"] = prompt.count }
    if let language { properties["$language"] = language }
    return properties
}

package func abtoResponseProperties(
    responseId: String,
    responseText: String?,
    timeToVisibleMs: Int?
) -> [String: Any] {
    var properties: [String: Any] = [
        "$capture_mode": "metadata_only",
        "$response_id": responseId,
    ]
    if let responseText { properties["$output_length_chars"] = responseText.count }
    if let timeToVisibleMs { properties["$time_to_render_ms"] = timeToVisibleMs }
    return properties
}

/// iOS/macOS 용 ABTO SDK 진입점.
/// 브라우저 SDK(packages/browser/javascript)와 동일한 이벤트 계약을 따른다:
/// Analytics 수신 계약(event_id·device_id·event_name·occurred_at·extra_json)으로
/// POST {"batch": […]} 한다.
public final class AbtoClient {
    public let config: AbtoConfig
    private let context: AbtoContext
    private let transport: AbtoTransport

    /// Analytics와 Gateway의 `x-abto-device-id`에 함께 써야 하는 attribution 축.
    public var deviceId: String { context.anonymousId }

    /// 현재 SDK client 생명주기의 session 식별자.
    public var sessionId: String { context.sessionId }

    public init(config: AbtoConfig, store: AbtoKeyValueStore = AbtoUserDefaultsStore()) {
        self.config = config
        self.context = AbtoContext(store: store)
        self.transport = AbtoTransport(config: config)
    }

    public convenience init(
        projectKey: String,
        endpoint: String? = nil,
        environment: AbtoEnvironment = .production,
        debug: Bool? = nil,
        store: AbtoKeyValueStore = AbtoUserDefaultsStore()
    ) throws {
        self.init(
            config: try AbtoConfig(projectKey: projectKey, endpoint: endpoint, environment: environment, debug: debug),
            store: store
        )
    }

    public func identify(userId: String, tenantId: String? = nil) {
        context.identify(userId: userId, tenantId: tenantId)
    }

    public func reset() {
        context.reset()
    }

    /// 수동 biz event 전송 — LLM call 이전 행동 트래킹의 기본 경로.
    @discardableResult
    public func capture(
        _ event: String,
        properties: [String: Any] = [:],
        envelope: [String: Any] = [:],
        value: Double? = nil,
        scale: String? = nil
    ) -> Bool {
        captureEvent(event, properties: properties, envelope: envelope, value: value, scale: scale)
    }

    @discardableResult
    func captureSystemEvent(
        _ event: String,
        systemProperties: [String: Any],
        properties: [String: Any] = [:],
        envelope: [String: Any] = [:]
    ) -> Bool {
        captureEvent(
            event,
            properties: properties,
            systemProperties: systemProperties,
            envelope: envelope,
            allowSystemEvent: true
        )
    }

    private func captureEvent(
        _ event: String,
        properties: [String: Any] = [:],
        systemProperties: [String: Any] = [:],
        envelope: [String: Any] = [:],
        value: Double? = nil,
        scale: String? = nil,
        allowSystemEvent: Bool = false
    ) -> Bool {
        if let issue = abtoEventNameIssue(event, allowSystemEvent: allowSystemEvent) {
            print("[abto] event was dropped: \(issue).")
            return false
        }
        let extraJSON = abtoExtraJSON(
            properties: properties,
            systemProperties: systemProperties,
            envelope: envelope,
            context: context,
            environment: config.environment
        )
        var captured: [String: Any] = [
            "event_id": abtoUUIDv7(),
            "device_id": context.anonymousId,
            "session_id": context.sessionId,
            "event_name": event,
            "occurred_at": abtoTimestamp(),
            "extra_json": extraJSON,
        ]
        if let traceId = envelope["trace_id"] as? String { captured["trace_id"] = traceId }
        if let value = abtoMetricValue(value) { captured["value"] = value }
        if let scale = abtoScaleValue(scale) { captured["scale"] = scale }
        if config.debug {
            print("[abto] \(event) \(captured)")
        }
        transport.enqueue(captured)
        return true
    }

    public func startLlmTrace(nodeId: String, taskType: String? = nil, surface: String? = nil) -> AbtoLlmTrace {
        AbtoLlmTrace(client: self, nodeId: nodeId, taskType: taskType, surface: surface)
    }

    public func flush(completion: (@Sendable () -> Void)? = nil) {
        transport.flush(completion: completion)
    }
}

/// LLM 호출 한 건의 생애주기 — trace_id 로 이전 행동을, request_id 로 게이트웨이 비용/latency 를 조인한다.
public final class AbtoLlmTrace {
    public let traceId: String
    public let nodeId: String
    public private(set) var requestId: String?

    private let client: AbtoClient
    private let taskType: String?
    private let surface: String?

    init(client: AbtoClient, nodeId: String, taskType: String?, surface: String?) {
        self.client = client
        self.nodeId = nodeId
        self.taskType = taskType
        self.surface = surface
        self.traceId = abtoUUIDv7TraceId()
    }

    /// 게이트웨이 응답 헤더에서 x-request-id 를 읽어 이후 이벤트에 붙인다.
    @discardableResult
    public func attachRequestId(fromHeaders headers: [AnyHashable: Any]) -> String? {
        for (key, value) in headers {
            if let name = key as? String, name.lowercased() == "x-request-id", let id = value as? String, !id.isEmpty {
                requestId = id
                return id
            }
        }
        return nil
    }

    public func attach(requestId: String) {
        self.requestId = requestId
    }

    public func submitPrompt(prompt: String? = nil, language: String? = nil) {
        let systemProperties = abtoPromptProperties(
            prompt: prompt,
            language: language,
            taskType: taskType
        )
        client.captureSystemEvent("llm_prompt_submitted", systemProperties: systemProperties, envelope: envelope())
    }

    public func markResponseVisible(responseId: String, responseText: String? = nil, timeToVisibleMs: Int? = nil) {
        let systemProperties = abtoResponseProperties(
            responseId: responseId,
            responseText: responseText,
            timeToVisibleMs: timeToVisibleMs
        )
        client.captureSystemEvent("llm_response_rendered", systemProperties: systemProperties, envelope: envelope(["response_id": responseId]))
    }

    public func captureOutcome(_ interactionType: String, responseId: String? = nil, properties extra: [String: Any] = [:]) {
        var systemProperties: [String: Any] = ["$interaction_type": interactionType]
        if let responseId { systemProperties["$response_id"] = responseId }
        if let requestId { systemProperties["$request_id"] = requestId }
        var overrides: [String: Any] = [:]
        if let responseId { overrides["response_id"] = responseId }
        client.captureSystemEvent(
            "llm_response_interacted",
            systemProperties: systemProperties,
            properties: extra,
            envelope: envelope(overrides)
        )
    }

    private func envelope(_ overrides: [String: Any] = [:]) -> [String: Any] {
        var envelope: [String: Any] = [
            "node_key": nodeId,
            "trace_id": traceId,
        ]
        if let taskType { envelope["task_type"] = taskType }
        if let surface { envelope["surface"] = surface }
        if let requestId { envelope["request_id"] = requestId }
        for (key, value) in overrides { envelope[key] = value }
        return envelope
    }
}
