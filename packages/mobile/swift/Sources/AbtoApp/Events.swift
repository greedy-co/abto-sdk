// GENERATED FILE — DO NOT EDIT.

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let events = try Events(json)

import Foundation

// MARK: - Events
struct Events: Codable {
    let aiPromptSubmittedProps: AIPromptSubmittedProps?
    let aiResponseInteractedProps: AIResponseInteractedProps?
    let aiResponseRenderedProps: AIResponseRenderedProps?
    let autocaptureProps: AutocaptureProps?
    let browserAIPromptSubmittedEvent: BrowserAIPromptSubmittedEvent?
    let browserAIResponseInteractedEvent: BrowserAIResponseInteractedEvent?
    let browserAIResponseRenderedEvent: BrowserAIResponseRenderedEvent?
    let browserAutocaptureEvent: BrowserAutocaptureEvent?
    let browserContextProperties: BrowserContextProperties?
    let browserDeadClickEvent: BrowserDeadClickEvent?
    let browserEventBatchRequest: BrowserEventBatchRequest?
    let browserEventBatchResponse: BrowserEventBatchResponse?
    let browserEventResult: BrowserEventResult?
    let browserEventResultCode: BrowserEventResultCode?
    let browserEventResultStatus: BrowserEventResultStatus?
    let browserIngestEvent: BrowserIngestEvent?
    let browserPageleaveEvent: BrowserPageleaveEvent?
    let browserPageviewEvent: BrowserPageviewEvent?
    let browserRageclickEvent: BrowserRageclickEvent?
    let customEvent: CustomEvent?
    let deadClickProps: DeadClickProps?
    let derivedTextMeta: DerivedTextMeta?
    let maskMode: MaskMode?
    let metricValue: Double?
    let pageleaveProps: PageleaveProps?
    let pageviewProps: PageviewProps?
    let rageclickProps: RageclickProps?
    let scrollDepthProps: ScrollDepthProps?
    let tokenBucket: TokenBucket?

    enum CodingKeys: String, CodingKey {
        case aiPromptSubmittedProps = "AiPromptSubmittedProps"
        case aiResponseInteractedProps = "AiResponseInteractedProps"
        case aiResponseRenderedProps = "AiResponseRenderedProps"
        case autocaptureProps = "AutocaptureProps"
        case browserAIPromptSubmittedEvent = "BrowserAiPromptSubmittedEvent"
        case browserAIResponseInteractedEvent = "BrowserAiResponseInteractedEvent"
        case browserAIResponseRenderedEvent = "BrowserAiResponseRenderedEvent"
        case browserAutocaptureEvent = "BrowserAutocaptureEvent"
        case browserContextProperties = "BrowserContextProperties"
        case browserDeadClickEvent = "BrowserDeadClickEvent"
        case browserEventBatchRequest = "BrowserEventBatchRequest"
        case browserEventBatchResponse = "BrowserEventBatchResponse"
        case browserEventResult = "BrowserEventResult"
        case browserEventResultCode = "BrowserEventResultCode"
        case browserEventResultStatus = "BrowserEventResultStatus"
        case browserIngestEvent = "BrowserIngestEvent"
        case browserPageleaveEvent = "BrowserPageleaveEvent"
        case browserPageviewEvent = "BrowserPageviewEvent"
        case browserRageclickEvent = "BrowserRageclickEvent"
        case customEvent = "CustomEvent"
        case deadClickProps = "DeadClickProps"
        case derivedTextMeta = "DerivedTextMeta"
        case maskMode = "MaskMode"
        case metricValue = "MetricValue"
        case pageleaveProps = "PageleaveProps"
        case pageviewProps = "PageviewProps"
        case rageclickProps = "RageclickProps"
        case scrollDepthProps = "ScrollDepthProps"
        case tokenBucket = "TokenBucket"
    }
}

// MARK: Events convenience initializers and mutators

extension Events {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Events.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        aiPromptSubmittedProps: AIPromptSubmittedProps?? = nil,
        aiResponseInteractedProps: AIResponseInteractedProps?? = nil,
        aiResponseRenderedProps: AIResponseRenderedProps?? = nil,
        autocaptureProps: AutocaptureProps?? = nil,
        browserAIPromptSubmittedEvent: BrowserAIPromptSubmittedEvent?? = nil,
        browserAIResponseInteractedEvent: BrowserAIResponseInteractedEvent?? = nil,
        browserAIResponseRenderedEvent: BrowserAIResponseRenderedEvent?? = nil,
        browserAutocaptureEvent: BrowserAutocaptureEvent?? = nil,
        browserContextProperties: BrowserContextProperties?? = nil,
        browserDeadClickEvent: BrowserDeadClickEvent?? = nil,
        browserEventBatchRequest: BrowserEventBatchRequest?? = nil,
        browserEventBatchResponse: BrowserEventBatchResponse?? = nil,
        browserEventResult: BrowserEventResult?? = nil,
        browserEventResultCode: BrowserEventResultCode?? = nil,
        browserEventResultStatus: BrowserEventResultStatus?? = nil,
        browserIngestEvent: BrowserIngestEvent?? = nil,
        browserPageleaveEvent: BrowserPageleaveEvent?? = nil,
        browserPageviewEvent: BrowserPageviewEvent?? = nil,
        browserRageclickEvent: BrowserRageclickEvent?? = nil,
        customEvent: CustomEvent?? = nil,
        deadClickProps: DeadClickProps?? = nil,
        derivedTextMeta: DerivedTextMeta?? = nil,
        maskMode: MaskMode?? = nil,
        metricValue: Double?? = nil,
        pageleaveProps: PageleaveProps?? = nil,
        pageviewProps: PageviewProps?? = nil,
        rageclickProps: RageclickProps?? = nil,
        scrollDepthProps: ScrollDepthProps?? = nil,
        tokenBucket: TokenBucket?? = nil
    ) -> Events {
        return Events(
            aiPromptSubmittedProps: aiPromptSubmittedProps ?? self.aiPromptSubmittedProps,
            aiResponseInteractedProps: aiResponseInteractedProps ?? self.aiResponseInteractedProps,
            aiResponseRenderedProps: aiResponseRenderedProps ?? self.aiResponseRenderedProps,
            autocaptureProps: autocaptureProps ?? self.autocaptureProps,
            browserAIPromptSubmittedEvent: browserAIPromptSubmittedEvent ?? self.browserAIPromptSubmittedEvent,
            browserAIResponseInteractedEvent: browserAIResponseInteractedEvent ?? self.browserAIResponseInteractedEvent,
            browserAIResponseRenderedEvent: browserAIResponseRenderedEvent ?? self.browserAIResponseRenderedEvent,
            browserAutocaptureEvent: browserAutocaptureEvent ?? self.browserAutocaptureEvent,
            browserContextProperties: browserContextProperties ?? self.browserContextProperties,
            browserDeadClickEvent: browserDeadClickEvent ?? self.browserDeadClickEvent,
            browserEventBatchRequest: browserEventBatchRequest ?? self.browserEventBatchRequest,
            browserEventBatchResponse: browserEventBatchResponse ?? self.browserEventBatchResponse,
            browserEventResult: browserEventResult ?? self.browserEventResult,
            browserEventResultCode: browserEventResultCode ?? self.browserEventResultCode,
            browserEventResultStatus: browserEventResultStatus ?? self.browserEventResultStatus,
            browserIngestEvent: browserIngestEvent ?? self.browserIngestEvent,
            browserPageleaveEvent: browserPageleaveEvent ?? self.browserPageleaveEvent,
            browserPageviewEvent: browserPageviewEvent ?? self.browserPageviewEvent,
            browserRageclickEvent: browserRageclickEvent ?? self.browserRageclickEvent,
            customEvent: customEvent ?? self.customEvent,
            deadClickProps: deadClickProps ?? self.deadClickProps,
            derivedTextMeta: derivedTextMeta ?? self.derivedTextMeta,
            maskMode: maskMode ?? self.maskMode,
            metricValue: metricValue ?? self.metricValue,
            pageleaveProps: pageleaveProps ?? self.pageleaveProps,
            pageviewProps: pageviewProps ?? self.pageviewProps,
            rageclickProps: rageclickProps ?? self.rageclickProps,
            scrollDepthProps: scrollDepthProps ?? self.scrollDepthProps,
            tokenBucket: tokenBucket ?? self.tokenBucket
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - AIPromptSubmittedProps
struct AIPromptSubmittedProps: Codable {
    let captureMode: CaptureMode
    let containsAttachment, containsCode: Bool?
    let language: String?
    let piiDetected: Bool?
    let promptHash: String?
    let promptLengthChars: Double?
    let promptText: String?
    let promptTokensEstimated: Double?
    let sensitiveCategory: SensitiveCategoryUnion?

    enum CodingKeys: String, CodingKey {
        case captureMode = "$capture_mode"
        case containsAttachment = "$contains_attachment"
        case containsCode = "$contains_code"
        case language = "$language"
        case piiDetected = "$pii_detected"
        case promptHash = "$prompt_hash"
        case promptLengthChars = "$prompt_length_chars"
        case promptText = "$prompt_text"
        case promptTokensEstimated = "$prompt_tokens_estimated"
        case sensitiveCategory = "$sensitive_category"
    }
}

// MARK: AIPromptSubmittedProps convenience initializers and mutators

extension AIPromptSubmittedProps {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(AIPromptSubmittedProps.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        captureMode: CaptureMode? = nil,
        containsAttachment: Bool?? = nil,
        containsCode: Bool?? = nil,
        language: String?? = nil,
        piiDetected: Bool?? = nil,
        promptHash: String?? = nil,
        promptLengthChars: Double?? = nil,
        promptText: String?? = nil,
        promptTokensEstimated: Double?? = nil,
        sensitiveCategory: SensitiveCategoryUnion?? = nil
    ) -> AIPromptSubmittedProps {
        return AIPromptSubmittedProps(
            captureMode: captureMode ?? self.captureMode,
            containsAttachment: containsAttachment ?? self.containsAttachment,
            containsCode: containsCode ?? self.containsCode,
            language: language ?? self.language,
            piiDetected: piiDetected ?? self.piiDetected,
            promptHash: promptHash ?? self.promptHash,
            promptLengthChars: promptLengthChars ?? self.promptLengthChars,
            promptText: promptText ?? self.promptText,
            promptTokensEstimated: promptTokensEstimated ?? self.promptTokensEstimated,
            sensitiveCategory: sensitiveCategory ?? self.sensitiveCategory
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum CaptureMode: String, Codable {
    case full = "full"
    case hash = "hash"
    case metadataOnly = "metadata_only"
    case off = "off"
}

enum SensitiveCategoryUnion: Codable {
    case enumArray([SensitiveCategory])
    case enumeration(SensitiveCategory)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode([SensitiveCategory].self) {
            self = .enumArray(x)
            return
        }
        if let x = try? container.decode(SensitiveCategory.self) {
            self = .enumeration(x)
            return
        }
        throw DecodingError.typeMismatch(SensitiveCategoryUnion.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for SensitiveCategoryUnion"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .enumArray(let x):
            try container.encode(x)
        case .enumeration(let x):
            try container.encode(x)
        }
    }
}

enum SensitiveCategory: String, Codable {
    case credential = "credential"
    case customerData = "customer_data"
    case finance = "finance"
    case healthcare = "healthcare"
    case internalDocument = "internal_document"
    case legal = "legal"
    case pii = "pii"
    case sourceCode = "source_code"
    case unknownSensitive = "unknown_sensitive"
}

// MARK: - AIResponseInteractedProps
struct AIResponseInteractedProps: Codable {
    let destination: String?
    let interactionType: AIInteractionType
    let requestID, responseID, source: String?
    let timeSinceResponseMS, visibleOutputRatio: Double?

    enum CodingKeys: String, CodingKey {
        case destination = "$destination"
        case interactionType = "$interaction_type"
        case requestID = "$request_id"
        case responseID = "$response_id"
        case source = "$source"
        case timeSinceResponseMS = "$time_since_response_ms"
        case visibleOutputRatio = "$visible_output_ratio"
    }
}

// MARK: AIResponseInteractedProps convenience initializers and mutators

extension AIResponseInteractedProps {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(AIResponseInteractedProps.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        destination: String?? = nil,
        interactionType: AIInteractionType? = nil,
        requestID: String?? = nil,
        responseID: String?? = nil,
        source: String?? = nil,
        timeSinceResponseMS: Double?? = nil,
        visibleOutputRatio: Double?? = nil
    ) -> AIResponseInteractedProps {
        return AIResponseInteractedProps(
            destination: destination ?? self.destination,
            interactionType: interactionType ?? self.interactionType,
            requestID: requestID ?? self.requestID,
            responseID: responseID ?? self.responseID,
            source: source ?? self.source,
            timeSinceResponseMS: timeSinceResponseMS ?? self.timeSinceResponseMS,
            visibleOutputRatio: visibleOutputRatio ?? self.visibleOutputRatio
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum AIInteractionType: String, Codable {
    case aborted = "aborted"
    case accepted = "accepted"
    case collapsed = "collapsed"
    case copied = "copied"
    case downloaded = "downloaded"
    case expanded = "expanded"
    case inserted = "inserted"
    case ratedNegative = "rated_negative"
    case ratedPositive = "rated_positive"
    case regenerated = "regenerated"
    case rejected = "rejected"
    case shared = "shared"
}

// MARK: - AIResponseRenderedProps
struct AIResponseRenderedProps: Codable {
    let captureMode: CaptureMode
    let outputLengthChars: Double?
    let responseID: String
    let responseText: String?
    let timeToRenderMS, visibleOutputRatio: Double?

    enum CodingKeys: String, CodingKey {
        case captureMode = "$capture_mode"
        case outputLengthChars = "$output_length_chars"
        case responseID = "$response_id"
        case responseText = "$response_text"
        case timeToRenderMS = "$time_to_render_ms"
        case visibleOutputRatio = "$visible_output_ratio"
    }
}

// MARK: AIResponseRenderedProps convenience initializers and mutators

extension AIResponseRenderedProps {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(AIResponseRenderedProps.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        captureMode: CaptureMode? = nil,
        outputLengthChars: Double?? = nil,
        responseID: String? = nil,
        responseText: String?? = nil,
        timeToRenderMS: Double?? = nil,
        visibleOutputRatio: Double?? = nil
    ) -> AIResponseRenderedProps {
        return AIResponseRenderedProps(
            captureMode: captureMode ?? self.captureMode,
            outputLengthChars: outputLengthChars ?? self.outputLengthChars,
            responseID: responseID ?? self.responseID,
            responseText: responseText ?? self.responseText,
            timeToRenderMS: timeToRenderMS ?? self.timeToRenderMS,
            visibleOutputRatio: visibleOutputRatio ?? self.visibleOutputRatio
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - AutocaptureProps
struct AutocaptureProps: Codable {
    let aiAction: String?
    let ceVersion: Double
    let elName, elText, elValue: String?
    let elementsChain: String
    let eventType: AutocaptureEventType
    let href, inputType, requestID, responseID: String?
    let selectionLength: Double?
    let tagName: String?

    enum CodingKeys: String, CodingKey {
        case aiAction = "$ai_action"
        case ceVersion = "$ce_version"
        case elName = "$el_name"
        case elText = "$el_text"
        case elValue = "$el_value"
        case elementsChain = "$elements_chain"
        case eventType = "$event_type"
        case href = "$href"
        case inputType = "$input_type"
        case requestID = "$request_id"
        case responseID = "$response_id"
        case selectionLength = "$selection_length"
        case tagName = "$tag_name"
    }
}

// MARK: AutocaptureProps convenience initializers and mutators

extension AutocaptureProps {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(AutocaptureProps.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        aiAction: String?? = nil,
        ceVersion: Double? = nil,
        elName: String?? = nil,
        elText: String?? = nil,
        elValue: String?? = nil,
        elementsChain: String? = nil,
        eventType: AutocaptureEventType? = nil,
        href: String?? = nil,
        inputType: String?? = nil,
        requestID: String?? = nil,
        responseID: String?? = nil,
        selectionLength: Double?? = nil,
        tagName: String?? = nil
    ) -> AutocaptureProps {
        return AutocaptureProps(
            aiAction: aiAction ?? self.aiAction,
            ceVersion: ceVersion ?? self.ceVersion,
            elName: elName ?? self.elName,
            elText: elText ?? self.elText,
            elValue: elValue ?? self.elValue,
            elementsChain: elementsChain ?? self.elementsChain,
            eventType: eventType ?? self.eventType,
            href: href ?? self.href,
            inputType: inputType ?? self.inputType,
            requestID: requestID ?? self.requestID,
            responseID: responseID ?? self.responseID,
            selectionLength: selectionLength ?? self.selectionLength,
            tagName: tagName ?? self.tagName
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum AutocaptureEventType: String, Codable {
    case change = "change"
    case click = "click"
    case copy = "copy"
    case submit = "submit"
}

// MARK: - BrowserAIPromptSubmittedEvent
struct BrowserAIPromptSubmittedEvent: Codable {
    let deviceID: String
    let eventID: String
    let eventName: BrowserAIPromptSubmittedEventEventName
    let extraJSON: BrowserAIPromptSubmittedEventExtraJSON
    let occurredAt: String
    let scale: String?
    let sessionID, traceID: String?
    let value: Double?

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case eventID = "event_id"
        case eventName = "event_name"
        case extraJSON = "extra_json"
        case occurredAt = "occurred_at"
        case scale
        case sessionID = "session_id"
        case traceID = "trace_id"
        case value
    }
}

// MARK: BrowserAIPromptSubmittedEvent convenience initializers and mutators

extension BrowserAIPromptSubmittedEvent {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserAIPromptSubmittedEvent.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        deviceID: String? = nil,
        eventID: String? = nil,
        eventName: BrowserAIPromptSubmittedEventEventName? = nil,
        extraJSON: BrowserAIPromptSubmittedEventExtraJSON? = nil,
        occurredAt: String? = nil,
        scale: String?? = nil,
        sessionID: String?? = nil,
        traceID: String?? = nil,
        value: Double?? = nil
    ) -> BrowserAIPromptSubmittedEvent {
        return BrowserAIPromptSubmittedEvent(
            deviceID: deviceID ?? self.deviceID,
            eventID: eventID ?? self.eventID,
            eventName: eventName ?? self.eventName,
            extraJSON: extraJSON ?? self.extraJSON,
            occurredAt: occurredAt ?? self.occurredAt,
            scale: scale ?? self.scale,
            sessionID: sessionID ?? self.sessionID,
            traceID: traceID ?? self.traceID,
            value: value ?? self.value
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum BrowserAIPromptSubmittedEventEventName: String, Codable {
    case llmPromptSubmitted = "llm_prompt_submitted"
}

// MARK: - BrowserAIPromptSubmittedEventExtraJSON
struct BrowserAIPromptSubmittedEventExtraJSON: Codable {
    let anonymousID, appVersion: String?
    let captureMode: CaptureMode
    let containsAttachment, containsCode: Bool?
    let conversationID, deviceID, entryPoint: String?
    let environment: Environment?
    let featureFlagKey, featureFlagVariant, language: String?
    let lib: LIB?
    let libVersion, messageID, nodeKey, pageviewID: String?
    let piiDetected: Bool?
    let promptHash: String?
    let promptLengthChars: Double?
    let promptTemplateID, promptText: String?
    let promptTokensEstimated: Double?
    let requestID, responseID, schemaVersion: String?
    let sensitiveCategory: SensitiveCategoryUnion?
    let sessionID, surface, taskType, tenantID: String?
    let traceID, userID, windowID: String?

    enum CodingKeys: String, CodingKey {
        case anonymousID = "$anonymous_id"
        case appVersion = "$app_version"
        case captureMode = "$capture_mode"
        case containsAttachment = "$contains_attachment"
        case containsCode = "$contains_code"
        case conversationID = "$conversation_id"
        case deviceID = "$device_id"
        case entryPoint = "$entry_point"
        case environment = "$environment"
        case featureFlagKey = "$feature_flag_key"
        case featureFlagVariant = "$feature_flag_variant"
        case language = "$language"
        case lib = "$lib"
        case libVersion = "$lib_version"
        case messageID = "$message_id"
        case nodeKey = "$node_key"
        case pageviewID = "$pageview_id"
        case piiDetected = "$pii_detected"
        case promptHash = "$prompt_hash"
        case promptLengthChars = "$prompt_length_chars"
        case promptTemplateID = "$prompt_template_id"
        case promptText = "$prompt_text"
        case promptTokensEstimated = "$prompt_tokens_estimated"
        case requestID = "$request_id"
        case responseID = "$response_id"
        case schemaVersion = "$schema_version"
        case sensitiveCategory = "$sensitive_category"
        case sessionID = "$session_id"
        case surface = "$surface"
        case taskType = "$task_type"
        case tenantID = "$tenant_id"
        case traceID = "$trace_id"
        case userID = "$user_id"
        case windowID = "$window_id"
    }
}

// MARK: BrowserAIPromptSubmittedEventExtraJSON convenience initializers and mutators

extension BrowserAIPromptSubmittedEventExtraJSON {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserAIPromptSubmittedEventExtraJSON.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        anonymousID: String?? = nil,
        appVersion: String?? = nil,
        captureMode: CaptureMode? = nil,
        containsAttachment: Bool?? = nil,
        containsCode: Bool?? = nil,
        conversationID: String?? = nil,
        deviceID: String?? = nil,
        entryPoint: String?? = nil,
        environment: Environment?? = nil,
        featureFlagKey: String?? = nil,
        featureFlagVariant: String?? = nil,
        language: String?? = nil,
        lib: LIB?? = nil,
        libVersion: String?? = nil,
        messageID: String?? = nil,
        nodeKey: String?? = nil,
        pageviewID: String?? = nil,
        piiDetected: Bool?? = nil,
        promptHash: String?? = nil,
        promptLengthChars: Double?? = nil,
        promptTemplateID: String?? = nil,
        promptText: String?? = nil,
        promptTokensEstimated: Double?? = nil,
        requestID: String?? = nil,
        responseID: String?? = nil,
        schemaVersion: String?? = nil,
        sensitiveCategory: SensitiveCategoryUnion?? = nil,
        sessionID: String?? = nil,
        surface: String?? = nil,
        taskType: String?? = nil,
        tenantID: String?? = nil,
        traceID: String?? = nil,
        userID: String?? = nil,
        windowID: String?? = nil
    ) -> BrowserAIPromptSubmittedEventExtraJSON {
        return BrowserAIPromptSubmittedEventExtraJSON(
            anonymousID: anonymousID ?? self.anonymousID,
            appVersion: appVersion ?? self.appVersion,
            captureMode: captureMode ?? self.captureMode,
            containsAttachment: containsAttachment ?? self.containsAttachment,
            containsCode: containsCode ?? self.containsCode,
            conversationID: conversationID ?? self.conversationID,
            deviceID: deviceID ?? self.deviceID,
            entryPoint: entryPoint ?? self.entryPoint,
            environment: environment ?? self.environment,
            featureFlagKey: featureFlagKey ?? self.featureFlagKey,
            featureFlagVariant: featureFlagVariant ?? self.featureFlagVariant,
            language: language ?? self.language,
            lib: lib ?? self.lib,
            libVersion: libVersion ?? self.libVersion,
            messageID: messageID ?? self.messageID,
            nodeKey: nodeKey ?? self.nodeKey,
            pageviewID: pageviewID ?? self.pageviewID,
            piiDetected: piiDetected ?? self.piiDetected,
            promptHash: promptHash ?? self.promptHash,
            promptLengthChars: promptLengthChars ?? self.promptLengthChars,
            promptTemplateID: promptTemplateID ?? self.promptTemplateID,
            promptText: promptText ?? self.promptText,
            promptTokensEstimated: promptTokensEstimated ?? self.promptTokensEstimated,
            requestID: requestID ?? self.requestID,
            responseID: responseID ?? self.responseID,
            schemaVersion: schemaVersion ?? self.schemaVersion,
            sensitiveCategory: sensitiveCategory ?? self.sensitiveCategory,
            sessionID: sessionID ?? self.sessionID,
            surface: surface ?? self.surface,
            taskType: taskType ?? self.taskType,
            tenantID: tenantID ?? self.tenantID,
            traceID: traceID ?? self.traceID,
            userID: userID ?? self.userID,
            windowID: windowID ?? self.windowID
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum Environment: String, Codable {
    case development = "development"
    case production = "production"
}

enum LIB: String, Codable {
    case android = "android"
    case flutter = "flutter"
    case ios = "ios"
    case web = "web"
}

// MARK: - BrowserAIResponseInteractedEvent
struct BrowserAIResponseInteractedEvent: Codable {
    let deviceID: String
    let eventID: String
    let eventName: BrowserAIResponseInteractedEventEventName
    let extraJSON: BrowserAIResponseInteractedEventExtraJSON
    let occurredAt: String
    let scale: String?
    let sessionID, traceID: String?
    let value: Double?

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case eventID = "event_id"
        case eventName = "event_name"
        case extraJSON = "extra_json"
        case occurredAt = "occurred_at"
        case scale
        case sessionID = "session_id"
        case traceID = "trace_id"
        case value
    }
}

// MARK: BrowserAIResponseInteractedEvent convenience initializers and mutators

extension BrowserAIResponseInteractedEvent {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserAIResponseInteractedEvent.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        deviceID: String? = nil,
        eventID: String? = nil,
        eventName: BrowserAIResponseInteractedEventEventName? = nil,
        extraJSON: BrowserAIResponseInteractedEventExtraJSON? = nil,
        occurredAt: String? = nil,
        scale: String?? = nil,
        sessionID: String?? = nil,
        traceID: String?? = nil,
        value: Double?? = nil
    ) -> BrowserAIResponseInteractedEvent {
        return BrowserAIResponseInteractedEvent(
            deviceID: deviceID ?? self.deviceID,
            eventID: eventID ?? self.eventID,
            eventName: eventName ?? self.eventName,
            extraJSON: extraJSON ?? self.extraJSON,
            occurredAt: occurredAt ?? self.occurredAt,
            scale: scale ?? self.scale,
            sessionID: sessionID ?? self.sessionID,
            traceID: traceID ?? self.traceID,
            value: value ?? self.value
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum BrowserAIResponseInteractedEventEventName: String, Codable {
    case llmResponseInteracted = "llm_response_interacted"
}

// MARK: - BrowserAIResponseInteractedEventExtraJSON
struct BrowserAIResponseInteractedEventExtraJSON: Codable {
    let anonymousID, appVersion, conversationID, destination: String?
    let deviceID, entryPoint: String?
    let environment: Environment?
    let featureFlagKey, featureFlagVariant: String?
    let interactionType: AIInteractionType
    let lib: LIB?
    let libVersion, messageID, nodeKey, pageviewID: String?
    let promptTemplateID, requestID, responseID, schemaVersion: String?
    let sessionID, source, surface, taskType: String?
    let tenantID: String?
    let timeSinceResponseMS: Double?
    let traceID, userID: String?
    let visibleOutputRatio: Double?
    let windowID: String?

    enum CodingKeys: String, CodingKey {
        case anonymousID = "$anonymous_id"
        case appVersion = "$app_version"
        case conversationID = "$conversation_id"
        case destination = "$destination"
        case deviceID = "$device_id"
        case entryPoint = "$entry_point"
        case environment = "$environment"
        case featureFlagKey = "$feature_flag_key"
        case featureFlagVariant = "$feature_flag_variant"
        case interactionType = "$interaction_type"
        case lib = "$lib"
        case libVersion = "$lib_version"
        case messageID = "$message_id"
        case nodeKey = "$node_key"
        case pageviewID = "$pageview_id"
        case promptTemplateID = "$prompt_template_id"
        case requestID = "$request_id"
        case responseID = "$response_id"
        case schemaVersion = "$schema_version"
        case sessionID = "$session_id"
        case source = "$source"
        case surface = "$surface"
        case taskType = "$task_type"
        case tenantID = "$tenant_id"
        case timeSinceResponseMS = "$time_since_response_ms"
        case traceID = "$trace_id"
        case userID = "$user_id"
        case visibleOutputRatio = "$visible_output_ratio"
        case windowID = "$window_id"
    }
}

// MARK: BrowserAIResponseInteractedEventExtraJSON convenience initializers and mutators

extension BrowserAIResponseInteractedEventExtraJSON {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserAIResponseInteractedEventExtraJSON.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        anonymousID: String?? = nil,
        appVersion: String?? = nil,
        conversationID: String?? = nil,
        destination: String?? = nil,
        deviceID: String?? = nil,
        entryPoint: String?? = nil,
        environment: Environment?? = nil,
        featureFlagKey: String?? = nil,
        featureFlagVariant: String?? = nil,
        interactionType: AIInteractionType? = nil,
        lib: LIB?? = nil,
        libVersion: String?? = nil,
        messageID: String?? = nil,
        nodeKey: String?? = nil,
        pageviewID: String?? = nil,
        promptTemplateID: String?? = nil,
        requestID: String?? = nil,
        responseID: String?? = nil,
        schemaVersion: String?? = nil,
        sessionID: String?? = nil,
        source: String?? = nil,
        surface: String?? = nil,
        taskType: String?? = nil,
        tenantID: String?? = nil,
        timeSinceResponseMS: Double?? = nil,
        traceID: String?? = nil,
        userID: String?? = nil,
        visibleOutputRatio: Double?? = nil,
        windowID: String?? = nil
    ) -> BrowserAIResponseInteractedEventExtraJSON {
        return BrowserAIResponseInteractedEventExtraJSON(
            anonymousID: anonymousID ?? self.anonymousID,
            appVersion: appVersion ?? self.appVersion,
            conversationID: conversationID ?? self.conversationID,
            destination: destination ?? self.destination,
            deviceID: deviceID ?? self.deviceID,
            entryPoint: entryPoint ?? self.entryPoint,
            environment: environment ?? self.environment,
            featureFlagKey: featureFlagKey ?? self.featureFlagKey,
            featureFlagVariant: featureFlagVariant ?? self.featureFlagVariant,
            interactionType: interactionType ?? self.interactionType,
            lib: lib ?? self.lib,
            libVersion: libVersion ?? self.libVersion,
            messageID: messageID ?? self.messageID,
            nodeKey: nodeKey ?? self.nodeKey,
            pageviewID: pageviewID ?? self.pageviewID,
            promptTemplateID: promptTemplateID ?? self.promptTemplateID,
            requestID: requestID ?? self.requestID,
            responseID: responseID ?? self.responseID,
            schemaVersion: schemaVersion ?? self.schemaVersion,
            sessionID: sessionID ?? self.sessionID,
            source: source ?? self.source,
            surface: surface ?? self.surface,
            taskType: taskType ?? self.taskType,
            tenantID: tenantID ?? self.tenantID,
            timeSinceResponseMS: timeSinceResponseMS ?? self.timeSinceResponseMS,
            traceID: traceID ?? self.traceID,
            userID: userID ?? self.userID,
            visibleOutputRatio: visibleOutputRatio ?? self.visibleOutputRatio,
            windowID: windowID ?? self.windowID
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - BrowserAIResponseRenderedEvent
struct BrowserAIResponseRenderedEvent: Codable {
    let deviceID: String
    let eventID: String
    let eventName: BrowserAIResponseRenderedEventEventName
    let extraJSON: BrowserAIResponseRenderedEventExtraJSON
    let occurredAt: String
    let scale: String?
    let sessionID, traceID: String?
    let value: Double?

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case eventID = "event_id"
        case eventName = "event_name"
        case extraJSON = "extra_json"
        case occurredAt = "occurred_at"
        case scale
        case sessionID = "session_id"
        case traceID = "trace_id"
        case value
    }
}

// MARK: BrowserAIResponseRenderedEvent convenience initializers and mutators

extension BrowserAIResponseRenderedEvent {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserAIResponseRenderedEvent.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        deviceID: String? = nil,
        eventID: String? = nil,
        eventName: BrowserAIResponseRenderedEventEventName? = nil,
        extraJSON: BrowserAIResponseRenderedEventExtraJSON? = nil,
        occurredAt: String? = nil,
        scale: String?? = nil,
        sessionID: String?? = nil,
        traceID: String?? = nil,
        value: Double?? = nil
    ) -> BrowserAIResponseRenderedEvent {
        return BrowserAIResponseRenderedEvent(
            deviceID: deviceID ?? self.deviceID,
            eventID: eventID ?? self.eventID,
            eventName: eventName ?? self.eventName,
            extraJSON: extraJSON ?? self.extraJSON,
            occurredAt: occurredAt ?? self.occurredAt,
            scale: scale ?? self.scale,
            sessionID: sessionID ?? self.sessionID,
            traceID: traceID ?? self.traceID,
            value: value ?? self.value
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum BrowserAIResponseRenderedEventEventName: String, Codable {
    case llmResponseRendered = "llm_response_rendered"
}

// MARK: - BrowserAIResponseRenderedEventExtraJSON
struct BrowserAIResponseRenderedEventExtraJSON: Codable {
    let anonymousID, appVersion: String?
    let captureMode: CaptureMode
    let conversationID, deviceID, entryPoint: String?
    let environment: Environment?
    let featureFlagKey, featureFlagVariant: String?
    let lib: LIB?
    let libVersion, messageID, nodeKey: String?
    let outputLengthChars: Double?
    let pageviewID, promptTemplateID, requestID: String?
    let responseID: String
    let responseText, schemaVersion, sessionID, surface: String?
    let taskType, tenantID: String?
    let timeToRenderMS: Double?
    let traceID, userID: String?
    let visibleOutputRatio: Double?
    let windowID: String?

    enum CodingKeys: String, CodingKey {
        case anonymousID = "$anonymous_id"
        case appVersion = "$app_version"
        case captureMode = "$capture_mode"
        case conversationID = "$conversation_id"
        case deviceID = "$device_id"
        case entryPoint = "$entry_point"
        case environment = "$environment"
        case featureFlagKey = "$feature_flag_key"
        case featureFlagVariant = "$feature_flag_variant"
        case lib = "$lib"
        case libVersion = "$lib_version"
        case messageID = "$message_id"
        case nodeKey = "$node_key"
        case outputLengthChars = "$output_length_chars"
        case pageviewID = "$pageview_id"
        case promptTemplateID = "$prompt_template_id"
        case requestID = "$request_id"
        case responseID = "$response_id"
        case responseText = "$response_text"
        case schemaVersion = "$schema_version"
        case sessionID = "$session_id"
        case surface = "$surface"
        case taskType = "$task_type"
        case tenantID = "$tenant_id"
        case timeToRenderMS = "$time_to_render_ms"
        case traceID = "$trace_id"
        case userID = "$user_id"
        case visibleOutputRatio = "$visible_output_ratio"
        case windowID = "$window_id"
    }
}

// MARK: BrowserAIResponseRenderedEventExtraJSON convenience initializers and mutators

extension BrowserAIResponseRenderedEventExtraJSON {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserAIResponseRenderedEventExtraJSON.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        anonymousID: String?? = nil,
        appVersion: String?? = nil,
        captureMode: CaptureMode? = nil,
        conversationID: String?? = nil,
        deviceID: String?? = nil,
        entryPoint: String?? = nil,
        environment: Environment?? = nil,
        featureFlagKey: String?? = nil,
        featureFlagVariant: String?? = nil,
        lib: LIB?? = nil,
        libVersion: String?? = nil,
        messageID: String?? = nil,
        nodeKey: String?? = nil,
        outputLengthChars: Double?? = nil,
        pageviewID: String?? = nil,
        promptTemplateID: String?? = nil,
        requestID: String?? = nil,
        responseID: String? = nil,
        responseText: String?? = nil,
        schemaVersion: String?? = nil,
        sessionID: String?? = nil,
        surface: String?? = nil,
        taskType: String?? = nil,
        tenantID: String?? = nil,
        timeToRenderMS: Double?? = nil,
        traceID: String?? = nil,
        userID: String?? = nil,
        visibleOutputRatio: Double?? = nil,
        windowID: String?? = nil
    ) -> BrowserAIResponseRenderedEventExtraJSON {
        return BrowserAIResponseRenderedEventExtraJSON(
            anonymousID: anonymousID ?? self.anonymousID,
            appVersion: appVersion ?? self.appVersion,
            captureMode: captureMode ?? self.captureMode,
            conversationID: conversationID ?? self.conversationID,
            deviceID: deviceID ?? self.deviceID,
            entryPoint: entryPoint ?? self.entryPoint,
            environment: environment ?? self.environment,
            featureFlagKey: featureFlagKey ?? self.featureFlagKey,
            featureFlagVariant: featureFlagVariant ?? self.featureFlagVariant,
            lib: lib ?? self.lib,
            libVersion: libVersion ?? self.libVersion,
            messageID: messageID ?? self.messageID,
            nodeKey: nodeKey ?? self.nodeKey,
            outputLengthChars: outputLengthChars ?? self.outputLengthChars,
            pageviewID: pageviewID ?? self.pageviewID,
            promptTemplateID: promptTemplateID ?? self.promptTemplateID,
            requestID: requestID ?? self.requestID,
            responseID: responseID ?? self.responseID,
            responseText: responseText ?? self.responseText,
            schemaVersion: schemaVersion ?? self.schemaVersion,
            sessionID: sessionID ?? self.sessionID,
            surface: surface ?? self.surface,
            taskType: taskType ?? self.taskType,
            tenantID: tenantID ?? self.tenantID,
            timeToRenderMS: timeToRenderMS ?? self.timeToRenderMS,
            traceID: traceID ?? self.traceID,
            userID: userID ?? self.userID,
            visibleOutputRatio: visibleOutputRatio ?? self.visibleOutputRatio,
            windowID: windowID ?? self.windowID
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - BrowserAutocaptureEvent
struct BrowserAutocaptureEvent: Codable {
    let deviceID: String
    let eventID: String
    let eventName: BrowserAutocaptureEventEventName
    let extraJSON: BrowserAutocaptureEventExtraJSON
    let occurredAt: String
    let scale: String?
    let sessionID, traceID: String?
    let value: Double?

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case eventID = "event_id"
        case eventName = "event_name"
        case extraJSON = "extra_json"
        case occurredAt = "occurred_at"
        case scale
        case sessionID = "session_id"
        case traceID = "trace_id"
        case value
    }
}

// MARK: BrowserAutocaptureEvent convenience initializers and mutators

extension BrowserAutocaptureEvent {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserAutocaptureEvent.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        deviceID: String? = nil,
        eventID: String? = nil,
        eventName: BrowserAutocaptureEventEventName? = nil,
        extraJSON: BrowserAutocaptureEventExtraJSON? = nil,
        occurredAt: String? = nil,
        scale: String?? = nil,
        sessionID: String?? = nil,
        traceID: String?? = nil,
        value: Double?? = nil
    ) -> BrowserAutocaptureEvent {
        return BrowserAutocaptureEvent(
            deviceID: deviceID ?? self.deviceID,
            eventID: eventID ?? self.eventID,
            eventName: eventName ?? self.eventName,
            extraJSON: extraJSON ?? self.extraJSON,
            occurredAt: occurredAt ?? self.occurredAt,
            scale: scale ?? self.scale,
            sessionID: sessionID ?? self.sessionID,
            traceID: traceID ?? self.traceID,
            value: value ?? self.value
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum BrowserAutocaptureEventEventName: String, Codable {
    case interactionAutocaptured = "interaction_autocaptured"
}

// MARK: - BrowserAutocaptureEventExtraJSON
struct BrowserAutocaptureEventExtraJSON: Codable {
    let aiAction, anonymousID, appVersion: String?
    let ceVersion: Double
    let conversationID, deviceID, elName, elText: String?
    let elValue: String?
    let elementsChain: String
    let entryPoint: String?
    let environment: Environment?
    let eventType: AutocaptureEventType
    let featureFlagKey, featureFlagVariant, href, inputType: String?
    let lib: LIB?
    let libVersion, messageID, nodeKey, pageviewID: String?
    let promptTemplateID, requestID, responseID, schemaVersion: String?
    let selectionLength: Double?
    let sessionID, surface, tagName, taskType: String?
    let tenantID, traceID, userID, windowID: String?

    enum CodingKeys: String, CodingKey {
        case aiAction = "$ai_action"
        case anonymousID = "$anonymous_id"
        case appVersion = "$app_version"
        case ceVersion = "$ce_version"
        case conversationID = "$conversation_id"
        case deviceID = "$device_id"
        case elName = "$el_name"
        case elText = "$el_text"
        case elValue = "$el_value"
        case elementsChain = "$elements_chain"
        case entryPoint = "$entry_point"
        case environment = "$environment"
        case eventType = "$event_type"
        case featureFlagKey = "$feature_flag_key"
        case featureFlagVariant = "$feature_flag_variant"
        case href = "$href"
        case inputType = "$input_type"
        case lib = "$lib"
        case libVersion = "$lib_version"
        case messageID = "$message_id"
        case nodeKey = "$node_key"
        case pageviewID = "$pageview_id"
        case promptTemplateID = "$prompt_template_id"
        case requestID = "$request_id"
        case responseID = "$response_id"
        case schemaVersion = "$schema_version"
        case selectionLength = "$selection_length"
        case sessionID = "$session_id"
        case surface = "$surface"
        case tagName = "$tag_name"
        case taskType = "$task_type"
        case tenantID = "$tenant_id"
        case traceID = "$trace_id"
        case userID = "$user_id"
        case windowID = "$window_id"
    }
}

// MARK: BrowserAutocaptureEventExtraJSON convenience initializers and mutators

extension BrowserAutocaptureEventExtraJSON {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserAutocaptureEventExtraJSON.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        aiAction: String?? = nil,
        anonymousID: String?? = nil,
        appVersion: String?? = nil,
        ceVersion: Double? = nil,
        conversationID: String?? = nil,
        deviceID: String?? = nil,
        elName: String?? = nil,
        elText: String?? = nil,
        elValue: String?? = nil,
        elementsChain: String? = nil,
        entryPoint: String?? = nil,
        environment: Environment?? = nil,
        eventType: AutocaptureEventType? = nil,
        featureFlagKey: String?? = nil,
        featureFlagVariant: String?? = nil,
        href: String?? = nil,
        inputType: String?? = nil,
        lib: LIB?? = nil,
        libVersion: String?? = nil,
        messageID: String?? = nil,
        nodeKey: String?? = nil,
        pageviewID: String?? = nil,
        promptTemplateID: String?? = nil,
        requestID: String?? = nil,
        responseID: String?? = nil,
        schemaVersion: String?? = nil,
        selectionLength: Double?? = nil,
        sessionID: String?? = nil,
        surface: String?? = nil,
        tagName: String?? = nil,
        taskType: String?? = nil,
        tenantID: String?? = nil,
        traceID: String?? = nil,
        userID: String?? = nil,
        windowID: String?? = nil
    ) -> BrowserAutocaptureEventExtraJSON {
        return BrowserAutocaptureEventExtraJSON(
            aiAction: aiAction ?? self.aiAction,
            anonymousID: anonymousID ?? self.anonymousID,
            appVersion: appVersion ?? self.appVersion,
            ceVersion: ceVersion ?? self.ceVersion,
            conversationID: conversationID ?? self.conversationID,
            deviceID: deviceID ?? self.deviceID,
            elName: elName ?? self.elName,
            elText: elText ?? self.elText,
            elValue: elValue ?? self.elValue,
            elementsChain: elementsChain ?? self.elementsChain,
            entryPoint: entryPoint ?? self.entryPoint,
            environment: environment ?? self.environment,
            eventType: eventType ?? self.eventType,
            featureFlagKey: featureFlagKey ?? self.featureFlagKey,
            featureFlagVariant: featureFlagVariant ?? self.featureFlagVariant,
            href: href ?? self.href,
            inputType: inputType ?? self.inputType,
            lib: lib ?? self.lib,
            libVersion: libVersion ?? self.libVersion,
            messageID: messageID ?? self.messageID,
            nodeKey: nodeKey ?? self.nodeKey,
            pageviewID: pageviewID ?? self.pageviewID,
            promptTemplateID: promptTemplateID ?? self.promptTemplateID,
            requestID: requestID ?? self.requestID,
            responseID: responseID ?? self.responseID,
            schemaVersion: schemaVersion ?? self.schemaVersion,
            selectionLength: selectionLength ?? self.selectionLength,
            sessionID: sessionID ?? self.sessionID,
            surface: surface ?? self.surface,
            tagName: tagName ?? self.tagName,
            taskType: taskType ?? self.taskType,
            tenantID: tenantID ?? self.tenantID,
            traceID: traceID ?? self.traceID,
            userID: userID ?? self.userID,
            windowID: windowID ?? self.windowID
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - BrowserContextProperties
struct BrowserContextProperties: Codable {
    let anonymousID, appVersion, conversationID, deviceID: String?
    let entryPoint: String?
    let environment: Environment?
    let featureFlagKey, featureFlagVariant: String?
    let lib: LIB?
    let libVersion, messageID, nodeKey, pageviewID: String?
    let promptTemplateID, requestID, responseID, schemaVersion: String?
    let sessionID, surface, taskType, tenantID: String?
    let traceID, userID, windowID: String?

    enum CodingKeys: String, CodingKey {
        case anonymousID = "$anonymous_id"
        case appVersion = "$app_version"
        case conversationID = "$conversation_id"
        case deviceID = "$device_id"
        case entryPoint = "$entry_point"
        case environment = "$environment"
        case featureFlagKey = "$feature_flag_key"
        case featureFlagVariant = "$feature_flag_variant"
        case lib = "$lib"
        case libVersion = "$lib_version"
        case messageID = "$message_id"
        case nodeKey = "$node_key"
        case pageviewID = "$pageview_id"
        case promptTemplateID = "$prompt_template_id"
        case requestID = "$request_id"
        case responseID = "$response_id"
        case schemaVersion = "$schema_version"
        case sessionID = "$session_id"
        case surface = "$surface"
        case taskType = "$task_type"
        case tenantID = "$tenant_id"
        case traceID = "$trace_id"
        case userID = "$user_id"
        case windowID = "$window_id"
    }
}

// MARK: BrowserContextProperties convenience initializers and mutators

extension BrowserContextProperties {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserContextProperties.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        anonymousID: String?? = nil,
        appVersion: String?? = nil,
        conversationID: String?? = nil,
        deviceID: String?? = nil,
        entryPoint: String?? = nil,
        environment: Environment?? = nil,
        featureFlagKey: String?? = nil,
        featureFlagVariant: String?? = nil,
        lib: LIB?? = nil,
        libVersion: String?? = nil,
        messageID: String?? = nil,
        nodeKey: String?? = nil,
        pageviewID: String?? = nil,
        promptTemplateID: String?? = nil,
        requestID: String?? = nil,
        responseID: String?? = nil,
        schemaVersion: String?? = nil,
        sessionID: String?? = nil,
        surface: String?? = nil,
        taskType: String?? = nil,
        tenantID: String?? = nil,
        traceID: String?? = nil,
        userID: String?? = nil,
        windowID: String?? = nil
    ) -> BrowserContextProperties {
        return BrowserContextProperties(
            anonymousID: anonymousID ?? self.anonymousID,
            appVersion: appVersion ?? self.appVersion,
            conversationID: conversationID ?? self.conversationID,
            deviceID: deviceID ?? self.deviceID,
            entryPoint: entryPoint ?? self.entryPoint,
            environment: environment ?? self.environment,
            featureFlagKey: featureFlagKey ?? self.featureFlagKey,
            featureFlagVariant: featureFlagVariant ?? self.featureFlagVariant,
            lib: lib ?? self.lib,
            libVersion: libVersion ?? self.libVersion,
            messageID: messageID ?? self.messageID,
            nodeKey: nodeKey ?? self.nodeKey,
            pageviewID: pageviewID ?? self.pageviewID,
            promptTemplateID: promptTemplateID ?? self.promptTemplateID,
            requestID: requestID ?? self.requestID,
            responseID: responseID ?? self.responseID,
            schemaVersion: schemaVersion ?? self.schemaVersion,
            sessionID: sessionID ?? self.sessionID,
            surface: surface ?? self.surface,
            taskType: taskType ?? self.taskType,
            tenantID: tenantID ?? self.tenantID,
            traceID: traceID ?? self.traceID,
            userID: userID ?? self.userID,
            windowID: windowID ?? self.windowID
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - BrowserDeadClickEvent
struct BrowserDeadClickEvent: Codable {
    let deviceID: String
    let eventID: String
    let eventName: BrowserDeadClickEventEventName
    let extraJSON: BrowserDeadClickEventExtraJSON
    let occurredAt: String
    let scale: String?
    let sessionID, traceID: String?
    let value: Double?

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case eventID = "event_id"
        case eventName = "event_name"
        case extraJSON = "extra_json"
        case occurredAt = "occurred_at"
        case scale
        case sessionID = "session_id"
        case traceID = "trace_id"
        case value
    }
}

// MARK: BrowserDeadClickEvent convenience initializers and mutators

extension BrowserDeadClickEvent {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserDeadClickEvent.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        deviceID: String? = nil,
        eventID: String? = nil,
        eventName: BrowserDeadClickEventEventName? = nil,
        extraJSON: BrowserDeadClickEventExtraJSON? = nil,
        occurredAt: String? = nil,
        scale: String?? = nil,
        sessionID: String?? = nil,
        traceID: String?? = nil,
        value: Double?? = nil
    ) -> BrowserDeadClickEvent {
        return BrowserDeadClickEvent(
            deviceID: deviceID ?? self.deviceID,
            eventID: eventID ?? self.eventID,
            eventName: eventName ?? self.eventName,
            extraJSON: extraJSON ?? self.extraJSON,
            occurredAt: occurredAt ?? self.occurredAt,
            scale: scale ?? self.scale,
            sessionID: sessionID ?? self.sessionID,
            traceID: traceID ?? self.traceID,
            value: value ?? self.value
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum BrowserDeadClickEventEventName: String, Codable {
    case interactionDeadclick = "interaction_deadclick"
}

// MARK: - BrowserDeadClickEventExtraJSON
struct BrowserDeadClickEventExtraJSON: Codable {
    let anonymousID, appVersion, conversationID, deviceID: String?
    let elementsChain: String
    let entryPoint: String?
    let environment: Environment?
    let featureFlagKey, featureFlagVariant: String?
    let lib: LIB?
    let libVersion, messageID, nodeKey, pageviewID: String?
    let promptTemplateID, requestID, responseID, schemaVersion: String?
    let sessionID, surface, taskType, tenantID: String?
    let traceID, userID, windowID: String?

    enum CodingKeys: String, CodingKey {
        case anonymousID = "$anonymous_id"
        case appVersion = "$app_version"
        case conversationID = "$conversation_id"
        case deviceID = "$device_id"
        case elementsChain = "$elements_chain"
        case entryPoint = "$entry_point"
        case environment = "$environment"
        case featureFlagKey = "$feature_flag_key"
        case featureFlagVariant = "$feature_flag_variant"
        case lib = "$lib"
        case libVersion = "$lib_version"
        case messageID = "$message_id"
        case nodeKey = "$node_key"
        case pageviewID = "$pageview_id"
        case promptTemplateID = "$prompt_template_id"
        case requestID = "$request_id"
        case responseID = "$response_id"
        case schemaVersion = "$schema_version"
        case sessionID = "$session_id"
        case surface = "$surface"
        case taskType = "$task_type"
        case tenantID = "$tenant_id"
        case traceID = "$trace_id"
        case userID = "$user_id"
        case windowID = "$window_id"
    }
}

// MARK: BrowserDeadClickEventExtraJSON convenience initializers and mutators

extension BrowserDeadClickEventExtraJSON {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserDeadClickEventExtraJSON.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        anonymousID: String?? = nil,
        appVersion: String?? = nil,
        conversationID: String?? = nil,
        deviceID: String?? = nil,
        elementsChain: String? = nil,
        entryPoint: String?? = nil,
        environment: Environment?? = nil,
        featureFlagKey: String?? = nil,
        featureFlagVariant: String?? = nil,
        lib: LIB?? = nil,
        libVersion: String?? = nil,
        messageID: String?? = nil,
        nodeKey: String?? = nil,
        pageviewID: String?? = nil,
        promptTemplateID: String?? = nil,
        requestID: String?? = nil,
        responseID: String?? = nil,
        schemaVersion: String?? = nil,
        sessionID: String?? = nil,
        surface: String?? = nil,
        taskType: String?? = nil,
        tenantID: String?? = nil,
        traceID: String?? = nil,
        userID: String?? = nil,
        windowID: String?? = nil
    ) -> BrowserDeadClickEventExtraJSON {
        return BrowserDeadClickEventExtraJSON(
            anonymousID: anonymousID ?? self.anonymousID,
            appVersion: appVersion ?? self.appVersion,
            conversationID: conversationID ?? self.conversationID,
            deviceID: deviceID ?? self.deviceID,
            elementsChain: elementsChain ?? self.elementsChain,
            entryPoint: entryPoint ?? self.entryPoint,
            environment: environment ?? self.environment,
            featureFlagKey: featureFlagKey ?? self.featureFlagKey,
            featureFlagVariant: featureFlagVariant ?? self.featureFlagVariant,
            lib: lib ?? self.lib,
            libVersion: libVersion ?? self.libVersion,
            messageID: messageID ?? self.messageID,
            nodeKey: nodeKey ?? self.nodeKey,
            pageviewID: pageviewID ?? self.pageviewID,
            promptTemplateID: promptTemplateID ?? self.promptTemplateID,
            requestID: requestID ?? self.requestID,
            responseID: responseID ?? self.responseID,
            schemaVersion: schemaVersion ?? self.schemaVersion,
            sessionID: sessionID ?? self.sessionID,
            surface: surface ?? self.surface,
            taskType: taskType ?? self.taskType,
            tenantID: tenantID ?? self.tenantID,
            traceID: traceID ?? self.traceID,
            userID: userID ?? self.userID,
            windowID: windowID ?? self.windowID
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - BrowserEventBatchRequest
struct BrowserEventBatchRequest: Codable {
    let batch: [BrowserEvent]
    let diagnostics: BrowserDiagnosticsEnvelope?
}

// MARK: BrowserEventBatchRequest convenience initializers and mutators

extension BrowserEventBatchRequest {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserEventBatchRequest.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        batch: [BrowserEvent]? = nil,
        diagnostics: BrowserDiagnosticsEnvelope?? = nil
    ) -> BrowserEventBatchRequest {
        return BrowserEventBatchRequest(
            batch: batch ?? self.batch,
            diagnostics: diagnostics ?? self.diagnostics
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - BrowserEvent
struct BrowserEvent: Codable {
    let deviceID: String
    let eventID: String
    let eventName: String
    let extraJSON: [String: JSONValue]
    let occurredAt: String
    let scale: String?
    let sessionID, traceID: String?
    let value: Double?

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case eventID = "event_id"
        case eventName = "event_name"
        case extraJSON = "extra_json"
        case occurredAt = "occurred_at"
        case scale
        case sessionID = "session_id"
        case traceID = "trace_id"
        case value
    }
}

// MARK: BrowserEvent convenience initializers and mutators

extension BrowserEvent {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserEvent.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        deviceID: String? = nil,
        eventID: String? = nil,
        eventName: String? = nil,
        extraJSON: [String: JSONValue]? = nil,
        occurredAt: String? = nil,
        scale: String?? = nil,
        sessionID: String?? = nil,
        traceID: String?? = nil,
        value: Double?? = nil
    ) -> BrowserEvent {
        return BrowserEvent(
            deviceID: deviceID ?? self.deviceID,
            eventID: eventID ?? self.eventID,
            eventName: eventName ?? self.eventName,
            extraJSON: extraJSON ?? self.extraJSON,
            occurredAt: occurredAt ?? self.occurredAt,
            scale: scale ?? self.scale,
            sessionID: sessionID ?? self.sessionID,
            traceID: traceID ?? self.traceID,
            value: value ?? self.value
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum JSONValue: Codable {
    case bool(Bool)
    case double(Double)
    case string(String)
    case unionArray([JSONValueElement])
    case unionMap([String: JSONValueElement])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Bool.self) {
            self = .bool(x)
            return
        }
        if let x = try? container.decode([JSONValueElement].self) {
            self = .unionArray(x)
            return
        }
        if let x = try? container.decode(Double.self) {
            self = .double(x)
            return
        }
        if let x = try? container.decode([String: JSONValueElement].self) {
            self = .unionMap(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        if container.decodeNil() {
            self = .null
            return
        }
        throw DecodingError.typeMismatch(JSONValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONValue"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let x):
            try container.encode(x)
        case .double(let x):
            try container.encode(x)
        case .string(let x):
            try container.encode(x)
        case .unionArray(let x):
            try container.encode(x)
        case .unionMap(let x):
            try container.encode(x)
        case .null:
            try container.encodeNil()
        }
    }
}

enum JSONValueElement: Codable {
    case bool(Bool)
    case double(Double)
    case string(String)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Bool.self) {
            self = .bool(x)
            return
        }
        if let x = try? container.decode(Double.self) {
            self = .double(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        if container.decodeNil() {
            self = .null
            return
        }
        throw DecodingError.typeMismatch(JSONValueElement.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONValueElement"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let x):
            try container.encode(x)
        case .double(let x):
            try container.encode(x)
        case .string(let x):
            try container.encode(x)
        case .null:
            try container.encodeNil()
        }
    }
}

// MARK: - BrowserDiagnosticsEnvelope
struct BrowserDiagnosticsEnvelope: Codable {
    let counters: BrowserDiagnosticCounters
    let sdkName: SDKName

    enum CodingKeys: String, CodingKey {
        case counters
        case sdkName = "sdk_name"
    }
}

// MARK: BrowserDiagnosticsEnvelope convenience initializers and mutators

extension BrowserDiagnosticsEnvelope {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserDiagnosticsEnvelope.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        counters: BrowserDiagnosticCounters? = nil,
        sdkName: SDKName? = nil
    ) -> BrowserDiagnosticsEnvelope {
        return BrowserDiagnosticsEnvelope(
            counters: counters ?? self.counters,
            sdkName: sdkName ?? self.sdkName
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - BrowserDiagnosticCounters
struct BrowserDiagnosticCounters: Codable {
    let identityPersistFailed, outboxWriteFailed, sendFailed, storageUnavailable: Int?

    enum CodingKeys: String, CodingKey {
        case identityPersistFailed = "identity_persist_failed"
        case outboxWriteFailed = "outbox_write_failed"
        case sendFailed = "send_failed"
        case storageUnavailable = "storage_unavailable"
    }
}

// MARK: BrowserDiagnosticCounters convenience initializers and mutators

extension BrowserDiagnosticCounters {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserDiagnosticCounters.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        identityPersistFailed: Int?? = nil,
        outboxWriteFailed: Int?? = nil,
        sendFailed: Int?? = nil,
        storageUnavailable: Int?? = nil
    ) -> BrowserDiagnosticCounters {
        return BrowserDiagnosticCounters(
            identityPersistFailed: identityPersistFailed ?? self.identityPersistFailed,
            outboxWriteFailed: outboxWriteFailed ?? self.outboxWriteFailed,
            sendFailed: sendFailed ?? self.sendFailed,
            storageUnavailable: storageUnavailable ?? self.storageUnavailable
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum SDKName: String, Codable {
    case browserJavascript = "browser-javascript"
}

// MARK: - BrowserEventBatchResponse
struct BrowserEventBatchResponse: Codable {
    let results: [String: BrowserEventResult]
}

// MARK: BrowserEventBatchResponse convenience initializers and mutators

extension BrowserEventBatchResponse {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserEventBatchResponse.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        results: [String: BrowserEventResult]? = nil
    ) -> BrowserEventBatchResponse {
        return BrowserEventBatchResponse(
            results: results ?? self.results
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - BrowserEventResult
struct BrowserEventResult: Codable {
    let code: BrowserEventResultCode?
    let result: BrowserEventResultStatus
}

// MARK: BrowserEventResult convenience initializers and mutators

extension BrowserEventResult {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserEventResult.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        code: BrowserEventResultCode?? = nil,
        result: BrowserEventResultStatus? = nil
    ) -> BrowserEventResult {
        return BrowserEventResult(
            code: code ?? self.code,
            result: result ?? self.result
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum BrowserEventResultCode: String, Codable {
    case invalidEvent = "invalid_event"
    case missingRequired = "missing_required"
    case reservedName = "reserved_name"
    case schemaDiscovered = "schema_discovered"
    case schemaDrift = "schema_drift"
    case schemaEnumMismatch = "schema_enum_mismatch"
    case schemaRequiredMissing = "schema_required_missing"
    case schemaTypeMismatch = "schema_type_mismatch"
    case storageUnavailable = "storage_unavailable"
}

enum BrowserEventResultStatus: String, Codable {
    case drop = "drop"
    case ok = "ok"
    case retry = "retry"
    case warning = "warning"
}

// MARK: - BrowserIngestEvent
struct BrowserIngestEvent: Codable {
    let deviceID: String
    let eventID: String
    let eventName: String
    let extraJSON: [String: JSONValue]
    let occurredAt: String
    let scale: String?
    let sessionID, traceID: String?
    /// Finite decimal with at most 38 integer digits and 12 fractional digits
    let value: Double?

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case eventID = "event_id"
        case eventName = "event_name"
        case extraJSON = "extra_json"
        case occurredAt = "occurred_at"
        case scale
        case sessionID = "session_id"
        case traceID = "trace_id"
        case value
    }
}

// MARK: BrowserIngestEvent convenience initializers and mutators

extension BrowserIngestEvent {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserIngestEvent.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        deviceID: String? = nil,
        eventID: String? = nil,
        eventName: String? = nil,
        extraJSON: [String: JSONValue]? = nil,
        occurredAt: String? = nil,
        scale: String?? = nil,
        sessionID: String?? = nil,
        traceID: String?? = nil,
        value: Double?? = nil
    ) -> BrowserIngestEvent {
        return BrowserIngestEvent(
            deviceID: deviceID ?? self.deviceID,
            eventID: eventID ?? self.eventID,
            eventName: eventName ?? self.eventName,
            extraJSON: extraJSON ?? self.extraJSON,
            occurredAt: occurredAt ?? self.occurredAt,
            scale: scale ?? self.scale,
            sessionID: sessionID ?? self.sessionID,
            traceID: traceID ?? self.traceID,
            value: value ?? self.value
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - BrowserPageleaveEvent
struct BrowserPageleaveEvent: Codable {
    let deviceID: String
    let eventID: String
    let eventName: BrowserPageleaveEventEventName
    let extraJSON: BrowserPageleaveEventExtraJSON
    let occurredAt: String
    let scale: String?
    let sessionID, traceID: String?
    let value: Double?

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case eventID = "event_id"
        case eventName = "event_name"
        case extraJSON = "extra_json"
        case occurredAt = "occurred_at"
        case scale
        case sessionID = "session_id"
        case traceID = "trace_id"
        case value
    }
}

// MARK: BrowserPageleaveEvent convenience initializers and mutators

extension BrowserPageleaveEvent {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserPageleaveEvent.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        deviceID: String? = nil,
        eventID: String? = nil,
        eventName: BrowserPageleaveEventEventName? = nil,
        extraJSON: BrowserPageleaveEventExtraJSON? = nil,
        occurredAt: String? = nil,
        scale: String?? = nil,
        sessionID: String?? = nil,
        traceID: String?? = nil,
        value: Double?? = nil
    ) -> BrowserPageleaveEvent {
        return BrowserPageleaveEvent(
            deviceID: deviceID ?? self.deviceID,
            eventID: eventID ?? self.eventID,
            eventName: eventName ?? self.eventName,
            extraJSON: extraJSON ?? self.extraJSON,
            occurredAt: occurredAt ?? self.occurredAt,
            scale: scale ?? self.scale,
            sessionID: sessionID ?? self.sessionID,
            traceID: traceID ?? self.traceID,
            value: value ?? self.value
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum BrowserPageleaveEventEventName: String, Codable {
    case pageleave = "pageleave"
}

// MARK: - BrowserPageleaveEventExtraJSON
struct BrowserPageleaveEventExtraJSON: Codable {
    let anonymousID, appVersion, conversationID: String?
    let currentURL: String
    let deviceID: String?
    let durationMS: Double?
    let entryPoint: String?
    let environment: Environment?
    let featureFlagKey, featureFlagVariant: String?
    let lastContentPercentage, lastContentY, lastScrollPercentage, lastScrollY: Double?
    let lib: LIB?
    let libVersion: String?
    let maxContentPercentage, maxContentY, maxScrollPercentage, maxScrollY: Double?
    let messageID, nodeKey, pageviewID: String?
    let pathname: String
    let promptTemplateID, requestID, responseID, schemaVersion: String?
    let sessionID, surface, taskType, tenantID: String?
    let traceID, userID, windowID: String?

    enum CodingKeys: String, CodingKey {
        case anonymousID = "$anonymous_id"
        case appVersion = "$app_version"
        case conversationID = "$conversation_id"
        case currentURL = "$current_url"
        case deviceID = "$device_id"
        case durationMS = "$duration_ms"
        case entryPoint = "$entry_point"
        case environment = "$environment"
        case featureFlagKey = "$feature_flag_key"
        case featureFlagVariant = "$feature_flag_variant"
        case lastContentPercentage = "$last_content_percentage"
        case lastContentY = "$last_content_y"
        case lastScrollPercentage = "$last_scroll_percentage"
        case lastScrollY = "$last_scroll_y"
        case lib = "$lib"
        case libVersion = "$lib_version"
        case maxContentPercentage = "$max_content_percentage"
        case maxContentY = "$max_content_y"
        case maxScrollPercentage = "$max_scroll_percentage"
        case maxScrollY = "$max_scroll_y"
        case messageID = "$message_id"
        case nodeKey = "$node_key"
        case pageviewID = "$pageview_id"
        case pathname = "$pathname"
        case promptTemplateID = "$prompt_template_id"
        case requestID = "$request_id"
        case responseID = "$response_id"
        case schemaVersion = "$schema_version"
        case sessionID = "$session_id"
        case surface = "$surface"
        case taskType = "$task_type"
        case tenantID = "$tenant_id"
        case traceID = "$trace_id"
        case userID = "$user_id"
        case windowID = "$window_id"
    }
}

// MARK: BrowserPageleaveEventExtraJSON convenience initializers and mutators

extension BrowserPageleaveEventExtraJSON {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserPageleaveEventExtraJSON.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        anonymousID: String?? = nil,
        appVersion: String?? = nil,
        conversationID: String?? = nil,
        currentURL: String? = nil,
        deviceID: String?? = nil,
        durationMS: Double?? = nil,
        entryPoint: String?? = nil,
        environment: Environment?? = nil,
        featureFlagKey: String?? = nil,
        featureFlagVariant: String?? = nil,
        lastContentPercentage: Double?? = nil,
        lastContentY: Double?? = nil,
        lastScrollPercentage: Double?? = nil,
        lastScrollY: Double?? = nil,
        lib: LIB?? = nil,
        libVersion: String?? = nil,
        maxContentPercentage: Double?? = nil,
        maxContentY: Double?? = nil,
        maxScrollPercentage: Double?? = nil,
        maxScrollY: Double?? = nil,
        messageID: String?? = nil,
        nodeKey: String?? = nil,
        pageviewID: String?? = nil,
        pathname: String? = nil,
        promptTemplateID: String?? = nil,
        requestID: String?? = nil,
        responseID: String?? = nil,
        schemaVersion: String?? = nil,
        sessionID: String?? = nil,
        surface: String?? = nil,
        taskType: String?? = nil,
        tenantID: String?? = nil,
        traceID: String?? = nil,
        userID: String?? = nil,
        windowID: String?? = nil
    ) -> BrowserPageleaveEventExtraJSON {
        return BrowserPageleaveEventExtraJSON(
            anonymousID: anonymousID ?? self.anonymousID,
            appVersion: appVersion ?? self.appVersion,
            conversationID: conversationID ?? self.conversationID,
            currentURL: currentURL ?? self.currentURL,
            deviceID: deviceID ?? self.deviceID,
            durationMS: durationMS ?? self.durationMS,
            entryPoint: entryPoint ?? self.entryPoint,
            environment: environment ?? self.environment,
            featureFlagKey: featureFlagKey ?? self.featureFlagKey,
            featureFlagVariant: featureFlagVariant ?? self.featureFlagVariant,
            lastContentPercentage: lastContentPercentage ?? self.lastContentPercentage,
            lastContentY: lastContentY ?? self.lastContentY,
            lastScrollPercentage: lastScrollPercentage ?? self.lastScrollPercentage,
            lastScrollY: lastScrollY ?? self.lastScrollY,
            lib: lib ?? self.lib,
            libVersion: libVersion ?? self.libVersion,
            maxContentPercentage: maxContentPercentage ?? self.maxContentPercentage,
            maxContentY: maxContentY ?? self.maxContentY,
            maxScrollPercentage: maxScrollPercentage ?? self.maxScrollPercentage,
            maxScrollY: maxScrollY ?? self.maxScrollY,
            messageID: messageID ?? self.messageID,
            nodeKey: nodeKey ?? self.nodeKey,
            pageviewID: pageviewID ?? self.pageviewID,
            pathname: pathname ?? self.pathname,
            promptTemplateID: promptTemplateID ?? self.promptTemplateID,
            requestID: requestID ?? self.requestID,
            responseID: responseID ?? self.responseID,
            schemaVersion: schemaVersion ?? self.schemaVersion,
            sessionID: sessionID ?? self.sessionID,
            surface: surface ?? self.surface,
            taskType: taskType ?? self.taskType,
            tenantID: tenantID ?? self.tenantID,
            traceID: traceID ?? self.traceID,
            userID: userID ?? self.userID,
            windowID: windowID ?? self.windowID
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - BrowserPageviewEvent
struct BrowserPageviewEvent: Codable {
    let deviceID: String
    let eventID: String
    let eventName: BrowserPageviewEventEventName
    let extraJSON: BrowserPageviewEventExtraJSON
    let occurredAt: String
    let scale: String?
    let sessionID, traceID: String?
    let value: Double?

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case eventID = "event_id"
        case eventName = "event_name"
        case extraJSON = "extra_json"
        case occurredAt = "occurred_at"
        case scale
        case sessionID = "session_id"
        case traceID = "trace_id"
        case value
    }
}

// MARK: BrowserPageviewEvent convenience initializers and mutators

extension BrowserPageviewEvent {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserPageviewEvent.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        deviceID: String? = nil,
        eventID: String? = nil,
        eventName: BrowserPageviewEventEventName? = nil,
        extraJSON: BrowserPageviewEventExtraJSON? = nil,
        occurredAt: String? = nil,
        scale: String?? = nil,
        sessionID: String?? = nil,
        traceID: String?? = nil,
        value: Double?? = nil
    ) -> BrowserPageviewEvent {
        return BrowserPageviewEvent(
            deviceID: deviceID ?? self.deviceID,
            eventID: eventID ?? self.eventID,
            eventName: eventName ?? self.eventName,
            extraJSON: extraJSON ?? self.extraJSON,
            occurredAt: occurredAt ?? self.occurredAt,
            scale: scale ?? self.scale,
            sessionID: sessionID ?? self.sessionID,
            traceID: traceID ?? self.traceID,
            value: value ?? self.value
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum BrowserPageviewEventEventName: String, Codable {
    case pageview = "pageview"
}

// MARK: - BrowserPageviewEventExtraJSON
struct BrowserPageviewEventExtraJSON: Codable {
    let anonymousID, appVersion, conversationID: String?
    let currentURL: String
    let deviceID, entryPoint: String?
    let environment: Environment?
    let featureFlagKey, featureFlagVariant: String?
    let lib: LIB?
    let libVersion, messageID, nodeKey, pageviewID: String?
    let pathname: String
    let promptTemplateID, referrer, requestID, responseID: String?
    let schemaVersion, sessionID, surface, taskType: String?
    let tenantID, traceID, userID, windowID: String?

    enum CodingKeys: String, CodingKey {
        case anonymousID = "$anonymous_id"
        case appVersion = "$app_version"
        case conversationID = "$conversation_id"
        case currentURL = "$current_url"
        case deviceID = "$device_id"
        case entryPoint = "$entry_point"
        case environment = "$environment"
        case featureFlagKey = "$feature_flag_key"
        case featureFlagVariant = "$feature_flag_variant"
        case lib = "$lib"
        case libVersion = "$lib_version"
        case messageID = "$message_id"
        case nodeKey = "$node_key"
        case pageviewID = "$pageview_id"
        case pathname = "$pathname"
        case promptTemplateID = "$prompt_template_id"
        case referrer = "$referrer"
        case requestID = "$request_id"
        case responseID = "$response_id"
        case schemaVersion = "$schema_version"
        case sessionID = "$session_id"
        case surface = "$surface"
        case taskType = "$task_type"
        case tenantID = "$tenant_id"
        case traceID = "$trace_id"
        case userID = "$user_id"
        case windowID = "$window_id"
    }
}

// MARK: BrowserPageviewEventExtraJSON convenience initializers and mutators

extension BrowserPageviewEventExtraJSON {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserPageviewEventExtraJSON.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        anonymousID: String?? = nil,
        appVersion: String?? = nil,
        conversationID: String?? = nil,
        currentURL: String? = nil,
        deviceID: String?? = nil,
        entryPoint: String?? = nil,
        environment: Environment?? = nil,
        featureFlagKey: String?? = nil,
        featureFlagVariant: String?? = nil,
        lib: LIB?? = nil,
        libVersion: String?? = nil,
        messageID: String?? = nil,
        nodeKey: String?? = nil,
        pageviewID: String?? = nil,
        pathname: String? = nil,
        promptTemplateID: String?? = nil,
        referrer: String?? = nil,
        requestID: String?? = nil,
        responseID: String?? = nil,
        schemaVersion: String?? = nil,
        sessionID: String?? = nil,
        surface: String?? = nil,
        taskType: String?? = nil,
        tenantID: String?? = nil,
        traceID: String?? = nil,
        userID: String?? = nil,
        windowID: String?? = nil
    ) -> BrowserPageviewEventExtraJSON {
        return BrowserPageviewEventExtraJSON(
            anonymousID: anonymousID ?? self.anonymousID,
            appVersion: appVersion ?? self.appVersion,
            conversationID: conversationID ?? self.conversationID,
            currentURL: currentURL ?? self.currentURL,
            deviceID: deviceID ?? self.deviceID,
            entryPoint: entryPoint ?? self.entryPoint,
            environment: environment ?? self.environment,
            featureFlagKey: featureFlagKey ?? self.featureFlagKey,
            featureFlagVariant: featureFlagVariant ?? self.featureFlagVariant,
            lib: lib ?? self.lib,
            libVersion: libVersion ?? self.libVersion,
            messageID: messageID ?? self.messageID,
            nodeKey: nodeKey ?? self.nodeKey,
            pageviewID: pageviewID ?? self.pageviewID,
            pathname: pathname ?? self.pathname,
            promptTemplateID: promptTemplateID ?? self.promptTemplateID,
            referrer: referrer ?? self.referrer,
            requestID: requestID ?? self.requestID,
            responseID: responseID ?? self.responseID,
            schemaVersion: schemaVersion ?? self.schemaVersion,
            sessionID: sessionID ?? self.sessionID,
            surface: surface ?? self.surface,
            taskType: taskType ?? self.taskType,
            tenantID: tenantID ?? self.tenantID,
            traceID: traceID ?? self.traceID,
            userID: userID ?? self.userID,
            windowID: windowID ?? self.windowID
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - BrowserRageclickEvent
struct BrowserRageclickEvent: Codable {
    let deviceID: String
    let eventID: String
    let eventName: BrowserRageclickEventEventName
    let extraJSON: BrowserRageclickEventExtraJSON
    let occurredAt: String
    let scale: String?
    let sessionID, traceID: String?
    let value: Double?

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case eventID = "event_id"
        case eventName = "event_name"
        case extraJSON = "extra_json"
        case occurredAt = "occurred_at"
        case scale
        case sessionID = "session_id"
        case traceID = "trace_id"
        case value
    }
}

// MARK: BrowserRageclickEvent convenience initializers and mutators

extension BrowserRageclickEvent {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserRageclickEvent.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        deviceID: String? = nil,
        eventID: String? = nil,
        eventName: BrowserRageclickEventEventName? = nil,
        extraJSON: BrowserRageclickEventExtraJSON? = nil,
        occurredAt: String? = nil,
        scale: String?? = nil,
        sessionID: String?? = nil,
        traceID: String?? = nil,
        value: Double?? = nil
    ) -> BrowserRageclickEvent {
        return BrowserRageclickEvent(
            deviceID: deviceID ?? self.deviceID,
            eventID: eventID ?? self.eventID,
            eventName: eventName ?? self.eventName,
            extraJSON: extraJSON ?? self.extraJSON,
            occurredAt: occurredAt ?? self.occurredAt,
            scale: scale ?? self.scale,
            sessionID: sessionID ?? self.sessionID,
            traceID: traceID ?? self.traceID,
            value: value ?? self.value
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum BrowserRageclickEventEventName: String, Codable {
    case interactionRageclick = "interaction_rageclick"
}

// MARK: - BrowserRageclickEventExtraJSON
struct BrowserRageclickEventExtraJSON: Codable {
    let anonymousID, appVersion: String?
    let clickCount: Double?
    let conversationID, deviceID: String?
    let elementsChain: String
    let entryPoint: String?
    let environment: Environment?
    let featureFlagKey, featureFlagVariant: String?
    let lib: LIB?
    let libVersion, messageID, nodeKey, pageviewID: String?
    let promptTemplateID, requestID, responseID, schemaVersion: String?
    let sessionID, surface, taskType, tenantID: String?
    let traceID, userID, windowID: String?

    enum CodingKeys: String, CodingKey {
        case anonymousID = "$anonymous_id"
        case appVersion = "$app_version"
        case clickCount = "$click_count"
        case conversationID = "$conversation_id"
        case deviceID = "$device_id"
        case elementsChain = "$elements_chain"
        case entryPoint = "$entry_point"
        case environment = "$environment"
        case featureFlagKey = "$feature_flag_key"
        case featureFlagVariant = "$feature_flag_variant"
        case lib = "$lib"
        case libVersion = "$lib_version"
        case messageID = "$message_id"
        case nodeKey = "$node_key"
        case pageviewID = "$pageview_id"
        case promptTemplateID = "$prompt_template_id"
        case requestID = "$request_id"
        case responseID = "$response_id"
        case schemaVersion = "$schema_version"
        case sessionID = "$session_id"
        case surface = "$surface"
        case taskType = "$task_type"
        case tenantID = "$tenant_id"
        case traceID = "$trace_id"
        case userID = "$user_id"
        case windowID = "$window_id"
    }
}

// MARK: BrowserRageclickEventExtraJSON convenience initializers and mutators

extension BrowserRageclickEventExtraJSON {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserRageclickEventExtraJSON.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        anonymousID: String?? = nil,
        appVersion: String?? = nil,
        clickCount: Double?? = nil,
        conversationID: String?? = nil,
        deviceID: String?? = nil,
        elementsChain: String? = nil,
        entryPoint: String?? = nil,
        environment: Environment?? = nil,
        featureFlagKey: String?? = nil,
        featureFlagVariant: String?? = nil,
        lib: LIB?? = nil,
        libVersion: String?? = nil,
        messageID: String?? = nil,
        nodeKey: String?? = nil,
        pageviewID: String?? = nil,
        promptTemplateID: String?? = nil,
        requestID: String?? = nil,
        responseID: String?? = nil,
        schemaVersion: String?? = nil,
        sessionID: String?? = nil,
        surface: String?? = nil,
        taskType: String?? = nil,
        tenantID: String?? = nil,
        traceID: String?? = nil,
        userID: String?? = nil,
        windowID: String?? = nil
    ) -> BrowserRageclickEventExtraJSON {
        return BrowserRageclickEventExtraJSON(
            anonymousID: anonymousID ?? self.anonymousID,
            appVersion: appVersion ?? self.appVersion,
            clickCount: clickCount ?? self.clickCount,
            conversationID: conversationID ?? self.conversationID,
            deviceID: deviceID ?? self.deviceID,
            elementsChain: elementsChain ?? self.elementsChain,
            entryPoint: entryPoint ?? self.entryPoint,
            environment: environment ?? self.environment,
            featureFlagKey: featureFlagKey ?? self.featureFlagKey,
            featureFlagVariant: featureFlagVariant ?? self.featureFlagVariant,
            lib: lib ?? self.lib,
            libVersion: libVersion ?? self.libVersion,
            messageID: messageID ?? self.messageID,
            nodeKey: nodeKey ?? self.nodeKey,
            pageviewID: pageviewID ?? self.pageviewID,
            promptTemplateID: promptTemplateID ?? self.promptTemplateID,
            requestID: requestID ?? self.requestID,
            responseID: responseID ?? self.responseID,
            schemaVersion: schemaVersion ?? self.schemaVersion,
            sessionID: sessionID ?? self.sessionID,
            surface: surface ?? self.surface,
            taskType: taskType ?? self.taskType,
            tenantID: tenantID ?? self.tenantID,
            traceID: traceID ?? self.traceID,
            userID: userID ?? self.userID,
            windowID: windowID ?? self.windowID
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - CustomEvent
struct CustomEvent: Codable {
    let deviceID: String
    let eventID: String
    let eventName: String
    let extraJSON: [String: JSONValue]
    let occurredAt: String
    let scale: String?
    let sessionID, traceID: String?
    let value: Double?

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case eventID = "event_id"
        case eventName = "event_name"
        case extraJSON = "extra_json"
        case occurredAt = "occurred_at"
        case scale
        case sessionID = "session_id"
        case traceID = "trace_id"
        case value
    }
}

// MARK: CustomEvent convenience initializers and mutators

extension CustomEvent {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(CustomEvent.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        deviceID: String? = nil,
        eventID: String? = nil,
        eventName: String? = nil,
        extraJSON: [String: JSONValue]? = nil,
        occurredAt: String? = nil,
        scale: String?? = nil,
        sessionID: String?? = nil,
        traceID: String?? = nil,
        value: Double?? = nil
    ) -> CustomEvent {
        return CustomEvent(
            deviceID: deviceID ?? self.deviceID,
            eventID: eventID ?? self.eventID,
            eventName: eventName ?? self.eventName,
            extraJSON: extraJSON ?? self.extraJSON,
            occurredAt: occurredAt ?? self.occurredAt,
            scale: scale ?? self.scale,
            sessionID: sessionID ?? self.sessionID,
            traceID: traceID ?? self.traceID,
            value: value ?? self.value
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - DeadClickProps
struct DeadClickProps: Codable {
    let elementsChain: String

    enum CodingKeys: String, CodingKey {
        case elementsChain = "$elements_chain"
    }
}

// MARK: DeadClickProps convenience initializers and mutators

extension DeadClickProps {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(DeadClickProps.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        elementsChain: String? = nil
    ) -> DeadClickProps {
        return DeadClickProps(
            elementsChain: elementsChain ?? self.elementsChain
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - DerivedTextMeta
struct DerivedTextMeta: Codable {
    let captureMode: CaptureMode
    let containsAttachment, containsCode: Bool?
    let excerpt, hash: String?
    let lengthChars: Double?
    let piiDetected: Bool?
    let sensitiveCategory: SensitiveCategory?
    let tokenBucket: TokenBucket?

    enum CodingKeys: String, CodingKey {
        case captureMode = "capture_mode"
        case containsAttachment = "contains_attachment"
        case containsCode = "contains_code"
        case excerpt, hash
        case lengthChars = "length_chars"
        case piiDetected = "pii_detected"
        case sensitiveCategory = "sensitive_category"
        case tokenBucket = "token_bucket"
    }
}

// MARK: DerivedTextMeta convenience initializers and mutators

extension DerivedTextMeta {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(DerivedTextMeta.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        captureMode: CaptureMode? = nil,
        containsAttachment: Bool?? = nil,
        containsCode: Bool?? = nil,
        excerpt: String?? = nil,
        hash: String?? = nil,
        lengthChars: Double?? = nil,
        piiDetected: Bool?? = nil,
        sensitiveCategory: SensitiveCategory?? = nil,
        tokenBucket: TokenBucket?? = nil
    ) -> DerivedTextMeta {
        return DerivedTextMeta(
            captureMode: captureMode ?? self.captureMode,
            containsAttachment: containsAttachment ?? self.containsAttachment,
            containsCode: containsCode ?? self.containsCode,
            excerpt: excerpt ?? self.excerpt,
            hash: hash ?? self.hash,
            lengthChars: lengthChars ?? self.lengthChars,
            piiDetected: piiDetected ?? self.piiDetected,
            sensitiveCategory: sensitiveCategory ?? self.sensitiveCategory,
            tokenBucket: tokenBucket ?? self.tokenBucket
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum TokenBucket: String, Codable {
    case the0 = "0"
    case the10012000 = "1001-2000"
    case the150 = "1-50"
    case the2000 = "2000+"
    case the201500 = "201-500"
    case the5011000 = "501-1000"
    case the51200 = "51-200"
}

enum MaskMode: String, Codable {
    case all = "all"
    case off = "off"
    case sensitive = "sensitive"
}

// MARK: - PageleaveProps
struct PageleaveProps: Codable {
    let currentURL: String
    let durationMS, lastContentPercentage, lastContentY, lastScrollPercentage: Double?
    let lastScrollY, maxContentPercentage, maxContentY, maxScrollPercentage: Double?
    let maxScrollY: Double?
    let pathname: String

    enum CodingKeys: String, CodingKey {
        case currentURL = "$current_url"
        case durationMS = "$duration_ms"
        case lastContentPercentage = "$last_content_percentage"
        case lastContentY = "$last_content_y"
        case lastScrollPercentage = "$last_scroll_percentage"
        case lastScrollY = "$last_scroll_y"
        case maxContentPercentage = "$max_content_percentage"
        case maxContentY = "$max_content_y"
        case maxScrollPercentage = "$max_scroll_percentage"
        case maxScrollY = "$max_scroll_y"
        case pathname = "$pathname"
    }
}

// MARK: PageleaveProps convenience initializers and mutators

extension PageleaveProps {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PageleaveProps.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        currentURL: String? = nil,
        durationMS: Double?? = nil,
        lastContentPercentage: Double?? = nil,
        lastContentY: Double?? = nil,
        lastScrollPercentage: Double?? = nil,
        lastScrollY: Double?? = nil,
        maxContentPercentage: Double?? = nil,
        maxContentY: Double?? = nil,
        maxScrollPercentage: Double?? = nil,
        maxScrollY: Double?? = nil,
        pathname: String? = nil
    ) -> PageleaveProps {
        return PageleaveProps(
            currentURL: currentURL ?? self.currentURL,
            durationMS: durationMS ?? self.durationMS,
            lastContentPercentage: lastContentPercentage ?? self.lastContentPercentage,
            lastContentY: lastContentY ?? self.lastContentY,
            lastScrollPercentage: lastScrollPercentage ?? self.lastScrollPercentage,
            lastScrollY: lastScrollY ?? self.lastScrollY,
            maxContentPercentage: maxContentPercentage ?? self.maxContentPercentage,
            maxContentY: maxContentY ?? self.maxContentY,
            maxScrollPercentage: maxScrollPercentage ?? self.maxScrollPercentage,
            maxScrollY: maxScrollY ?? self.maxScrollY,
            pathname: pathname ?? self.pathname
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - PageviewProps
struct PageviewProps: Codable {
    let currentURL, pathname: String
    let referrer: String?

    enum CodingKeys: String, CodingKey {
        case currentURL = "$current_url"
        case pathname = "$pathname"
        case referrer = "$referrer"
    }
}

// MARK: PageviewProps convenience initializers and mutators

extension PageviewProps {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PageviewProps.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        currentURL: String? = nil,
        pathname: String? = nil,
        referrer: String?? = nil
    ) -> PageviewProps {
        return PageviewProps(
            currentURL: currentURL ?? self.currentURL,
            pathname: pathname ?? self.pathname,
            referrer: referrer ?? self.referrer
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - RageclickProps
struct RageclickProps: Codable {
    let clickCount: Double?
    let elementsChain: String

    enum CodingKeys: String, CodingKey {
        case clickCount = "$click_count"
        case elementsChain = "$elements_chain"
    }
}

// MARK: RageclickProps convenience initializers and mutators

extension RageclickProps {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(RageclickProps.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        clickCount: Double?? = nil,
        elementsChain: String? = nil
    ) -> RageclickProps {
        return RageclickProps(
            clickCount: clickCount ?? self.clickCount,
            elementsChain: elementsChain ?? self.elementsChain
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - ScrollDepthProps
struct ScrollDepthProps: Codable {
    let lastContentPercentage, lastContentY, lastScrollPercentage, lastScrollY: Double?
    let maxContentPercentage, maxContentY, maxScrollPercentage, maxScrollY: Double?

    enum CodingKeys: String, CodingKey {
        case lastContentPercentage = "$last_content_percentage"
        case lastContentY = "$last_content_y"
        case lastScrollPercentage = "$last_scroll_percentage"
        case lastScrollY = "$last_scroll_y"
        case maxContentPercentage = "$max_content_percentage"
        case maxContentY = "$max_content_y"
        case maxScrollPercentage = "$max_scroll_percentage"
        case maxScrollY = "$max_scroll_y"
    }
}

// MARK: ScrollDepthProps convenience initializers and mutators

extension ScrollDepthProps {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(ScrollDepthProps.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        lastContentPercentage: Double?? = nil,
        lastContentY: Double?? = nil,
        lastScrollPercentage: Double?? = nil,
        lastScrollY: Double?? = nil,
        maxContentPercentage: Double?? = nil,
        maxContentY: Double?? = nil,
        maxScrollPercentage: Double?? = nil,
        maxScrollY: Double?? = nil
    ) -> ScrollDepthProps {
        return ScrollDepthProps(
            lastContentPercentage: lastContentPercentage ?? self.lastContentPercentage,
            lastContentY: lastContentY ?? self.lastContentY,
            lastScrollPercentage: lastScrollPercentage ?? self.lastScrollPercentage,
            lastScrollY: lastScrollY ?? self.lastScrollY,
            maxContentPercentage: maxContentPercentage ?? self.maxContentPercentage,
            maxContentY: maxContentY ?? self.maxContentY,
            maxScrollPercentage: maxScrollPercentage ?? self.maxScrollPercentage,
            maxScrollY: maxScrollY ?? self.maxScrollY
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Helper functions for creating encoders and decoders

func newJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        decoder.dateDecodingStrategy = .iso8601
    }
    return decoder
}

func newJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        encoder.dateEncodingStrategy = .iso8601
    }
    return encoder
}
