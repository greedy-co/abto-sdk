// GENERATED from ABTO's public event contract — DO NOT EDIT.
// Regenerate from the canonical public schema before release.

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let events = try Events(json)

import Foundation

// MARK: - Events
struct Events: Codable {
    let browserAIPromptSubmittedEvent: BrowserAIPromptSubmittedEvent?
    let browserAIResponseInteractedEvent: BrowserAIResponseInteractedEvent?
    let browserAIResponseRenderedEvent: BrowserAIResponseRenderedEvent?
    let browserAutocaptureEvent: BrowserAutocaptureEvent?
    let browserDeadClickEvent: BrowserDeadClickEvent?
    let browserPageleaveEvent: BrowserPageleaveEvent?
    let browserPageviewEvent: BrowserPageviewEvent?
    let browserRageclickEvent: BrowserRageclickEvent?
    let customEvent: CustomEvent?
    let derivedTextMeta: DerivedTextMeta?
    let maskMode: MaskMode?
    let scrollDepthProps: ScrollDepthProps?
    let tokenBucket: TokenBucket?

    enum CodingKeys: String, CodingKey {
        case browserAIPromptSubmittedEvent = "BrowserAiPromptSubmittedEvent"
        case browserAIResponseInteractedEvent = "BrowserAiResponseInteractedEvent"
        case browserAIResponseRenderedEvent = "BrowserAiResponseRenderedEvent"
        case browserAutocaptureEvent = "BrowserAutocaptureEvent"
        case browserDeadClickEvent = "BrowserDeadClickEvent"
        case browserPageleaveEvent = "BrowserPageleaveEvent"
        case browserPageviewEvent = "BrowserPageviewEvent"
        case browserRageclickEvent = "BrowserRageclickEvent"
        case customEvent = "CustomEvent"
        case derivedTextMeta = "DerivedTextMeta"
        case maskMode = "MaskMode"
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
        browserAIPromptSubmittedEvent: BrowserAIPromptSubmittedEvent?? = nil,
        browserAIResponseInteractedEvent: BrowserAIResponseInteractedEvent?? = nil,
        browserAIResponseRenderedEvent: BrowserAIResponseRenderedEvent?? = nil,
        browserAutocaptureEvent: BrowserAutocaptureEvent?? = nil,
        browserDeadClickEvent: BrowserDeadClickEvent?? = nil,
        browserPageleaveEvent: BrowserPageleaveEvent?? = nil,
        browserPageviewEvent: BrowserPageviewEvent?? = nil,
        browserRageclickEvent: BrowserRageclickEvent?? = nil,
        customEvent: CustomEvent?? = nil,
        derivedTextMeta: DerivedTextMeta?? = nil,
        maskMode: MaskMode?? = nil,
        scrollDepthProps: ScrollDepthProps?? = nil,
        tokenBucket: TokenBucket?? = nil
    ) -> Events {
        return Events(
            browserAIPromptSubmittedEvent: browserAIPromptSubmittedEvent ?? self.browserAIPromptSubmittedEvent,
            browserAIResponseInteractedEvent: browserAIResponseInteractedEvent ?? self.browserAIResponseInteractedEvent,
            browserAIResponseRenderedEvent: browserAIResponseRenderedEvent ?? self.browserAIResponseRenderedEvent,
            browserAutocaptureEvent: browserAutocaptureEvent ?? self.browserAutocaptureEvent,
            browserDeadClickEvent: browserDeadClickEvent ?? self.browserDeadClickEvent,
            browserPageleaveEvent: browserPageleaveEvent ?? self.browserPageleaveEvent,
            browserPageviewEvent: browserPageviewEvent ?? self.browserPageviewEvent,
            browserRageclickEvent: browserRageclickEvent ?? self.browserRageclickEvent,
            customEvent: customEvent ?? self.customEvent,
            derivedTextMeta: derivedTextMeta ?? self.derivedTextMeta,
            maskMode: maskMode ?? self.maskMode,
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

// MARK: - BrowserAIPromptSubmittedEvent
struct BrowserAIPromptSubmittedEvent: Codable {
    let distinctID: String
    let event: BrowserAIPromptSubmittedEventEvent
    let properties: BrowserAIPromptSubmittedEventProperties
    let browserAIPromptSubmittedEventSet, setOnce: [String: JSONValue]?
    let timestamp, uuid: String

    enum CodingKeys: String, CodingKey {
        case distinctID = "distinct_id"
        case event, properties
        case browserAIPromptSubmittedEventSet = "set"
        case setOnce = "set_once"
        case timestamp, uuid
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
        distinctID: String? = nil,
        event: BrowserAIPromptSubmittedEventEvent? = nil,
        properties: BrowserAIPromptSubmittedEventProperties? = nil,
        browserAIPromptSubmittedEventSet: [String: JSONValue]?? = nil,
        setOnce: [String: JSONValue]?? = nil,
        timestamp: String? = nil,
        uuid: String? = nil
    ) -> BrowserAIPromptSubmittedEvent {
        return BrowserAIPromptSubmittedEvent(
            distinctID: distinctID ?? self.distinctID,
            event: event ?? self.event,
            properties: properties ?? self.properties,
            browserAIPromptSubmittedEventSet: browserAIPromptSubmittedEventSet ?? self.browserAIPromptSubmittedEventSet,
            setOnce: setOnce ?? self.setOnce,
            timestamp: timestamp ?? self.timestamp,
            uuid: uuid ?? self.uuid
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

enum BrowserAIPromptSubmittedEventEvent: String, Codable {
    case aiPromptSubmitted = "$ai_prompt_submitted"
}

// MARK: - BrowserAIPromptSubmittedEventProperties
struct BrowserAIPromptSubmittedEventProperties: Codable {
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

// MARK: BrowserAIPromptSubmittedEventProperties convenience initializers and mutators

extension BrowserAIPromptSubmittedEventProperties {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserAIPromptSubmittedEventProperties.self, from: data)
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
    ) -> BrowserAIPromptSubmittedEventProperties {
        return BrowserAIPromptSubmittedEventProperties(
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

enum CaptureMode: String, Codable {
    case full = "full"
    case hash = "hash"
    case metadataOnly = "metadata_only"
    case off = "off"
}

enum Environment: String, Codable {
    case development = "development"
    case production = "production"
}

enum LIB: String, Codable {
    case web = "web"
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

// MARK: - BrowserAIResponseInteractedEvent
struct BrowserAIResponseInteractedEvent: Codable {
    let distinctID: String
    let event: BrowserAIResponseInteractedEventEvent
    let properties: BrowserAIResponseInteractedEventProperties
    let browserAIResponseInteractedEventSet, setOnce: [String: JSONValue]?
    let timestamp, uuid: String

    enum CodingKeys: String, CodingKey {
        case distinctID = "distinct_id"
        case event, properties
        case browserAIResponseInteractedEventSet = "set"
        case setOnce = "set_once"
        case timestamp, uuid
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
        distinctID: String? = nil,
        event: BrowserAIResponseInteractedEventEvent? = nil,
        properties: BrowserAIResponseInteractedEventProperties? = nil,
        browserAIResponseInteractedEventSet: [String: JSONValue]?? = nil,
        setOnce: [String: JSONValue]?? = nil,
        timestamp: String? = nil,
        uuid: String? = nil
    ) -> BrowserAIResponseInteractedEvent {
        return BrowserAIResponseInteractedEvent(
            distinctID: distinctID ?? self.distinctID,
            event: event ?? self.event,
            properties: properties ?? self.properties,
            browserAIResponseInteractedEventSet: browserAIResponseInteractedEventSet ?? self.browserAIResponseInteractedEventSet,
            setOnce: setOnce ?? self.setOnce,
            timestamp: timestamp ?? self.timestamp,
            uuid: uuid ?? self.uuid
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum BrowserAIResponseInteractedEventEvent: String, Codable {
    case aiResponseInteracted = "$ai_response_interacted"
}

// MARK: - BrowserAIResponseInteractedEventProperties
struct BrowserAIResponseInteractedEventProperties: Codable {
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

// MARK: BrowserAIResponseInteractedEventProperties convenience initializers and mutators

extension BrowserAIResponseInteractedEventProperties {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserAIResponseInteractedEventProperties.self, from: data)
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
    ) -> BrowserAIResponseInteractedEventProperties {
        return BrowserAIResponseInteractedEventProperties(
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

// MARK: - BrowserAIResponseRenderedEvent
struct BrowserAIResponseRenderedEvent: Codable {
    let distinctID: String
    let event: BrowserAIResponseRenderedEventEvent
    let properties: BrowserAIResponseRenderedEventProperties
    let browserAIResponseRenderedEventSet, setOnce: [String: JSONValue]?
    let timestamp, uuid: String

    enum CodingKeys: String, CodingKey {
        case distinctID = "distinct_id"
        case event, properties
        case browserAIResponseRenderedEventSet = "set"
        case setOnce = "set_once"
        case timestamp, uuid
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
        distinctID: String? = nil,
        event: BrowserAIResponseRenderedEventEvent? = nil,
        properties: BrowserAIResponseRenderedEventProperties? = nil,
        browserAIResponseRenderedEventSet: [String: JSONValue]?? = nil,
        setOnce: [String: JSONValue]?? = nil,
        timestamp: String? = nil,
        uuid: String? = nil
    ) -> BrowserAIResponseRenderedEvent {
        return BrowserAIResponseRenderedEvent(
            distinctID: distinctID ?? self.distinctID,
            event: event ?? self.event,
            properties: properties ?? self.properties,
            browserAIResponseRenderedEventSet: browserAIResponseRenderedEventSet ?? self.browserAIResponseRenderedEventSet,
            setOnce: setOnce ?? self.setOnce,
            timestamp: timestamp ?? self.timestamp,
            uuid: uuid ?? self.uuid
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum BrowserAIResponseRenderedEventEvent: String, Codable {
    case aiResponseRendered = "$ai_response_rendered"
}

// MARK: - BrowserAIResponseRenderedEventProperties
struct BrowserAIResponseRenderedEventProperties: Codable {
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

// MARK: BrowserAIResponseRenderedEventProperties convenience initializers and mutators

extension BrowserAIResponseRenderedEventProperties {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserAIResponseRenderedEventProperties.self, from: data)
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
    ) -> BrowserAIResponseRenderedEventProperties {
        return BrowserAIResponseRenderedEventProperties(
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
    let distinctID: String
    let event: BrowserAutocaptureEventEvent
    let properties: BrowserAutocaptureEventProperties
    let browserAutocaptureEventSet, setOnce: [String: JSONValue]?
    let timestamp, uuid: String

    enum CodingKeys: String, CodingKey {
        case distinctID = "distinct_id"
        case event, properties
        case browserAutocaptureEventSet = "set"
        case setOnce = "set_once"
        case timestamp, uuid
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
        distinctID: String? = nil,
        event: BrowserAutocaptureEventEvent? = nil,
        properties: BrowserAutocaptureEventProperties? = nil,
        browserAutocaptureEventSet: [String: JSONValue]?? = nil,
        setOnce: [String: JSONValue]?? = nil,
        timestamp: String? = nil,
        uuid: String? = nil
    ) -> BrowserAutocaptureEvent {
        return BrowserAutocaptureEvent(
            distinctID: distinctID ?? self.distinctID,
            event: event ?? self.event,
            properties: properties ?? self.properties,
            browserAutocaptureEventSet: browserAutocaptureEventSet ?? self.browserAutocaptureEventSet,
            setOnce: setOnce ?? self.setOnce,
            timestamp: timestamp ?? self.timestamp,
            uuid: uuid ?? self.uuid
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum BrowserAutocaptureEventEvent: String, Codable {
    case autocapture = "$autocapture"
}

// MARK: - BrowserAutocaptureEventProperties
struct BrowserAutocaptureEventProperties: Codable {
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

// MARK: BrowserAutocaptureEventProperties convenience initializers and mutators

extension BrowserAutocaptureEventProperties {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserAutocaptureEventProperties.self, from: data)
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
    ) -> BrowserAutocaptureEventProperties {
        return BrowserAutocaptureEventProperties(
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

enum AutocaptureEventType: String, Codable {
    case change = "change"
    case click = "click"
    case copy = "copy"
    case submit = "submit"
}

// MARK: - BrowserDeadClickEvent
struct BrowserDeadClickEvent: Codable {
    let distinctID: String
    let event: BrowserDeadClickEventEvent
    let properties: BrowserDeadClickEventProperties
    let browserDeadClickEventSet, setOnce: [String: JSONValue]?
    let timestamp, uuid: String

    enum CodingKeys: String, CodingKey {
        case distinctID = "distinct_id"
        case event, properties
        case browserDeadClickEventSet = "set"
        case setOnce = "set_once"
        case timestamp, uuid
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
        distinctID: String? = nil,
        event: BrowserDeadClickEventEvent? = nil,
        properties: BrowserDeadClickEventProperties? = nil,
        browserDeadClickEventSet: [String: JSONValue]?? = nil,
        setOnce: [String: JSONValue]?? = nil,
        timestamp: String? = nil,
        uuid: String? = nil
    ) -> BrowserDeadClickEvent {
        return BrowserDeadClickEvent(
            distinctID: distinctID ?? self.distinctID,
            event: event ?? self.event,
            properties: properties ?? self.properties,
            browserDeadClickEventSet: browserDeadClickEventSet ?? self.browserDeadClickEventSet,
            setOnce: setOnce ?? self.setOnce,
            timestamp: timestamp ?? self.timestamp,
            uuid: uuid ?? self.uuid
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum BrowserDeadClickEventEvent: String, Codable {
    case deadClick = "$dead_click"
}

// MARK: - BrowserDeadClickEventProperties
struct BrowserDeadClickEventProperties: Codable {
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

// MARK: BrowserDeadClickEventProperties convenience initializers and mutators

extension BrowserDeadClickEventProperties {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserDeadClickEventProperties.self, from: data)
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
    ) -> BrowserDeadClickEventProperties {
        return BrowserDeadClickEventProperties(
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

// MARK: - BrowserPageleaveEvent
struct BrowserPageleaveEvent: Codable {
    let distinctID: String
    let event: BrowserPageleaveEventEvent
    let properties: BrowserPageleaveEventProperties
    let browserPageleaveEventSet, setOnce: [String: JSONValue]?
    let timestamp, uuid: String

    enum CodingKeys: String, CodingKey {
        case distinctID = "distinct_id"
        case event, properties
        case browserPageleaveEventSet = "set"
        case setOnce = "set_once"
        case timestamp, uuid
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
        distinctID: String? = nil,
        event: BrowserPageleaveEventEvent? = nil,
        properties: BrowserPageleaveEventProperties? = nil,
        browserPageleaveEventSet: [String: JSONValue]?? = nil,
        setOnce: [String: JSONValue]?? = nil,
        timestamp: String? = nil,
        uuid: String? = nil
    ) -> BrowserPageleaveEvent {
        return BrowserPageleaveEvent(
            distinctID: distinctID ?? self.distinctID,
            event: event ?? self.event,
            properties: properties ?? self.properties,
            browserPageleaveEventSet: browserPageleaveEventSet ?? self.browserPageleaveEventSet,
            setOnce: setOnce ?? self.setOnce,
            timestamp: timestamp ?? self.timestamp,
            uuid: uuid ?? self.uuid
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum BrowserPageleaveEventEvent: String, Codable {
    case pageleave = "$pageleave"
}

// MARK: - BrowserPageleaveEventProperties
struct BrowserPageleaveEventProperties: Codable {
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

// MARK: BrowserPageleaveEventProperties convenience initializers and mutators

extension BrowserPageleaveEventProperties {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserPageleaveEventProperties.self, from: data)
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
    ) -> BrowserPageleaveEventProperties {
        return BrowserPageleaveEventProperties(
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
    let distinctID: String
    let event: BrowserPageviewEventEvent
    let properties: BrowserPageviewEventProperties
    let browserPageviewEventSet, setOnce: [String: JSONValue]?
    let timestamp, uuid: String

    enum CodingKeys: String, CodingKey {
        case distinctID = "distinct_id"
        case event, properties
        case browserPageviewEventSet = "set"
        case setOnce = "set_once"
        case timestamp, uuid
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
        distinctID: String? = nil,
        event: BrowserPageviewEventEvent? = nil,
        properties: BrowserPageviewEventProperties? = nil,
        browserPageviewEventSet: [String: JSONValue]?? = nil,
        setOnce: [String: JSONValue]?? = nil,
        timestamp: String? = nil,
        uuid: String? = nil
    ) -> BrowserPageviewEvent {
        return BrowserPageviewEvent(
            distinctID: distinctID ?? self.distinctID,
            event: event ?? self.event,
            properties: properties ?? self.properties,
            browserPageviewEventSet: browserPageviewEventSet ?? self.browserPageviewEventSet,
            setOnce: setOnce ?? self.setOnce,
            timestamp: timestamp ?? self.timestamp,
            uuid: uuid ?? self.uuid
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum BrowserPageviewEventEvent: String, Codable {
    case pageview = "$pageview"
}

// MARK: - BrowserPageviewEventProperties
struct BrowserPageviewEventProperties: Codable {
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

// MARK: BrowserPageviewEventProperties convenience initializers and mutators

extension BrowserPageviewEventProperties {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserPageviewEventProperties.self, from: data)
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
    ) -> BrowserPageviewEventProperties {
        return BrowserPageviewEventProperties(
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
    let distinctID: String
    let event: BrowserRageclickEventEvent
    let properties: BrowserRageclickEventProperties
    let browserRageclickEventSet, setOnce: [String: JSONValue]?
    let timestamp, uuid: String

    enum CodingKeys: String, CodingKey {
        case distinctID = "distinct_id"
        case event, properties
        case browserRageclickEventSet = "set"
        case setOnce = "set_once"
        case timestamp, uuid
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
        distinctID: String? = nil,
        event: BrowserRageclickEventEvent? = nil,
        properties: BrowserRageclickEventProperties? = nil,
        browserRageclickEventSet: [String: JSONValue]?? = nil,
        setOnce: [String: JSONValue]?? = nil,
        timestamp: String? = nil,
        uuid: String? = nil
    ) -> BrowserRageclickEvent {
        return BrowserRageclickEvent(
            distinctID: distinctID ?? self.distinctID,
            event: event ?? self.event,
            properties: properties ?? self.properties,
            browserRageclickEventSet: browserRageclickEventSet ?? self.browserRageclickEventSet,
            setOnce: setOnce ?? self.setOnce,
            timestamp: timestamp ?? self.timestamp,
            uuid: uuid ?? self.uuid
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum BrowserRageclickEventEvent: String, Codable {
    case rageclick = "$rageclick"
}

// MARK: - BrowserRageclickEventProperties
struct BrowserRageclickEventProperties: Codable {
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

// MARK: BrowserRageclickEventProperties convenience initializers and mutators

extension BrowserRageclickEventProperties {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserRageclickEventProperties.self, from: data)
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
    ) -> BrowserRageclickEventProperties {
        return BrowserRageclickEventProperties(
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
    let distinctID: String
    let event: String
    let properties: [String: JSONValue]
    let customEventSet, setOnce: [String: JSONValue]?
    let timestamp, uuid: String

    enum CodingKeys: String, CodingKey {
        case distinctID = "distinct_id"
        case event, properties
        case customEventSet = "set"
        case setOnce = "set_once"
        case timestamp, uuid
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
        distinctID: String? = nil,
        event: String? = nil,
        properties: [String: JSONValue]? = nil,
        customEventSet: [String: JSONValue]?? = nil,
        setOnce: [String: JSONValue]?? = nil,
        timestamp: String? = nil,
        uuid: String? = nil
    ) -> CustomEvent {
        return CustomEvent(
            distinctID: distinctID ?? self.distinctID,
            event: event ?? self.event,
            properties: properties ?? self.properties,
            customEventSet: customEventSet ?? self.customEventSet,
            setOnce: setOnce ?? self.setOnce,
            timestamp: timestamp ?? self.timestamp,
            uuid: uuid ?? self.uuid
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
