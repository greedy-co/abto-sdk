import Foundation

/// iOS/macOS 용 ABTO SDK 진입점.
/// 브라우저 SDK(packages/sdk)와 동일한 이벤트 계약을 따른다:
/// envelope(event_id·timestamp·source·schema_version·식별자) + POST {"batch": […]}.
public final class AbtoClient {
    public let config: AbtoConfig
    private let context: AbtoContext
    private let transport: AbtoTransport

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
    public func capture(_ event: String, properties: [String: Any] = [:], envelope: [String: Any] = [:]) {
        var captured: [String: Any] = [
            "event_id": abtoUUIDv7(),
            "event": event,
            "timestamp": abtoTimestamp(),
            "source": "ios",
            "environment": config.environment.rawValue,
            "schema_version": abtoSchemaVersion,
            "properties": properties,
        ]
        for (key, value) in context.commonProperties() { captured[key] = value }
        for (key, value) in envelope { captured[key] = value }
        if config.debug {
            print("[abto] \(event) \(captured)")
        }
        transport.enqueue(captured)
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
        var properties: [String: Any] = ["prompt_capture_mode": "full"]
        if let prompt {
            properties["prompt_text"] = prompt
            properties["prompt_length_chars"] = prompt.count
        }
        if let language { properties["language"] = language }
        if let taskType { properties["task_type"] = taskType }
        client.capture("llm_prompt_submitted", properties: properties, envelope: envelope())
    }

    public func markResponseVisible(responseId: String, responseText: String? = nil, timeToVisibleMs: Int? = nil) {
        var properties: [String: Any] = [
            "response_capture_mode": "full",
            "response_id": responseId,
        ]
        if let responseText { properties["response_text"] = responseText }
        if let timeToVisibleMs { properties["time_to_visible_ms"] = timeToVisibleMs }
        client.capture("llm_response_visible", properties: properties, envelope: envelope(["response_id": responseId]))
    }

    public func captureOutcome(_ interactionType: String, responseId: String? = nil, properties extra: [String: Any] = [:]) {
        var properties: [String: Any] = ["interaction_type": interactionType]
        if let responseId { properties["response_id"] = responseId }
        if let requestId { properties["request_id"] = requestId }
        for (key, value) in extra { properties[key] = value }
        var overrides: [String: Any] = [:]
        if let responseId { overrides["response_id"] = responseId }
        client.capture("llm_response_\(interactionType)", properties: properties, envelope: envelope(overrides))
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
