import Foundation

// trace_id rides as a first-class wire field, so it is not copied into the bag.
private let abtoEnvelopeContextKeys = [
    "feature_id": "$feature_id",
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
    guard let value, !value.contains("\0"), value.utf16.count <= abtoScaleMaxLength else { return nil }
    return value
}

// Mirrors the shallow JsonValue contract; Foundation validates JSON-compatible scalars.
package func abtoValidProperties(_ properties: [String: Any]) -> Bool {
    func scalar(_ value: Any) -> Bool {
        if value is NSNull { return true }
        if let text = value as? String { return !text.contains("\0") }
        if let number = value as? NSNumber { return number.doubleValue.isFinite }
        return false
    }
    func value(_ item: Any) -> Bool {
        if scalar(item) { return true }
        if let array = item as? [Any] { return array.allSatisfy(scalar) }
        if let object = item as? [String: Any] {
            return object.allSatisfy { !$0.key.contains("\0") && scalar($0.value) }
        }
        return false
    }
    return properties.allSatisfy { !$0.key.hasPrefix("$") && !$0.key.contains("\0") &&
        !abtoCustomMetricFields.contains($0.key) && value($0.value) }
}

package func abtoEventNameIssue(_ event: String) -> String? {
    if event.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return abtoErrEventNameBlank }
    if event.contains("\0") { return abtoErrEventNameNul }
    if event.hasPrefix("$") { return abtoErrEventNameDollarPrefix }
    if abtoReservedEventNames.contains(event) { return abtoErrEventNameReserved }
    if event.utf16.count > abtoEventNameMaxLength { return abtoErrEventNameTooLong }
    return nil
}

/// Builds the property bag carried in `extra_json`.
///
/// The bag holds only what no first-class wire field carries. device_id, session_id and trace_id
/// ride at the top level, so a copy here would be a duplicate no aggregation reads, stored forever
/// in every event's jsonb. Context with no column of its own stays, because the bag is its only
/// carrier.
package func abtoExtraJSON(
    systemProperties: [String: Any],
    envelope: [String: Any],
    context: AbtoContext,
    environment: AbtoEnvironment,
    properties: [String: Any] = [:]
) -> [String: Any] {
    var extraJSON: [String: Any] = properties
    for (key, value) in systemProperties { extraJSON[key] = value }
    extraJSON["$lib"] = "ios"
    extraJSON["$environment"] = environment.rawValue
    extraJSON["$schema_version"] = abtoSchemaVersion
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

/// ABTO SDK entry point for iOS/macOS.
/// Uses the same event contract as the Browser SDK and posts `{"batch": […]}`
/// to the Analytics ingestion contract: event_id, device_id, event_name, occurred_at, and extra_json.
public final class AbtoClient {
    public let config: AbtoConfig
    private let context: AbtoContext
    private let transport: AbtoTransport

    /// Attribution axis shared by Analytics and the Gateway's `x-abto-device-id`.
    public var deviceId: String { context.anonymousId }

    /// Session identifier for the current SDK client lifecycle.
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

    /// Sends optional value and scale as metric columns and optional properties as extra_json.
    public func capture(
        _ event: String,
        value: Double? = nil,
        scale: String? = nil,
        properties: [String: Any] = [:]
    ) {
        if let issue = abtoEventNameIssue(event) {
            print(abtoErrEventDropped.replacingOccurrences(of: "{issue}", with: issue))
            return
        }
        guard (value == nil || abtoMetricValue(value) != nil), (scale == nil || abtoScaleValue(scale) != nil), abtoValidProperties(properties) else {
            print(abtoErrCustomCaptureInvalid)
            return
        }
        captureEvent(event, properties: properties, value: value, scale: scale)
    }

    func captureSystemEvent(
        _ event: String,
        systemProperties: [String: Any],
        envelope: [String: Any] = [:]
    ) {
        captureEvent(event, systemProperties: systemProperties, envelope: envelope)
    }

    /// Builds and enqueues one event. Names are checked by the public `capture`; the SDK's own
    /// system event names are constants and need no check.
    private func captureEvent(
        _ event: String,
        properties: [String: Any] = [:],
        systemProperties: [String: Any] = [:],
        envelope: [String: Any] = [:],
        value: Double? = nil,
        scale: String? = nil
    ) {
        let extraJSON = abtoExtraJSON(
            systemProperties: systemProperties,
            envelope: envelope,
            context: context,
            environment: config.environment,
            properties: properties
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
        if let value { captured["value"] = value }
        if let scale { captured["scale"] = scale }
        if config.debug {
            print("[abto] \(event) \(captured)")
        }
        transport.enqueue(captured)
    }

    public func startLlmTrace(featureId: String, taskType: String? = nil, surface: String? = nil) -> AbtoLlmTrace {
        AbtoLlmTrace(client: self, featureId: featureId, taskType: taskType, surface: surface)
    }

    public func flush(completion: (@Sendable () -> Void)? = nil) {
        transport.flush(completion: completion)
    }
}

/// Lifecycle of one LLM call, joining prior behavior by trace_id and Gateway cost and latency by request_id.
public final class AbtoLlmTrace {
    public let traceId: String
    public let featureId: String
    public private(set) var requestId: String?

    private let client: AbtoClient
    private let taskType: String?
    private let surface: String?

    init(client: AbtoClient, featureId: String, taskType: String?, surface: String?) {
        self.client = client
        self.featureId = featureId
        self.taskType = taskType
        self.surface = surface
        self.traceId = abtoUUIDv7TraceId()
    }

    /// Reads x-abto-request-id from Gateway response headers and attaches it to later events.
    @discardableResult
    public func attachRequestId(fromHeaders headers: [AnyHashable: Any]) -> String? {
        for (key, value) in headers {
            if let name = key as? String, name.lowercased() == "x-abto-request-id", let id = value as? String, !id.isEmpty {
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

    public func captureOutcome(
        _ interactionType: AbtoResponseInteraction,
        responseId: String? = nil
    ) {
        captureCanonicalOutcome(interactionType.rawValue, responseId: responseId)
    }

    private func captureCanonicalOutcome(
        _ interactionType: String,
        responseId: String?
    ) {
        var systemProperties: [String: Any] = ["$interaction_type": interactionType]
        if let responseId { systemProperties["$response_id"] = responseId }
        if let requestId { systemProperties["$request_id"] = requestId }
        var overrides: [String: Any] = [:]
        if let responseId { overrides["response_id"] = responseId }
        client.captureSystemEvent(
            "llm_response_interacted",
            systemProperties: systemProperties,
            envelope: envelope(overrides)
        )
    }

    private func envelope(_ overrides: [String: Any] = [:]) -> [String: Any] {
        var envelope: [String: Any] = [
            "feature_id": featureId,
            "trace_id": traceId,
        ]
        if let taskType { envelope["task_type"] = taskType }
        if let surface { envelope["surface"] = surface }
        if let requestId { envelope["request_id"] = requestId }
        for (key, value) in overrides { envelope[key] = value }
        return envelope
    }
}
