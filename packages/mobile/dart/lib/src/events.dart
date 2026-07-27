// GENERATED FILE — DO NOT EDIT.

// To parse this JSON data, do
//
//     final events = eventsFromJson(jsonString);

import 'dart:convert';

Events eventsFromJson(String str) => Events.fromJson(json.decode(str));

String eventsToJson(Events data) => json.encode(data.toJson());

class Events {
    AiPromptSubmittedProps? aiPromptSubmittedProps;
    AiResponseInteractedProps? aiResponseInteractedProps;
    AiResponseRenderedProps? aiResponseRenderedProps;
    AutocaptureProps? autocaptureProps;
    BrowserAiPromptSubmittedEvent? browserAiPromptSubmittedEvent;
    BrowserAiResponseInteractedEvent? browserAiResponseInteractedEvent;
    BrowserAiResponseRenderedEvent? browserAiResponseRenderedEvent;
    BrowserAutocaptureEvent? browserAutocaptureEvent;
    BrowserContextProperties? browserContextProperties;
    BrowserDeadClickEvent? browserDeadClickEvent;
    BrowserEventBatchRequest? browserEventBatchRequest;
    BrowserEventBatchResponse? browserEventBatchResponse;
    BrowserEventResult? browserEventResult;
    BrowserEventResultCode? browserEventResultCode;
    BrowserEventResultStatus? browserEventResultStatus;
    BrowserIngestEvent? browserIngestEvent;
    BrowserPageleaveEvent? browserPageleaveEvent;
    BrowserPageviewEvent? browserPageviewEvent;
    BrowserRageclickEvent? browserRageclickEvent;
    CustomEvent? customEvent;
    DeadClickProps? deadClickProps;
    DerivedTextMeta? derivedTextMeta;
    MaskMode? maskMode;
    double? metricValue;
    PageleaveProps? pageleaveProps;
    PageviewProps? pageviewProps;
    RageclickProps? rageclickProps;
    ScrollDepthProps? scrollDepthProps;
    TokenBucket? tokenBucket;

    Events({
        this.aiPromptSubmittedProps,
        this.aiResponseInteractedProps,
        this.aiResponseRenderedProps,
        this.autocaptureProps,
        this.browserAiPromptSubmittedEvent,
        this.browserAiResponseInteractedEvent,
        this.browserAiResponseRenderedEvent,
        this.browserAutocaptureEvent,
        this.browserContextProperties,
        this.browserDeadClickEvent,
        this.browserEventBatchRequest,
        this.browserEventBatchResponse,
        this.browserEventResult,
        this.browserEventResultCode,
        this.browserEventResultStatus,
        this.browserIngestEvent,
        this.browserPageleaveEvent,
        this.browserPageviewEvent,
        this.browserRageclickEvent,
        this.customEvent,
        this.deadClickProps,
        this.derivedTextMeta,
        this.maskMode,
        this.metricValue,
        this.pageleaveProps,
        this.pageviewProps,
        this.rageclickProps,
        this.scrollDepthProps,
        this.tokenBucket,
    });

    factory Events.fromJson(Map<String, dynamic> json) => Events(
        aiPromptSubmittedProps: json["AiPromptSubmittedProps"] == null ? null : AiPromptSubmittedProps.fromJson(json["AiPromptSubmittedProps"]),
        aiResponseInteractedProps: json["AiResponseInteractedProps"] == null ? null : AiResponseInteractedProps.fromJson(json["AiResponseInteractedProps"]),
        aiResponseRenderedProps: json["AiResponseRenderedProps"] == null ? null : AiResponseRenderedProps.fromJson(json["AiResponseRenderedProps"]),
        autocaptureProps: json["AutocaptureProps"] == null ? null : AutocaptureProps.fromJson(json["AutocaptureProps"]),
        browserAiPromptSubmittedEvent: json["BrowserAiPromptSubmittedEvent"] == null ? null : BrowserAiPromptSubmittedEvent.fromJson(json["BrowserAiPromptSubmittedEvent"]),
        browserAiResponseInteractedEvent: json["BrowserAiResponseInteractedEvent"] == null ? null : BrowserAiResponseInteractedEvent.fromJson(json["BrowserAiResponseInteractedEvent"]),
        browserAiResponseRenderedEvent: json["BrowserAiResponseRenderedEvent"] == null ? null : BrowserAiResponseRenderedEvent.fromJson(json["BrowserAiResponseRenderedEvent"]),
        browserAutocaptureEvent: json["BrowserAutocaptureEvent"] == null ? null : BrowserAutocaptureEvent.fromJson(json["BrowserAutocaptureEvent"]),
        browserContextProperties: json["BrowserContextProperties"] == null ? null : BrowserContextProperties.fromJson(json["BrowserContextProperties"]),
        browserDeadClickEvent: json["BrowserDeadClickEvent"] == null ? null : BrowserDeadClickEvent.fromJson(json["BrowserDeadClickEvent"]),
        browserEventBatchRequest: json["BrowserEventBatchRequest"] == null ? null : BrowserEventBatchRequest.fromJson(json["BrowserEventBatchRequest"]),
        browserEventBatchResponse: json["BrowserEventBatchResponse"] == null ? null : BrowserEventBatchResponse.fromJson(json["BrowserEventBatchResponse"]),
        browserEventResult: json["BrowserEventResult"] == null ? null : BrowserEventResult.fromJson(json["BrowserEventResult"]),
        browserEventResultCode: browserEventResultCodeValues.map[json["BrowserEventResultCode"]],
        browserEventResultStatus: browserEventResultStatusValues.map[json["BrowserEventResultStatus"]],
        browserIngestEvent: json["BrowserIngestEvent"] == null ? null : BrowserIngestEvent.fromJson(json["BrowserIngestEvent"]),
        browserPageleaveEvent: json["BrowserPageleaveEvent"] == null ? null : BrowserPageleaveEvent.fromJson(json["BrowserPageleaveEvent"]),
        browserPageviewEvent: json["BrowserPageviewEvent"] == null ? null : BrowserPageviewEvent.fromJson(json["BrowserPageviewEvent"]),
        browserRageclickEvent: json["BrowserRageclickEvent"] == null ? null : BrowserRageclickEvent.fromJson(json["BrowserRageclickEvent"]),
        customEvent: json["CustomEvent"] == null ? null : CustomEvent.fromJson(json["CustomEvent"]),
        deadClickProps: json["DeadClickProps"] == null ? null : DeadClickProps.fromJson(json["DeadClickProps"]),
        derivedTextMeta: json["DerivedTextMeta"] == null ? null : DerivedTextMeta.fromJson(json["DerivedTextMeta"]),
        maskMode: maskModeValues.map[json["MaskMode"]],
        metricValue: json["MetricValue"]?.toDouble(),
        pageleaveProps: json["PageleaveProps"] == null ? null : PageleaveProps.fromJson(json["PageleaveProps"]),
        pageviewProps: json["PageviewProps"] == null ? null : PageviewProps.fromJson(json["PageviewProps"]),
        rageclickProps: json["RageclickProps"] == null ? null : RageclickProps.fromJson(json["RageclickProps"]),
        scrollDepthProps: json["ScrollDepthProps"] == null ? null : ScrollDepthProps.fromJson(json["ScrollDepthProps"]),
        tokenBucket: tokenBucketValues.map[json["TokenBucket"]],
    );

    Map<String, dynamic> toJson() => {
        "AiPromptSubmittedProps": aiPromptSubmittedProps?.toJson(),
        "AiResponseInteractedProps": aiResponseInteractedProps?.toJson(),
        "AiResponseRenderedProps": aiResponseRenderedProps?.toJson(),
        "AutocaptureProps": autocaptureProps?.toJson(),
        "BrowserAiPromptSubmittedEvent": browserAiPromptSubmittedEvent?.toJson(),
        "BrowserAiResponseInteractedEvent": browserAiResponseInteractedEvent?.toJson(),
        "BrowserAiResponseRenderedEvent": browserAiResponseRenderedEvent?.toJson(),
        "BrowserAutocaptureEvent": browserAutocaptureEvent?.toJson(),
        "BrowserContextProperties": browserContextProperties?.toJson(),
        "BrowserDeadClickEvent": browserDeadClickEvent?.toJson(),
        "BrowserEventBatchRequest": browserEventBatchRequest?.toJson(),
        "BrowserEventBatchResponse": browserEventBatchResponse?.toJson(),
        "BrowserEventResult": browserEventResult?.toJson(),
        "BrowserEventResultCode": browserEventResultCodeValues.reverse[browserEventResultCode],
        "BrowserEventResultStatus": browserEventResultStatusValues.reverse[browserEventResultStatus],
        "BrowserIngestEvent": browserIngestEvent?.toJson(),
        "BrowserPageleaveEvent": browserPageleaveEvent?.toJson(),
        "BrowserPageviewEvent": browserPageviewEvent?.toJson(),
        "BrowserRageclickEvent": browserRageclickEvent?.toJson(),
        "CustomEvent": customEvent?.toJson(),
        "DeadClickProps": deadClickProps?.toJson(),
        "DerivedTextMeta": derivedTextMeta?.toJson(),
        "MaskMode": maskModeValues.reverse[maskMode],
        "MetricValue": metricValue,
        "PageleaveProps": pageleaveProps?.toJson(),
        "PageviewProps": pageviewProps?.toJson(),
        "RageclickProps": rageclickProps?.toJson(),
        "ScrollDepthProps": scrollDepthProps?.toJson(),
        "TokenBucket": tokenBucketValues.reverse[tokenBucket],
    };
}

class AiPromptSubmittedProps {
    CaptureMode captureMode;
    bool? containsAttachment;
    bool? containsCode;
    String? language;
    bool? piiDetected;
    String? promptHash;
    double? promptLengthChars;
    String? promptText;
    double? promptTokensEstimated;
    dynamic sensitiveCategory;

    AiPromptSubmittedProps({
        required this.captureMode,
        this.containsAttachment,
        this.containsCode,
        this.language,
        this.piiDetected,
        this.promptHash,
        this.promptLengthChars,
        this.promptText,
        this.promptTokensEstimated,
        this.sensitiveCategory,
    });

    factory AiPromptSubmittedProps.fromJson(Map<String, dynamic> json) => AiPromptSubmittedProps(
        captureMode: captureModeValues.map[json["\u0024capture_mode"]]!,
        containsAttachment: json["\u0024contains_attachment"],
        containsCode: json["\u0024contains_code"],
        language: json["\u0024language"],
        piiDetected: json["\u0024pii_detected"],
        promptHash: json["\u0024prompt_hash"],
        promptLengthChars: json["\u0024prompt_length_chars"]?.toDouble(),
        promptText: json["\u0024prompt_text"],
        promptTokensEstimated: json["\u0024prompt_tokens_estimated"]?.toDouble(),
        sensitiveCategory: json["\u0024sensitive_category"],
    );

    Map<String, dynamic> toJson() => {
        "\u0024capture_mode": captureModeValues.reverse[captureMode],
        "\u0024contains_attachment": containsAttachment,
        "\u0024contains_code": containsCode,
        "\u0024language": language,
        "\u0024pii_detected": piiDetected,
        "\u0024prompt_hash": promptHash,
        "\u0024prompt_length_chars": promptLengthChars,
        "\u0024prompt_text": promptText,
        "\u0024prompt_tokens_estimated": promptTokensEstimated,
        "\u0024sensitive_category": sensitiveCategory,
    };
}

enum CaptureMode {
    FULL,
    HASH,
    METADATA_ONLY,
    OFF
}

final captureModeValues = EnumValues({
    "full": CaptureMode.FULL,
    "hash": CaptureMode.HASH,
    "metadata_only": CaptureMode.METADATA_ONLY,
    "off": CaptureMode.OFF
});

enum SensitiveCategory {
    CREDENTIAL,
    CUSTOMER_DATA,
    FINANCE,
    HEALTHCARE,
    INTERNAL_DOCUMENT,
    LEGAL,
    PII,
    SOURCE_CODE,
    UNKNOWN_SENSITIVE
}

final sensitiveCategoryValues = EnumValues({
    "credential": SensitiveCategory.CREDENTIAL,
    "customer_data": SensitiveCategory.CUSTOMER_DATA,
    "finance": SensitiveCategory.FINANCE,
    "healthcare": SensitiveCategory.HEALTHCARE,
    "internal_document": SensitiveCategory.INTERNAL_DOCUMENT,
    "legal": SensitiveCategory.LEGAL,
    "pii": SensitiveCategory.PII,
    "source_code": SensitiveCategory.SOURCE_CODE,
    "unknown_sensitive": SensitiveCategory.UNKNOWN_SENSITIVE
});

class AiResponseInteractedProps {
    String? destination;
    AiInteractionType interactionType;
    String? requestId;
    String? responseId;
    String? source;
    double? timeSinceResponseMs;
    double? visibleOutputRatio;

    AiResponseInteractedProps({
        this.destination,
        required this.interactionType,
        this.requestId,
        this.responseId,
        this.source,
        this.timeSinceResponseMs,
        this.visibleOutputRatio,
    });

    factory AiResponseInteractedProps.fromJson(Map<String, dynamic> json) => AiResponseInteractedProps(
        destination: json["\u0024destination"],
        interactionType: aiInteractionTypeValues.map[json["\u0024interaction_type"]]!,
        requestId: json["\u0024request_id"],
        responseId: json["\u0024response_id"],
        source: json["\u0024source"],
        timeSinceResponseMs: json["\u0024time_since_response_ms"]?.toDouble(),
        visibleOutputRatio: json["\u0024visible_output_ratio"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "\u0024destination": destination,
        "\u0024interaction_type": aiInteractionTypeValues.reverse[interactionType],
        "\u0024request_id": requestId,
        "\u0024response_id": responseId,
        "\u0024source": source,
        "\u0024time_since_response_ms": timeSinceResponseMs,
        "\u0024visible_output_ratio": visibleOutputRatio,
    };
}

enum AiInteractionType {
    ABORTED,
    ACCEPTED,
    COLLAPSED,
    COPIED,
    DOWNLOADED,
    EXPANDED,
    INSERTED,
    RATED_NEGATIVE,
    RATED_POSITIVE,
    REGENERATED,
    REJECTED,
    SHARED
}

final aiInteractionTypeValues = EnumValues({
    "aborted": AiInteractionType.ABORTED,
    "accepted": AiInteractionType.ACCEPTED,
    "collapsed": AiInteractionType.COLLAPSED,
    "copied": AiInteractionType.COPIED,
    "downloaded": AiInteractionType.DOWNLOADED,
    "expanded": AiInteractionType.EXPANDED,
    "inserted": AiInteractionType.INSERTED,
    "rated_negative": AiInteractionType.RATED_NEGATIVE,
    "rated_positive": AiInteractionType.RATED_POSITIVE,
    "regenerated": AiInteractionType.REGENERATED,
    "rejected": AiInteractionType.REJECTED,
    "shared": AiInteractionType.SHARED
});

class AiResponseRenderedProps {
    CaptureMode captureMode;
    double? outputLengthChars;
    String responseId;
    String? responseText;
    double? timeToRenderMs;
    double? visibleOutputRatio;

    AiResponseRenderedProps({
        required this.captureMode,
        this.outputLengthChars,
        required this.responseId,
        this.responseText,
        this.timeToRenderMs,
        this.visibleOutputRatio,
    });

    factory AiResponseRenderedProps.fromJson(Map<String, dynamic> json) => AiResponseRenderedProps(
        captureMode: captureModeValues.map[json["\u0024capture_mode"]]!,
        outputLengthChars: json["\u0024output_length_chars"]?.toDouble(),
        responseId: json["\u0024response_id"],
        responseText: json["\u0024response_text"],
        timeToRenderMs: json["\u0024time_to_render_ms"]?.toDouble(),
        visibleOutputRatio: json["\u0024visible_output_ratio"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "\u0024capture_mode": captureModeValues.reverse[captureMode],
        "\u0024output_length_chars": outputLengthChars,
        "\u0024response_id": responseId,
        "\u0024response_text": responseText,
        "\u0024time_to_render_ms": timeToRenderMs,
        "\u0024visible_output_ratio": visibleOutputRatio,
    };
}

class AutocaptureProps {
    String? aiAction;
    double ceVersion;
    String? elName;
    String? elText;
    String? elValue;
    String elementsChain;
    AutocaptureEventType eventType;
    String? href;
    String? inputType;
    String? requestId;
    String? responseId;
    double? selectionLength;
    String? tagName;

    AutocaptureProps({
        this.aiAction,
        required this.ceVersion,
        this.elName,
        this.elText,
        this.elValue,
        required this.elementsChain,
        required this.eventType,
        this.href,
        this.inputType,
        this.requestId,
        this.responseId,
        this.selectionLength,
        this.tagName,
    });

    factory AutocaptureProps.fromJson(Map<String, dynamic> json) => AutocaptureProps(
        aiAction: json["\u0024ai_action"],
        ceVersion: json["\u0024ce_version"]?.toDouble(),
        elName: json["\u0024el_name"],
        elText: json["\u0024el_text"],
        elValue: json["\u0024el_value"],
        elementsChain: json["\u0024elements_chain"],
        eventType: autocaptureEventTypeValues.map[json["\u0024event_type"]]!,
        href: json["\u0024href"],
        inputType: json["\u0024input_type"],
        requestId: json["\u0024request_id"],
        responseId: json["\u0024response_id"],
        selectionLength: json["\u0024selection_length"]?.toDouble(),
        tagName: json["\u0024tag_name"],
    );

    Map<String, dynamic> toJson() => {
        "\u0024ai_action": aiAction,
        "\u0024ce_version": ceVersion,
        "\u0024el_name": elName,
        "\u0024el_text": elText,
        "\u0024el_value": elValue,
        "\u0024elements_chain": elementsChain,
        "\u0024event_type": autocaptureEventTypeValues.reverse[eventType],
        "\u0024href": href,
        "\u0024input_type": inputType,
        "\u0024request_id": requestId,
        "\u0024response_id": responseId,
        "\u0024selection_length": selectionLength,
        "\u0024tag_name": tagName,
    };
}

enum AutocaptureEventType {
    CHANGE,
    CLICK,
    COPY,
    SUBMIT
}

final autocaptureEventTypeValues = EnumValues({
    "change": AutocaptureEventType.CHANGE,
    "click": AutocaptureEventType.CLICK,
    "copy": AutocaptureEventType.COPY,
    "submit": AutocaptureEventType.SUBMIT
});

class BrowserAiPromptSubmittedEvent {
    String deviceId;
    String eventId;
    BrowserAiPromptSubmittedEventEventName eventName;
    BrowserAiPromptSubmittedEventExtraJson extraJson;
    String occurredAt;
    String? scale;
    String? sessionId;
    String? traceId;
    double? value;

    BrowserAiPromptSubmittedEvent({
        required this.deviceId,
        required this.eventId,
        required this.eventName,
        required this.extraJson,
        required this.occurredAt,
        this.scale,
        this.sessionId,
        this.traceId,
        this.value,
    });

    factory BrowserAiPromptSubmittedEvent.fromJson(Map<String, dynamic> json) => BrowserAiPromptSubmittedEvent(
        deviceId: json["device_id"],
        eventId: json["event_id"],
        eventName: browserAiPromptSubmittedEventEventNameValues.map[json["event_name"]]!,
        extraJson: BrowserAiPromptSubmittedEventExtraJson.fromJson(json["extra_json"]),
        occurredAt: json["occurred_at"],
        scale: json["scale"],
        sessionId: json["session_id"],
        traceId: json["trace_id"],
        value: json["value"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "device_id": deviceId,
        "event_id": eventId,
        "event_name": browserAiPromptSubmittedEventEventNameValues.reverse[eventName],
        "extra_json": extraJson.toJson(),
        "occurred_at": occurredAt,
        "scale": scale,
        "session_id": sessionId,
        "trace_id": traceId,
        "value": value,
    };
}

enum BrowserAiPromptSubmittedEventEventName {
    LLM_PROMPT_SUBMITTED
}

final browserAiPromptSubmittedEventEventNameValues = EnumValues({
    "llm_prompt_submitted": BrowserAiPromptSubmittedEventEventName.LLM_PROMPT_SUBMITTED
});

class BrowserAiPromptSubmittedEventExtraJson {
    String? anonymousId;
    String? appVersion;
    CaptureMode captureMode;
    bool? containsAttachment;
    bool? containsCode;
    String? conversationId;
    String? deviceId;
    String? entryPoint;
    Environment? environment;
    String? featureFlagKey;
    String? featureFlagVariant;
    String? language;
    Lib? lib;
    String? libVersion;
    String? messageId;
    String? nodeKey;
    String? pageviewId;
    bool? piiDetected;
    String? promptHash;
    double? promptLengthChars;
    String? promptTemplateId;
    String? promptText;
    double? promptTokensEstimated;
    String? requestId;
    String? responseId;
    String? schemaVersion;
    dynamic sensitiveCategory;
    String? sessionId;
    String? surface;
    String? taskType;
    String? tenantId;
    String? traceId;
    String? userId;
    String? windowId;

    BrowserAiPromptSubmittedEventExtraJson({
        this.anonymousId,
        this.appVersion,
        required this.captureMode,
        this.containsAttachment,
        this.containsCode,
        this.conversationId,
        this.deviceId,
        this.entryPoint,
        this.environment,
        this.featureFlagKey,
        this.featureFlagVariant,
        this.language,
        this.lib,
        this.libVersion,
        this.messageId,
        this.nodeKey,
        this.pageviewId,
        this.piiDetected,
        this.promptHash,
        this.promptLengthChars,
        this.promptTemplateId,
        this.promptText,
        this.promptTokensEstimated,
        this.requestId,
        this.responseId,
        this.schemaVersion,
        this.sensitiveCategory,
        this.sessionId,
        this.surface,
        this.taskType,
        this.tenantId,
        this.traceId,
        this.userId,
        this.windowId,
    });

    factory BrowserAiPromptSubmittedEventExtraJson.fromJson(Map<String, dynamic> json) => BrowserAiPromptSubmittedEventExtraJson(
        anonymousId: json["\u0024anonymous_id"],
        appVersion: json["\u0024app_version"],
        captureMode: captureModeValues.map[json["\u0024capture_mode"]]!,
        containsAttachment: json["\u0024contains_attachment"],
        containsCode: json["\u0024contains_code"],
        conversationId: json["\u0024conversation_id"],
        deviceId: json["\u0024device_id"],
        entryPoint: json["\u0024entry_point"],
        environment: environmentValues.map[json["\u0024environment"]],
        featureFlagKey: json["\u0024feature_flag_key"],
        featureFlagVariant: json["\u0024feature_flag_variant"],
        language: json["\u0024language"],
        lib: libValues.map[json["\u0024lib"]],
        libVersion: json["\u0024lib_version"],
        messageId: json["\u0024message_id"],
        nodeKey: json["\u0024node_key"],
        pageviewId: json["\u0024pageview_id"],
        piiDetected: json["\u0024pii_detected"],
        promptHash: json["\u0024prompt_hash"],
        promptLengthChars: json["\u0024prompt_length_chars"]?.toDouble(),
        promptTemplateId: json["\u0024prompt_template_id"],
        promptText: json["\u0024prompt_text"],
        promptTokensEstimated: json["\u0024prompt_tokens_estimated"]?.toDouble(),
        requestId: json["\u0024request_id"],
        responseId: json["\u0024response_id"],
        schemaVersion: json["\u0024schema_version"],
        sensitiveCategory: json["\u0024sensitive_category"],
        sessionId: json["\u0024session_id"],
        surface: json["\u0024surface"],
        taskType: json["\u0024task_type"],
        tenantId: json["\u0024tenant_id"],
        traceId: json["\u0024trace_id"],
        userId: json["\u0024user_id"],
        windowId: json["\u0024window_id"],
    );

    Map<String, dynamic> toJson() => {
        "\u0024anonymous_id": anonymousId,
        "\u0024app_version": appVersion,
        "\u0024capture_mode": captureModeValues.reverse[captureMode],
        "\u0024contains_attachment": containsAttachment,
        "\u0024contains_code": containsCode,
        "\u0024conversation_id": conversationId,
        "\u0024device_id": deviceId,
        "\u0024entry_point": entryPoint,
        "\u0024environment": environmentValues.reverse[environment],
        "\u0024feature_flag_key": featureFlagKey,
        "\u0024feature_flag_variant": featureFlagVariant,
        "\u0024language": language,
        "\u0024lib": libValues.reverse[lib],
        "\u0024lib_version": libVersion,
        "\u0024message_id": messageId,
        "\u0024node_key": nodeKey,
        "\u0024pageview_id": pageviewId,
        "\u0024pii_detected": piiDetected,
        "\u0024prompt_hash": promptHash,
        "\u0024prompt_length_chars": promptLengthChars,
        "\u0024prompt_template_id": promptTemplateId,
        "\u0024prompt_text": promptText,
        "\u0024prompt_tokens_estimated": promptTokensEstimated,
        "\u0024request_id": requestId,
        "\u0024response_id": responseId,
        "\u0024schema_version": schemaVersion,
        "\u0024sensitive_category": sensitiveCategory,
        "\u0024session_id": sessionId,
        "\u0024surface": surface,
        "\u0024task_type": taskType,
        "\u0024tenant_id": tenantId,
        "\u0024trace_id": traceId,
        "\u0024user_id": userId,
        "\u0024window_id": windowId,
    };
}

enum Environment {
    DEVELOPMENT,
    PRODUCTION
}

final environmentValues = EnumValues({
    "development": Environment.DEVELOPMENT,
    "production": Environment.PRODUCTION
});

enum Lib {
    ANDROID,
    FLUTTER,
    IOS,
    WEB
}

final libValues = EnumValues({
    "android": Lib.ANDROID,
    "flutter": Lib.FLUTTER,
    "ios": Lib.IOS,
    "web": Lib.WEB
});

class BrowserAiResponseInteractedEvent {
    String deviceId;
    String eventId;
    BrowserAiResponseInteractedEventEventName eventName;
    BrowserAiResponseInteractedEventExtraJson extraJson;
    String occurredAt;
    String? scale;
    String? sessionId;
    String? traceId;
    double? value;

    BrowserAiResponseInteractedEvent({
        required this.deviceId,
        required this.eventId,
        required this.eventName,
        required this.extraJson,
        required this.occurredAt,
        this.scale,
        this.sessionId,
        this.traceId,
        this.value,
    });

    factory BrowserAiResponseInteractedEvent.fromJson(Map<String, dynamic> json) => BrowserAiResponseInteractedEvent(
        deviceId: json["device_id"],
        eventId: json["event_id"],
        eventName: browserAiResponseInteractedEventEventNameValues.map[json["event_name"]]!,
        extraJson: BrowserAiResponseInteractedEventExtraJson.fromJson(json["extra_json"]),
        occurredAt: json["occurred_at"],
        scale: json["scale"],
        sessionId: json["session_id"],
        traceId: json["trace_id"],
        value: json["value"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "device_id": deviceId,
        "event_id": eventId,
        "event_name": browserAiResponseInteractedEventEventNameValues.reverse[eventName],
        "extra_json": extraJson.toJson(),
        "occurred_at": occurredAt,
        "scale": scale,
        "session_id": sessionId,
        "trace_id": traceId,
        "value": value,
    };
}

enum BrowserAiResponseInteractedEventEventName {
    LLM_RESPONSE_INTERACTED
}

final browserAiResponseInteractedEventEventNameValues = EnumValues({
    "llm_response_interacted": BrowserAiResponseInteractedEventEventName.LLM_RESPONSE_INTERACTED
});

class BrowserAiResponseInteractedEventExtraJson {
    String? anonymousId;
    String? appVersion;
    String? conversationId;
    String? destination;
    String? deviceId;
    String? entryPoint;
    Environment? environment;
    String? featureFlagKey;
    String? featureFlagVariant;
    AiInteractionType interactionType;
    Lib? lib;
    String? libVersion;
    String? messageId;
    String? nodeKey;
    String? pageviewId;
    String? promptTemplateId;
    String? requestId;
    String? responseId;
    String? schemaVersion;
    String? sessionId;
    String? source;
    String? surface;
    String? taskType;
    String? tenantId;
    double? timeSinceResponseMs;
    String? traceId;
    String? userId;
    double? visibleOutputRatio;
    String? windowId;

    BrowserAiResponseInteractedEventExtraJson({
        this.anonymousId,
        this.appVersion,
        this.conversationId,
        this.destination,
        this.deviceId,
        this.entryPoint,
        this.environment,
        this.featureFlagKey,
        this.featureFlagVariant,
        required this.interactionType,
        this.lib,
        this.libVersion,
        this.messageId,
        this.nodeKey,
        this.pageviewId,
        this.promptTemplateId,
        this.requestId,
        this.responseId,
        this.schemaVersion,
        this.sessionId,
        this.source,
        this.surface,
        this.taskType,
        this.tenantId,
        this.timeSinceResponseMs,
        this.traceId,
        this.userId,
        this.visibleOutputRatio,
        this.windowId,
    });

    factory BrowserAiResponseInteractedEventExtraJson.fromJson(Map<String, dynamic> json) => BrowserAiResponseInteractedEventExtraJson(
        anonymousId: json["\u0024anonymous_id"],
        appVersion: json["\u0024app_version"],
        conversationId: json["\u0024conversation_id"],
        destination: json["\u0024destination"],
        deviceId: json["\u0024device_id"],
        entryPoint: json["\u0024entry_point"],
        environment: environmentValues.map[json["\u0024environment"]],
        featureFlagKey: json["\u0024feature_flag_key"],
        featureFlagVariant: json["\u0024feature_flag_variant"],
        interactionType: aiInteractionTypeValues.map[json["\u0024interaction_type"]]!,
        lib: libValues.map[json["\u0024lib"]],
        libVersion: json["\u0024lib_version"],
        messageId: json["\u0024message_id"],
        nodeKey: json["\u0024node_key"],
        pageviewId: json["\u0024pageview_id"],
        promptTemplateId: json["\u0024prompt_template_id"],
        requestId: json["\u0024request_id"],
        responseId: json["\u0024response_id"],
        schemaVersion: json["\u0024schema_version"],
        sessionId: json["\u0024session_id"],
        source: json["\u0024source"],
        surface: json["\u0024surface"],
        taskType: json["\u0024task_type"],
        tenantId: json["\u0024tenant_id"],
        timeSinceResponseMs: json["\u0024time_since_response_ms"]?.toDouble(),
        traceId: json["\u0024trace_id"],
        userId: json["\u0024user_id"],
        visibleOutputRatio: json["\u0024visible_output_ratio"]?.toDouble(),
        windowId: json["\u0024window_id"],
    );

    Map<String, dynamic> toJson() => {
        "\u0024anonymous_id": anonymousId,
        "\u0024app_version": appVersion,
        "\u0024conversation_id": conversationId,
        "\u0024destination": destination,
        "\u0024device_id": deviceId,
        "\u0024entry_point": entryPoint,
        "\u0024environment": environmentValues.reverse[environment],
        "\u0024feature_flag_key": featureFlagKey,
        "\u0024feature_flag_variant": featureFlagVariant,
        "\u0024interaction_type": aiInteractionTypeValues.reverse[interactionType],
        "\u0024lib": libValues.reverse[lib],
        "\u0024lib_version": libVersion,
        "\u0024message_id": messageId,
        "\u0024node_key": nodeKey,
        "\u0024pageview_id": pageviewId,
        "\u0024prompt_template_id": promptTemplateId,
        "\u0024request_id": requestId,
        "\u0024response_id": responseId,
        "\u0024schema_version": schemaVersion,
        "\u0024session_id": sessionId,
        "\u0024source": source,
        "\u0024surface": surface,
        "\u0024task_type": taskType,
        "\u0024tenant_id": tenantId,
        "\u0024time_since_response_ms": timeSinceResponseMs,
        "\u0024trace_id": traceId,
        "\u0024user_id": userId,
        "\u0024visible_output_ratio": visibleOutputRatio,
        "\u0024window_id": windowId,
    };
}

class BrowserAiResponseRenderedEvent {
    String deviceId;
    String eventId;
    BrowserAiResponseRenderedEventEventName eventName;
    BrowserAiResponseRenderedEventExtraJson extraJson;
    String occurredAt;
    String? scale;
    String? sessionId;
    String? traceId;
    double? value;

    BrowserAiResponseRenderedEvent({
        required this.deviceId,
        required this.eventId,
        required this.eventName,
        required this.extraJson,
        required this.occurredAt,
        this.scale,
        this.sessionId,
        this.traceId,
        this.value,
    });

    factory BrowserAiResponseRenderedEvent.fromJson(Map<String, dynamic> json) => BrowserAiResponseRenderedEvent(
        deviceId: json["device_id"],
        eventId: json["event_id"],
        eventName: browserAiResponseRenderedEventEventNameValues.map[json["event_name"]]!,
        extraJson: BrowserAiResponseRenderedEventExtraJson.fromJson(json["extra_json"]),
        occurredAt: json["occurred_at"],
        scale: json["scale"],
        sessionId: json["session_id"],
        traceId: json["trace_id"],
        value: json["value"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "device_id": deviceId,
        "event_id": eventId,
        "event_name": browserAiResponseRenderedEventEventNameValues.reverse[eventName],
        "extra_json": extraJson.toJson(),
        "occurred_at": occurredAt,
        "scale": scale,
        "session_id": sessionId,
        "trace_id": traceId,
        "value": value,
    };
}

enum BrowserAiResponseRenderedEventEventName {
    LLM_RESPONSE_RENDERED
}

final browserAiResponseRenderedEventEventNameValues = EnumValues({
    "llm_response_rendered": BrowserAiResponseRenderedEventEventName.LLM_RESPONSE_RENDERED
});

class BrowserAiResponseRenderedEventExtraJson {
    String? anonymousId;
    String? appVersion;
    CaptureMode captureMode;
    String? conversationId;
    String? deviceId;
    String? entryPoint;
    Environment? environment;
    String? featureFlagKey;
    String? featureFlagVariant;
    Lib? lib;
    String? libVersion;
    String? messageId;
    String? nodeKey;
    double? outputLengthChars;
    String? pageviewId;
    String? promptTemplateId;
    String? requestId;
    String responseId;
    String? responseText;
    String? schemaVersion;
    String? sessionId;
    String? surface;
    String? taskType;
    String? tenantId;
    double? timeToRenderMs;
    String? traceId;
    String? userId;
    double? visibleOutputRatio;
    String? windowId;

    BrowserAiResponseRenderedEventExtraJson({
        this.anonymousId,
        this.appVersion,
        required this.captureMode,
        this.conversationId,
        this.deviceId,
        this.entryPoint,
        this.environment,
        this.featureFlagKey,
        this.featureFlagVariant,
        this.lib,
        this.libVersion,
        this.messageId,
        this.nodeKey,
        this.outputLengthChars,
        this.pageviewId,
        this.promptTemplateId,
        this.requestId,
        required this.responseId,
        this.responseText,
        this.schemaVersion,
        this.sessionId,
        this.surface,
        this.taskType,
        this.tenantId,
        this.timeToRenderMs,
        this.traceId,
        this.userId,
        this.visibleOutputRatio,
        this.windowId,
    });

    factory BrowserAiResponseRenderedEventExtraJson.fromJson(Map<String, dynamic> json) => BrowserAiResponseRenderedEventExtraJson(
        anonymousId: json["\u0024anonymous_id"],
        appVersion: json["\u0024app_version"],
        captureMode: captureModeValues.map[json["\u0024capture_mode"]]!,
        conversationId: json["\u0024conversation_id"],
        deviceId: json["\u0024device_id"],
        entryPoint: json["\u0024entry_point"],
        environment: environmentValues.map[json["\u0024environment"]],
        featureFlagKey: json["\u0024feature_flag_key"],
        featureFlagVariant: json["\u0024feature_flag_variant"],
        lib: libValues.map[json["\u0024lib"]],
        libVersion: json["\u0024lib_version"],
        messageId: json["\u0024message_id"],
        nodeKey: json["\u0024node_key"],
        outputLengthChars: json["\u0024output_length_chars"]?.toDouble(),
        pageviewId: json["\u0024pageview_id"],
        promptTemplateId: json["\u0024prompt_template_id"],
        requestId: json["\u0024request_id"],
        responseId: json["\u0024response_id"],
        responseText: json["\u0024response_text"],
        schemaVersion: json["\u0024schema_version"],
        sessionId: json["\u0024session_id"],
        surface: json["\u0024surface"],
        taskType: json["\u0024task_type"],
        tenantId: json["\u0024tenant_id"],
        timeToRenderMs: json["\u0024time_to_render_ms"]?.toDouble(),
        traceId: json["\u0024trace_id"],
        userId: json["\u0024user_id"],
        visibleOutputRatio: json["\u0024visible_output_ratio"]?.toDouble(),
        windowId: json["\u0024window_id"],
    );

    Map<String, dynamic> toJson() => {
        "\u0024anonymous_id": anonymousId,
        "\u0024app_version": appVersion,
        "\u0024capture_mode": captureModeValues.reverse[captureMode],
        "\u0024conversation_id": conversationId,
        "\u0024device_id": deviceId,
        "\u0024entry_point": entryPoint,
        "\u0024environment": environmentValues.reverse[environment],
        "\u0024feature_flag_key": featureFlagKey,
        "\u0024feature_flag_variant": featureFlagVariant,
        "\u0024lib": libValues.reverse[lib],
        "\u0024lib_version": libVersion,
        "\u0024message_id": messageId,
        "\u0024node_key": nodeKey,
        "\u0024output_length_chars": outputLengthChars,
        "\u0024pageview_id": pageviewId,
        "\u0024prompt_template_id": promptTemplateId,
        "\u0024request_id": requestId,
        "\u0024response_id": responseId,
        "\u0024response_text": responseText,
        "\u0024schema_version": schemaVersion,
        "\u0024session_id": sessionId,
        "\u0024surface": surface,
        "\u0024task_type": taskType,
        "\u0024tenant_id": tenantId,
        "\u0024time_to_render_ms": timeToRenderMs,
        "\u0024trace_id": traceId,
        "\u0024user_id": userId,
        "\u0024visible_output_ratio": visibleOutputRatio,
        "\u0024window_id": windowId,
    };
}

class BrowserAutocaptureEvent {
    String deviceId;
    String eventId;
    BrowserAutocaptureEventEventName eventName;
    BrowserAutocaptureEventExtraJson extraJson;
    String occurredAt;
    String? scale;
    String? sessionId;
    String? traceId;
    double? value;

    BrowserAutocaptureEvent({
        required this.deviceId,
        required this.eventId,
        required this.eventName,
        required this.extraJson,
        required this.occurredAt,
        this.scale,
        this.sessionId,
        this.traceId,
        this.value,
    });

    factory BrowserAutocaptureEvent.fromJson(Map<String, dynamic> json) => BrowserAutocaptureEvent(
        deviceId: json["device_id"],
        eventId: json["event_id"],
        eventName: browserAutocaptureEventEventNameValues.map[json["event_name"]]!,
        extraJson: BrowserAutocaptureEventExtraJson.fromJson(json["extra_json"]),
        occurredAt: json["occurred_at"],
        scale: json["scale"],
        sessionId: json["session_id"],
        traceId: json["trace_id"],
        value: json["value"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "device_id": deviceId,
        "event_id": eventId,
        "event_name": browserAutocaptureEventEventNameValues.reverse[eventName],
        "extra_json": extraJson.toJson(),
        "occurred_at": occurredAt,
        "scale": scale,
        "session_id": sessionId,
        "trace_id": traceId,
        "value": value,
    };
}

enum BrowserAutocaptureEventEventName {
    INTERACTION_AUTOCAPTURED
}

final browserAutocaptureEventEventNameValues = EnumValues({
    "interaction_autocaptured": BrowserAutocaptureEventEventName.INTERACTION_AUTOCAPTURED
});

class BrowserAutocaptureEventExtraJson {
    String? aiAction;
    String? anonymousId;
    String? appVersion;
    double ceVersion;
    String? conversationId;
    String? deviceId;
    String? elName;
    String? elText;
    String? elValue;
    String elementsChain;
    String? entryPoint;
    Environment? environment;
    AutocaptureEventType eventType;
    String? featureFlagKey;
    String? featureFlagVariant;
    String? href;
    String? inputType;
    Lib? lib;
    String? libVersion;
    String? messageId;
    String? nodeKey;
    String? pageviewId;
    String? promptTemplateId;
    String? requestId;
    String? responseId;
    String? schemaVersion;
    double? selectionLength;
    String? sessionId;
    String? surface;
    String? tagName;
    String? taskType;
    String? tenantId;
    String? traceId;
    String? userId;
    String? windowId;

    BrowserAutocaptureEventExtraJson({
        this.aiAction,
        this.anonymousId,
        this.appVersion,
        required this.ceVersion,
        this.conversationId,
        this.deviceId,
        this.elName,
        this.elText,
        this.elValue,
        required this.elementsChain,
        this.entryPoint,
        this.environment,
        required this.eventType,
        this.featureFlagKey,
        this.featureFlagVariant,
        this.href,
        this.inputType,
        this.lib,
        this.libVersion,
        this.messageId,
        this.nodeKey,
        this.pageviewId,
        this.promptTemplateId,
        this.requestId,
        this.responseId,
        this.schemaVersion,
        this.selectionLength,
        this.sessionId,
        this.surface,
        this.tagName,
        this.taskType,
        this.tenantId,
        this.traceId,
        this.userId,
        this.windowId,
    });

    factory BrowserAutocaptureEventExtraJson.fromJson(Map<String, dynamic> json) => BrowserAutocaptureEventExtraJson(
        aiAction: json["\u0024ai_action"],
        anonymousId: json["\u0024anonymous_id"],
        appVersion: json["\u0024app_version"],
        ceVersion: json["\u0024ce_version"]?.toDouble(),
        conversationId: json["\u0024conversation_id"],
        deviceId: json["\u0024device_id"],
        elName: json["\u0024el_name"],
        elText: json["\u0024el_text"],
        elValue: json["\u0024el_value"],
        elementsChain: json["\u0024elements_chain"],
        entryPoint: json["\u0024entry_point"],
        environment: environmentValues.map[json["\u0024environment"]],
        eventType: autocaptureEventTypeValues.map[json["\u0024event_type"]]!,
        featureFlagKey: json["\u0024feature_flag_key"],
        featureFlagVariant: json["\u0024feature_flag_variant"],
        href: json["\u0024href"],
        inputType: json["\u0024input_type"],
        lib: libValues.map[json["\u0024lib"]],
        libVersion: json["\u0024lib_version"],
        messageId: json["\u0024message_id"],
        nodeKey: json["\u0024node_key"],
        pageviewId: json["\u0024pageview_id"],
        promptTemplateId: json["\u0024prompt_template_id"],
        requestId: json["\u0024request_id"],
        responseId: json["\u0024response_id"],
        schemaVersion: json["\u0024schema_version"],
        selectionLength: json["\u0024selection_length"]?.toDouble(),
        sessionId: json["\u0024session_id"],
        surface: json["\u0024surface"],
        tagName: json["\u0024tag_name"],
        taskType: json["\u0024task_type"],
        tenantId: json["\u0024tenant_id"],
        traceId: json["\u0024trace_id"],
        userId: json["\u0024user_id"],
        windowId: json["\u0024window_id"],
    );

    Map<String, dynamic> toJson() => {
        "\u0024ai_action": aiAction,
        "\u0024anonymous_id": anonymousId,
        "\u0024app_version": appVersion,
        "\u0024ce_version": ceVersion,
        "\u0024conversation_id": conversationId,
        "\u0024device_id": deviceId,
        "\u0024el_name": elName,
        "\u0024el_text": elText,
        "\u0024el_value": elValue,
        "\u0024elements_chain": elementsChain,
        "\u0024entry_point": entryPoint,
        "\u0024environment": environmentValues.reverse[environment],
        "\u0024event_type": autocaptureEventTypeValues.reverse[eventType],
        "\u0024feature_flag_key": featureFlagKey,
        "\u0024feature_flag_variant": featureFlagVariant,
        "\u0024href": href,
        "\u0024input_type": inputType,
        "\u0024lib": libValues.reverse[lib],
        "\u0024lib_version": libVersion,
        "\u0024message_id": messageId,
        "\u0024node_key": nodeKey,
        "\u0024pageview_id": pageviewId,
        "\u0024prompt_template_id": promptTemplateId,
        "\u0024request_id": requestId,
        "\u0024response_id": responseId,
        "\u0024schema_version": schemaVersion,
        "\u0024selection_length": selectionLength,
        "\u0024session_id": sessionId,
        "\u0024surface": surface,
        "\u0024tag_name": tagName,
        "\u0024task_type": taskType,
        "\u0024tenant_id": tenantId,
        "\u0024trace_id": traceId,
        "\u0024user_id": userId,
        "\u0024window_id": windowId,
    };
}

class BrowserContextProperties {
    String? anonymousId;
    String? appVersion;
    String? conversationId;
    String? deviceId;
    String? entryPoint;
    Environment? environment;
    String? featureFlagKey;
    String? featureFlagVariant;
    Lib? lib;
    String? libVersion;
    String? messageId;
    String? nodeKey;
    String? pageviewId;
    String? promptTemplateId;
    String? requestId;
    String? responseId;
    String? schemaVersion;
    String? sessionId;
    String? surface;
    String? taskType;
    String? tenantId;
    String? traceId;
    String? userId;
    String? windowId;

    BrowserContextProperties({
        this.anonymousId,
        this.appVersion,
        this.conversationId,
        this.deviceId,
        this.entryPoint,
        this.environment,
        this.featureFlagKey,
        this.featureFlagVariant,
        this.lib,
        this.libVersion,
        this.messageId,
        this.nodeKey,
        this.pageviewId,
        this.promptTemplateId,
        this.requestId,
        this.responseId,
        this.schemaVersion,
        this.sessionId,
        this.surface,
        this.taskType,
        this.tenantId,
        this.traceId,
        this.userId,
        this.windowId,
    });

    factory BrowserContextProperties.fromJson(Map<String, dynamic> json) => BrowserContextProperties(
        anonymousId: json["\u0024anonymous_id"],
        appVersion: json["\u0024app_version"],
        conversationId: json["\u0024conversation_id"],
        deviceId: json["\u0024device_id"],
        entryPoint: json["\u0024entry_point"],
        environment: environmentValues.map[json["\u0024environment"]],
        featureFlagKey: json["\u0024feature_flag_key"],
        featureFlagVariant: json["\u0024feature_flag_variant"],
        lib: libValues.map[json["\u0024lib"]],
        libVersion: json["\u0024lib_version"],
        messageId: json["\u0024message_id"],
        nodeKey: json["\u0024node_key"],
        pageviewId: json["\u0024pageview_id"],
        promptTemplateId: json["\u0024prompt_template_id"],
        requestId: json["\u0024request_id"],
        responseId: json["\u0024response_id"],
        schemaVersion: json["\u0024schema_version"],
        sessionId: json["\u0024session_id"],
        surface: json["\u0024surface"],
        taskType: json["\u0024task_type"],
        tenantId: json["\u0024tenant_id"],
        traceId: json["\u0024trace_id"],
        userId: json["\u0024user_id"],
        windowId: json["\u0024window_id"],
    );

    Map<String, dynamic> toJson() => {
        "\u0024anonymous_id": anonymousId,
        "\u0024app_version": appVersion,
        "\u0024conversation_id": conversationId,
        "\u0024device_id": deviceId,
        "\u0024entry_point": entryPoint,
        "\u0024environment": environmentValues.reverse[environment],
        "\u0024feature_flag_key": featureFlagKey,
        "\u0024feature_flag_variant": featureFlagVariant,
        "\u0024lib": libValues.reverse[lib],
        "\u0024lib_version": libVersion,
        "\u0024message_id": messageId,
        "\u0024node_key": nodeKey,
        "\u0024pageview_id": pageviewId,
        "\u0024prompt_template_id": promptTemplateId,
        "\u0024request_id": requestId,
        "\u0024response_id": responseId,
        "\u0024schema_version": schemaVersion,
        "\u0024session_id": sessionId,
        "\u0024surface": surface,
        "\u0024task_type": taskType,
        "\u0024tenant_id": tenantId,
        "\u0024trace_id": traceId,
        "\u0024user_id": userId,
        "\u0024window_id": windowId,
    };
}

class BrowserDeadClickEvent {
    String deviceId;
    String eventId;
    BrowserDeadClickEventEventName eventName;
    BrowserDeadClickEventExtraJson extraJson;
    String occurredAt;
    String? scale;
    String? sessionId;
    String? traceId;
    double? value;

    BrowserDeadClickEvent({
        required this.deviceId,
        required this.eventId,
        required this.eventName,
        required this.extraJson,
        required this.occurredAt,
        this.scale,
        this.sessionId,
        this.traceId,
        this.value,
    });

    factory BrowserDeadClickEvent.fromJson(Map<String, dynamic> json) => BrowserDeadClickEvent(
        deviceId: json["device_id"],
        eventId: json["event_id"],
        eventName: browserDeadClickEventEventNameValues.map[json["event_name"]]!,
        extraJson: BrowserDeadClickEventExtraJson.fromJson(json["extra_json"]),
        occurredAt: json["occurred_at"],
        scale: json["scale"],
        sessionId: json["session_id"],
        traceId: json["trace_id"],
        value: json["value"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "device_id": deviceId,
        "event_id": eventId,
        "event_name": browserDeadClickEventEventNameValues.reverse[eventName],
        "extra_json": extraJson.toJson(),
        "occurred_at": occurredAt,
        "scale": scale,
        "session_id": sessionId,
        "trace_id": traceId,
        "value": value,
    };
}

enum BrowserDeadClickEventEventName {
    INTERACTION_DEADCLICK
}

final browserDeadClickEventEventNameValues = EnumValues({
    "interaction_deadclick": BrowserDeadClickEventEventName.INTERACTION_DEADCLICK
});

class BrowserDeadClickEventExtraJson {
    String? anonymousId;
    String? appVersion;
    String? conversationId;
    String? deviceId;
    String elementsChain;
    String? entryPoint;
    Environment? environment;
    String? featureFlagKey;
    String? featureFlagVariant;
    Lib? lib;
    String? libVersion;
    String? messageId;
    String? nodeKey;
    String? pageviewId;
    String? promptTemplateId;
    String? requestId;
    String? responseId;
    String? schemaVersion;
    String? sessionId;
    String? surface;
    String? taskType;
    String? tenantId;
    String? traceId;
    String? userId;
    String? windowId;

    BrowserDeadClickEventExtraJson({
        this.anonymousId,
        this.appVersion,
        this.conversationId,
        this.deviceId,
        required this.elementsChain,
        this.entryPoint,
        this.environment,
        this.featureFlagKey,
        this.featureFlagVariant,
        this.lib,
        this.libVersion,
        this.messageId,
        this.nodeKey,
        this.pageviewId,
        this.promptTemplateId,
        this.requestId,
        this.responseId,
        this.schemaVersion,
        this.sessionId,
        this.surface,
        this.taskType,
        this.tenantId,
        this.traceId,
        this.userId,
        this.windowId,
    });

    factory BrowserDeadClickEventExtraJson.fromJson(Map<String, dynamic> json) => BrowserDeadClickEventExtraJson(
        anonymousId: json["\u0024anonymous_id"],
        appVersion: json["\u0024app_version"],
        conversationId: json["\u0024conversation_id"],
        deviceId: json["\u0024device_id"],
        elementsChain: json["\u0024elements_chain"],
        entryPoint: json["\u0024entry_point"],
        environment: environmentValues.map[json["\u0024environment"]],
        featureFlagKey: json["\u0024feature_flag_key"],
        featureFlagVariant: json["\u0024feature_flag_variant"],
        lib: libValues.map[json["\u0024lib"]],
        libVersion: json["\u0024lib_version"],
        messageId: json["\u0024message_id"],
        nodeKey: json["\u0024node_key"],
        pageviewId: json["\u0024pageview_id"],
        promptTemplateId: json["\u0024prompt_template_id"],
        requestId: json["\u0024request_id"],
        responseId: json["\u0024response_id"],
        schemaVersion: json["\u0024schema_version"],
        sessionId: json["\u0024session_id"],
        surface: json["\u0024surface"],
        taskType: json["\u0024task_type"],
        tenantId: json["\u0024tenant_id"],
        traceId: json["\u0024trace_id"],
        userId: json["\u0024user_id"],
        windowId: json["\u0024window_id"],
    );

    Map<String, dynamic> toJson() => {
        "\u0024anonymous_id": anonymousId,
        "\u0024app_version": appVersion,
        "\u0024conversation_id": conversationId,
        "\u0024device_id": deviceId,
        "\u0024elements_chain": elementsChain,
        "\u0024entry_point": entryPoint,
        "\u0024environment": environmentValues.reverse[environment],
        "\u0024feature_flag_key": featureFlagKey,
        "\u0024feature_flag_variant": featureFlagVariant,
        "\u0024lib": libValues.reverse[lib],
        "\u0024lib_version": libVersion,
        "\u0024message_id": messageId,
        "\u0024node_key": nodeKey,
        "\u0024pageview_id": pageviewId,
        "\u0024prompt_template_id": promptTemplateId,
        "\u0024request_id": requestId,
        "\u0024response_id": responseId,
        "\u0024schema_version": schemaVersion,
        "\u0024session_id": sessionId,
        "\u0024surface": surface,
        "\u0024task_type": taskType,
        "\u0024tenant_id": tenantId,
        "\u0024trace_id": traceId,
        "\u0024user_id": userId,
        "\u0024window_id": windowId,
    };
}

class BrowserEventBatchRequest {
    List<BrowserEvent> batch;

    BrowserEventBatchRequest({
        required this.batch,
    });

    factory BrowserEventBatchRequest.fromJson(Map<String, dynamic> json) => BrowserEventBatchRequest(
        batch: List<BrowserEvent>.from(json["batch"].map((x) => BrowserEvent.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "batch": List<dynamic>.from(batch.map((x) => x.toJson())),
    };
}

class BrowserEvent {
    String deviceId;
    String eventId;
    String eventName;
    Map<String, dynamic> extraJson;
    String occurredAt;
    String? scale;
    String? sessionId;
    String? traceId;
    double? value;

    BrowserEvent({
        required this.deviceId,
        required this.eventId,
        required this.eventName,
        required this.extraJson,
        required this.occurredAt,
        this.scale,
        this.sessionId,
        this.traceId,
        this.value,
    });

    factory BrowserEvent.fromJson(Map<String, dynamic> json) => BrowserEvent(
        deviceId: json["device_id"],
        eventId: json["event_id"],
        eventName: json["event_name"],
        extraJson: Map.from(json["extra_json"]).map((k, v) => MapEntry<String, dynamic>(k, v)),
        occurredAt: json["occurred_at"],
        scale: json["scale"],
        sessionId: json["session_id"],
        traceId: json["trace_id"],
        value: json["value"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "device_id": deviceId,
        "event_id": eventId,
        "event_name": eventName,
        "extra_json": Map.from(extraJson).map((k, v) => MapEntry<String, dynamic>(k, v)),
        "occurred_at": occurredAt,
        "scale": scale,
        "session_id": sessionId,
        "trace_id": traceId,
        "value": value,
    };
}

class BrowserEventBatchResponse {
    Map<String, BrowserEventResult> results;

    BrowserEventBatchResponse({
        required this.results,
    });

    factory BrowserEventBatchResponse.fromJson(Map<String, dynamic> json) => BrowserEventBatchResponse(
        results: Map.from(json["results"]).map((k, v) => MapEntry<String, BrowserEventResult>(k, BrowserEventResult.fromJson(v))),
    );

    Map<String, dynamic> toJson() => {
        "results": Map.from(results).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
    };
}

class BrowserEventResult {
    BrowserEventResultCode? code;
    BrowserEventResultStatus result;

    BrowserEventResult({
        this.code,
        required this.result,
    });

    factory BrowserEventResult.fromJson(Map<String, dynamic> json) => BrowserEventResult(
        code: browserEventResultCodeValues.map[json["code"]],
        result: browserEventResultStatusValues.map[json["result"]]!,
    );

    Map<String, dynamic> toJson() => {
        "code": browserEventResultCodeValues.reverse[code],
        "result": browserEventResultStatusValues.reverse[result],
    };
}

enum BrowserEventResultCode {
    INVALID_EVENT,
    MISSING_REQUIRED,
    RESERVED_NAME,
    SCHEMA_DISCOVERED,
    SCHEMA_DRIFT,
    SCHEMA_ENUM_MISMATCH,
    SCHEMA_REQUIRED_MISSING,
    SCHEMA_TYPE_MISMATCH,
    STORAGE_UNAVAILABLE
}

final browserEventResultCodeValues = EnumValues({
    "invalid_event": BrowserEventResultCode.INVALID_EVENT,
    "missing_required": BrowserEventResultCode.MISSING_REQUIRED,
    "reserved_name": BrowserEventResultCode.RESERVED_NAME,
    "schema_discovered": BrowserEventResultCode.SCHEMA_DISCOVERED,
    "schema_drift": BrowserEventResultCode.SCHEMA_DRIFT,
    "schema_enum_mismatch": BrowserEventResultCode.SCHEMA_ENUM_MISMATCH,
    "schema_required_missing": BrowserEventResultCode.SCHEMA_REQUIRED_MISSING,
    "schema_type_mismatch": BrowserEventResultCode.SCHEMA_TYPE_MISMATCH,
    "storage_unavailable": BrowserEventResultCode.STORAGE_UNAVAILABLE
});

enum BrowserEventResultStatus {
    DROP,
    OK,
    RETRY,
    WARNING
}

final browserEventResultStatusValues = EnumValues({
    "drop": BrowserEventResultStatus.DROP,
    "ok": BrowserEventResultStatus.OK,
    "retry": BrowserEventResultStatus.RETRY,
    "warning": BrowserEventResultStatus.WARNING
});

class BrowserIngestEvent {
    String deviceId;
    String eventId;
    String eventName;
    Map<String, dynamic> extraJson;
    String occurredAt;
    String? scale;
    String? sessionId;
    String? traceId;

    ///Finite decimal with at most 38 integer digits and 12 fractional digits
    double? value;

    BrowserIngestEvent({
        required this.deviceId,
        required this.eventId,
        required this.eventName,
        required this.extraJson,
        required this.occurredAt,
        this.scale,
        this.sessionId,
        this.traceId,
        this.value,
    });

    factory BrowserIngestEvent.fromJson(Map<String, dynamic> json) => BrowserIngestEvent(
        deviceId: json["device_id"],
        eventId: json["event_id"],
        eventName: json["event_name"],
        extraJson: Map.from(json["extra_json"]).map((k, v) => MapEntry<String, dynamic>(k, v)),
        occurredAt: json["occurred_at"],
        scale: json["scale"],
        sessionId: json["session_id"],
        traceId: json["trace_id"],
        value: json["value"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "device_id": deviceId,
        "event_id": eventId,
        "event_name": eventName,
        "extra_json": Map.from(extraJson).map((k, v) => MapEntry<String, dynamic>(k, v)),
        "occurred_at": occurredAt,
        "scale": scale,
        "session_id": sessionId,
        "trace_id": traceId,
        "value": value,
    };
}

class BrowserPageleaveEvent {
    String deviceId;
    String eventId;
    BrowserPageleaveEventEventName eventName;
    BrowserPageleaveEventExtraJson extraJson;
    String occurredAt;
    String? scale;
    String? sessionId;
    String? traceId;
    double? value;

    BrowserPageleaveEvent({
        required this.deviceId,
        required this.eventId,
        required this.eventName,
        required this.extraJson,
        required this.occurredAt,
        this.scale,
        this.sessionId,
        this.traceId,
        this.value,
    });

    factory BrowserPageleaveEvent.fromJson(Map<String, dynamic> json) => BrowserPageleaveEvent(
        deviceId: json["device_id"],
        eventId: json["event_id"],
        eventName: browserPageleaveEventEventNameValues.map[json["event_name"]]!,
        extraJson: BrowserPageleaveEventExtraJson.fromJson(json["extra_json"]),
        occurredAt: json["occurred_at"],
        scale: json["scale"],
        sessionId: json["session_id"],
        traceId: json["trace_id"],
        value: json["value"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "device_id": deviceId,
        "event_id": eventId,
        "event_name": browserPageleaveEventEventNameValues.reverse[eventName],
        "extra_json": extraJson.toJson(),
        "occurred_at": occurredAt,
        "scale": scale,
        "session_id": sessionId,
        "trace_id": traceId,
        "value": value,
    };
}

enum BrowserPageleaveEventEventName {
    PAGELEAVE
}

final browserPageleaveEventEventNameValues = EnumValues({
    "pageleave": BrowserPageleaveEventEventName.PAGELEAVE
});

class BrowserPageleaveEventExtraJson {
    String? anonymousId;
    String? appVersion;
    String? conversationId;
    String currentUrl;
    String? deviceId;
    double? durationMs;
    String? entryPoint;
    Environment? environment;
    String? featureFlagKey;
    String? featureFlagVariant;
    double? lastContentPercentage;
    double? lastContentY;
    double? lastScrollPercentage;
    double? lastScrollY;
    Lib? lib;
    String? libVersion;
    double? maxContentPercentage;
    double? maxContentY;
    double? maxScrollPercentage;
    double? maxScrollY;
    String? messageId;
    String? nodeKey;
    String? pageviewId;
    String pathname;
    String? promptTemplateId;
    String? requestId;
    String? responseId;
    String? schemaVersion;
    String? sessionId;
    String? surface;
    String? taskType;
    String? tenantId;
    String? traceId;
    String? userId;
    String? windowId;

    BrowserPageleaveEventExtraJson({
        this.anonymousId,
        this.appVersion,
        this.conversationId,
        required this.currentUrl,
        this.deviceId,
        this.durationMs,
        this.entryPoint,
        this.environment,
        this.featureFlagKey,
        this.featureFlagVariant,
        this.lastContentPercentage,
        this.lastContentY,
        this.lastScrollPercentage,
        this.lastScrollY,
        this.lib,
        this.libVersion,
        this.maxContentPercentage,
        this.maxContentY,
        this.maxScrollPercentage,
        this.maxScrollY,
        this.messageId,
        this.nodeKey,
        this.pageviewId,
        required this.pathname,
        this.promptTemplateId,
        this.requestId,
        this.responseId,
        this.schemaVersion,
        this.sessionId,
        this.surface,
        this.taskType,
        this.tenantId,
        this.traceId,
        this.userId,
        this.windowId,
    });

    factory BrowserPageleaveEventExtraJson.fromJson(Map<String, dynamic> json) => BrowserPageleaveEventExtraJson(
        anonymousId: json["\u0024anonymous_id"],
        appVersion: json["\u0024app_version"],
        conversationId: json["\u0024conversation_id"],
        currentUrl: json["\u0024current_url"],
        deviceId: json["\u0024device_id"],
        durationMs: json["\u0024duration_ms"]?.toDouble(),
        entryPoint: json["\u0024entry_point"],
        environment: environmentValues.map[json["\u0024environment"]],
        featureFlagKey: json["\u0024feature_flag_key"],
        featureFlagVariant: json["\u0024feature_flag_variant"],
        lastContentPercentage: json["\u0024last_content_percentage"]?.toDouble(),
        lastContentY: json["\u0024last_content_y"]?.toDouble(),
        lastScrollPercentage: json["\u0024last_scroll_percentage"]?.toDouble(),
        lastScrollY: json["\u0024last_scroll_y"]?.toDouble(),
        lib: libValues.map[json["\u0024lib"]],
        libVersion: json["\u0024lib_version"],
        maxContentPercentage: json["\u0024max_content_percentage"]?.toDouble(),
        maxContentY: json["\u0024max_content_y"]?.toDouble(),
        maxScrollPercentage: json["\u0024max_scroll_percentage"]?.toDouble(),
        maxScrollY: json["\u0024max_scroll_y"]?.toDouble(),
        messageId: json["\u0024message_id"],
        nodeKey: json["\u0024node_key"],
        pageviewId: json["\u0024pageview_id"],
        pathname: json["\u0024pathname"],
        promptTemplateId: json["\u0024prompt_template_id"],
        requestId: json["\u0024request_id"],
        responseId: json["\u0024response_id"],
        schemaVersion: json["\u0024schema_version"],
        sessionId: json["\u0024session_id"],
        surface: json["\u0024surface"],
        taskType: json["\u0024task_type"],
        tenantId: json["\u0024tenant_id"],
        traceId: json["\u0024trace_id"],
        userId: json["\u0024user_id"],
        windowId: json["\u0024window_id"],
    );

    Map<String, dynamic> toJson() => {
        "\u0024anonymous_id": anonymousId,
        "\u0024app_version": appVersion,
        "\u0024conversation_id": conversationId,
        "\u0024current_url": currentUrl,
        "\u0024device_id": deviceId,
        "\u0024duration_ms": durationMs,
        "\u0024entry_point": entryPoint,
        "\u0024environment": environmentValues.reverse[environment],
        "\u0024feature_flag_key": featureFlagKey,
        "\u0024feature_flag_variant": featureFlagVariant,
        "\u0024last_content_percentage": lastContentPercentage,
        "\u0024last_content_y": lastContentY,
        "\u0024last_scroll_percentage": lastScrollPercentage,
        "\u0024last_scroll_y": lastScrollY,
        "\u0024lib": libValues.reverse[lib],
        "\u0024lib_version": libVersion,
        "\u0024max_content_percentage": maxContentPercentage,
        "\u0024max_content_y": maxContentY,
        "\u0024max_scroll_percentage": maxScrollPercentage,
        "\u0024max_scroll_y": maxScrollY,
        "\u0024message_id": messageId,
        "\u0024node_key": nodeKey,
        "\u0024pageview_id": pageviewId,
        "\u0024pathname": pathname,
        "\u0024prompt_template_id": promptTemplateId,
        "\u0024request_id": requestId,
        "\u0024response_id": responseId,
        "\u0024schema_version": schemaVersion,
        "\u0024session_id": sessionId,
        "\u0024surface": surface,
        "\u0024task_type": taskType,
        "\u0024tenant_id": tenantId,
        "\u0024trace_id": traceId,
        "\u0024user_id": userId,
        "\u0024window_id": windowId,
    };
}

class BrowserPageviewEvent {
    String deviceId;
    String eventId;
    BrowserPageviewEventEventName eventName;
    BrowserPageviewEventExtraJson extraJson;
    String occurredAt;
    String? scale;
    String? sessionId;
    String? traceId;
    double? value;

    BrowserPageviewEvent({
        required this.deviceId,
        required this.eventId,
        required this.eventName,
        required this.extraJson,
        required this.occurredAt,
        this.scale,
        this.sessionId,
        this.traceId,
        this.value,
    });

    factory BrowserPageviewEvent.fromJson(Map<String, dynamic> json) => BrowserPageviewEvent(
        deviceId: json["device_id"],
        eventId: json["event_id"],
        eventName: browserPageviewEventEventNameValues.map[json["event_name"]]!,
        extraJson: BrowserPageviewEventExtraJson.fromJson(json["extra_json"]),
        occurredAt: json["occurred_at"],
        scale: json["scale"],
        sessionId: json["session_id"],
        traceId: json["trace_id"],
        value: json["value"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "device_id": deviceId,
        "event_id": eventId,
        "event_name": browserPageviewEventEventNameValues.reverse[eventName],
        "extra_json": extraJson.toJson(),
        "occurred_at": occurredAt,
        "scale": scale,
        "session_id": sessionId,
        "trace_id": traceId,
        "value": value,
    };
}

enum BrowserPageviewEventEventName {
    PAGEVIEW
}

final browserPageviewEventEventNameValues = EnumValues({
    "pageview": BrowserPageviewEventEventName.PAGEVIEW
});

class BrowserPageviewEventExtraJson {
    String? anonymousId;
    String? appVersion;
    String? conversationId;
    String currentUrl;
    String? deviceId;
    String? entryPoint;
    Environment? environment;
    String? featureFlagKey;
    String? featureFlagVariant;
    Lib? lib;
    String? libVersion;
    String? messageId;
    String? nodeKey;
    String? pageviewId;
    String pathname;
    String? promptTemplateId;
    String? referrer;
    String? requestId;
    String? responseId;
    String? schemaVersion;
    String? sessionId;
    String? surface;
    String? taskType;
    String? tenantId;
    String? traceId;
    String? userId;
    String? windowId;

    BrowserPageviewEventExtraJson({
        this.anonymousId,
        this.appVersion,
        this.conversationId,
        required this.currentUrl,
        this.deviceId,
        this.entryPoint,
        this.environment,
        this.featureFlagKey,
        this.featureFlagVariant,
        this.lib,
        this.libVersion,
        this.messageId,
        this.nodeKey,
        this.pageviewId,
        required this.pathname,
        this.promptTemplateId,
        this.referrer,
        this.requestId,
        this.responseId,
        this.schemaVersion,
        this.sessionId,
        this.surface,
        this.taskType,
        this.tenantId,
        this.traceId,
        this.userId,
        this.windowId,
    });

    factory BrowserPageviewEventExtraJson.fromJson(Map<String, dynamic> json) => BrowserPageviewEventExtraJson(
        anonymousId: json["\u0024anonymous_id"],
        appVersion: json["\u0024app_version"],
        conversationId: json["\u0024conversation_id"],
        currentUrl: json["\u0024current_url"],
        deviceId: json["\u0024device_id"],
        entryPoint: json["\u0024entry_point"],
        environment: environmentValues.map[json["\u0024environment"]],
        featureFlagKey: json["\u0024feature_flag_key"],
        featureFlagVariant: json["\u0024feature_flag_variant"],
        lib: libValues.map[json["\u0024lib"]],
        libVersion: json["\u0024lib_version"],
        messageId: json["\u0024message_id"],
        nodeKey: json["\u0024node_key"],
        pageviewId: json["\u0024pageview_id"],
        pathname: json["\u0024pathname"],
        promptTemplateId: json["\u0024prompt_template_id"],
        referrer: json["\u0024referrer"],
        requestId: json["\u0024request_id"],
        responseId: json["\u0024response_id"],
        schemaVersion: json["\u0024schema_version"],
        sessionId: json["\u0024session_id"],
        surface: json["\u0024surface"],
        taskType: json["\u0024task_type"],
        tenantId: json["\u0024tenant_id"],
        traceId: json["\u0024trace_id"],
        userId: json["\u0024user_id"],
        windowId: json["\u0024window_id"],
    );

    Map<String, dynamic> toJson() => {
        "\u0024anonymous_id": anonymousId,
        "\u0024app_version": appVersion,
        "\u0024conversation_id": conversationId,
        "\u0024current_url": currentUrl,
        "\u0024device_id": deviceId,
        "\u0024entry_point": entryPoint,
        "\u0024environment": environmentValues.reverse[environment],
        "\u0024feature_flag_key": featureFlagKey,
        "\u0024feature_flag_variant": featureFlagVariant,
        "\u0024lib": libValues.reverse[lib],
        "\u0024lib_version": libVersion,
        "\u0024message_id": messageId,
        "\u0024node_key": nodeKey,
        "\u0024pageview_id": pageviewId,
        "\u0024pathname": pathname,
        "\u0024prompt_template_id": promptTemplateId,
        "\u0024referrer": referrer,
        "\u0024request_id": requestId,
        "\u0024response_id": responseId,
        "\u0024schema_version": schemaVersion,
        "\u0024session_id": sessionId,
        "\u0024surface": surface,
        "\u0024task_type": taskType,
        "\u0024tenant_id": tenantId,
        "\u0024trace_id": traceId,
        "\u0024user_id": userId,
        "\u0024window_id": windowId,
    };
}

class BrowserRageclickEvent {
    String deviceId;
    String eventId;
    BrowserRageclickEventEventName eventName;
    BrowserRageclickEventExtraJson extraJson;
    String occurredAt;
    String? scale;
    String? sessionId;
    String? traceId;
    double? value;

    BrowserRageclickEvent({
        required this.deviceId,
        required this.eventId,
        required this.eventName,
        required this.extraJson,
        required this.occurredAt,
        this.scale,
        this.sessionId,
        this.traceId,
        this.value,
    });

    factory BrowserRageclickEvent.fromJson(Map<String, dynamic> json) => BrowserRageclickEvent(
        deviceId: json["device_id"],
        eventId: json["event_id"],
        eventName: browserRageclickEventEventNameValues.map[json["event_name"]]!,
        extraJson: BrowserRageclickEventExtraJson.fromJson(json["extra_json"]),
        occurredAt: json["occurred_at"],
        scale: json["scale"],
        sessionId: json["session_id"],
        traceId: json["trace_id"],
        value: json["value"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "device_id": deviceId,
        "event_id": eventId,
        "event_name": browserRageclickEventEventNameValues.reverse[eventName],
        "extra_json": extraJson.toJson(),
        "occurred_at": occurredAt,
        "scale": scale,
        "session_id": sessionId,
        "trace_id": traceId,
        "value": value,
    };
}

enum BrowserRageclickEventEventName {
    INTERACTION_RAGECLICK
}

final browserRageclickEventEventNameValues = EnumValues({
    "interaction_rageclick": BrowserRageclickEventEventName.INTERACTION_RAGECLICK
});

class BrowserRageclickEventExtraJson {
    String? anonymousId;
    String? appVersion;
    double? clickCount;
    String? conversationId;
    String? deviceId;
    String elementsChain;
    String? entryPoint;
    Environment? environment;
    String? featureFlagKey;
    String? featureFlagVariant;
    Lib? lib;
    String? libVersion;
    String? messageId;
    String? nodeKey;
    String? pageviewId;
    String? promptTemplateId;
    String? requestId;
    String? responseId;
    String? schemaVersion;
    String? sessionId;
    String? surface;
    String? taskType;
    String? tenantId;
    String? traceId;
    String? userId;
    String? windowId;

    BrowserRageclickEventExtraJson({
        this.anonymousId,
        this.appVersion,
        this.clickCount,
        this.conversationId,
        this.deviceId,
        required this.elementsChain,
        this.entryPoint,
        this.environment,
        this.featureFlagKey,
        this.featureFlagVariant,
        this.lib,
        this.libVersion,
        this.messageId,
        this.nodeKey,
        this.pageviewId,
        this.promptTemplateId,
        this.requestId,
        this.responseId,
        this.schemaVersion,
        this.sessionId,
        this.surface,
        this.taskType,
        this.tenantId,
        this.traceId,
        this.userId,
        this.windowId,
    });

    factory BrowserRageclickEventExtraJson.fromJson(Map<String, dynamic> json) => BrowserRageclickEventExtraJson(
        anonymousId: json["\u0024anonymous_id"],
        appVersion: json["\u0024app_version"],
        clickCount: json["\u0024click_count"]?.toDouble(),
        conversationId: json["\u0024conversation_id"],
        deviceId: json["\u0024device_id"],
        elementsChain: json["\u0024elements_chain"],
        entryPoint: json["\u0024entry_point"],
        environment: environmentValues.map[json["\u0024environment"]],
        featureFlagKey: json["\u0024feature_flag_key"],
        featureFlagVariant: json["\u0024feature_flag_variant"],
        lib: libValues.map[json["\u0024lib"]],
        libVersion: json["\u0024lib_version"],
        messageId: json["\u0024message_id"],
        nodeKey: json["\u0024node_key"],
        pageviewId: json["\u0024pageview_id"],
        promptTemplateId: json["\u0024prompt_template_id"],
        requestId: json["\u0024request_id"],
        responseId: json["\u0024response_id"],
        schemaVersion: json["\u0024schema_version"],
        sessionId: json["\u0024session_id"],
        surface: json["\u0024surface"],
        taskType: json["\u0024task_type"],
        tenantId: json["\u0024tenant_id"],
        traceId: json["\u0024trace_id"],
        userId: json["\u0024user_id"],
        windowId: json["\u0024window_id"],
    );

    Map<String, dynamic> toJson() => {
        "\u0024anonymous_id": anonymousId,
        "\u0024app_version": appVersion,
        "\u0024click_count": clickCount,
        "\u0024conversation_id": conversationId,
        "\u0024device_id": deviceId,
        "\u0024elements_chain": elementsChain,
        "\u0024entry_point": entryPoint,
        "\u0024environment": environmentValues.reverse[environment],
        "\u0024feature_flag_key": featureFlagKey,
        "\u0024feature_flag_variant": featureFlagVariant,
        "\u0024lib": libValues.reverse[lib],
        "\u0024lib_version": libVersion,
        "\u0024message_id": messageId,
        "\u0024node_key": nodeKey,
        "\u0024pageview_id": pageviewId,
        "\u0024prompt_template_id": promptTemplateId,
        "\u0024request_id": requestId,
        "\u0024response_id": responseId,
        "\u0024schema_version": schemaVersion,
        "\u0024session_id": sessionId,
        "\u0024surface": surface,
        "\u0024task_type": taskType,
        "\u0024tenant_id": tenantId,
        "\u0024trace_id": traceId,
        "\u0024user_id": userId,
        "\u0024window_id": windowId,
    };
}

class CustomEvent {
    String deviceId;
    String eventId;
    String eventName;
    Map<String, dynamic> extraJson;
    String occurredAt;
    String? scale;
    String? sessionId;
    String? traceId;
    double? value;

    CustomEvent({
        required this.deviceId,
        required this.eventId,
        required this.eventName,
        required this.extraJson,
        required this.occurredAt,
        this.scale,
        this.sessionId,
        this.traceId,
        this.value,
    });

    factory CustomEvent.fromJson(Map<String, dynamic> json) => CustomEvent(
        deviceId: json["device_id"],
        eventId: json["event_id"],
        eventName: json["event_name"],
        extraJson: Map.from(json["extra_json"]).map((k, v) => MapEntry<String, dynamic>(k, v)),
        occurredAt: json["occurred_at"],
        scale: json["scale"],
        sessionId: json["session_id"],
        traceId: json["trace_id"],
        value: json["value"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "device_id": deviceId,
        "event_id": eventId,
        "event_name": eventName,
        "extra_json": Map.from(extraJson).map((k, v) => MapEntry<String, dynamic>(k, v)),
        "occurred_at": occurredAt,
        "scale": scale,
        "session_id": sessionId,
        "trace_id": traceId,
        "value": value,
    };
}

class DeadClickProps {
    String elementsChain;

    DeadClickProps({
        required this.elementsChain,
    });

    factory DeadClickProps.fromJson(Map<String, dynamic> json) => DeadClickProps(
        elementsChain: json["\u0024elements_chain"],
    );

    Map<String, dynamic> toJson() => {
        "\u0024elements_chain": elementsChain,
    };
}

class DerivedTextMeta {
    CaptureMode captureMode;
    bool? containsAttachment;
    bool? containsCode;
    String? excerpt;
    String? hash;
    double? lengthChars;
    bool? piiDetected;
    SensitiveCategory? sensitiveCategory;
    TokenBucket? tokenBucket;

    DerivedTextMeta({
        required this.captureMode,
        this.containsAttachment,
        this.containsCode,
        this.excerpt,
        this.hash,
        this.lengthChars,
        this.piiDetected,
        this.sensitiveCategory,
        this.tokenBucket,
    });

    factory DerivedTextMeta.fromJson(Map<String, dynamic> json) => DerivedTextMeta(
        captureMode: captureModeValues.map[json["capture_mode"]]!,
        containsAttachment: json["contains_attachment"],
        containsCode: json["contains_code"],
        excerpt: json["excerpt"],
        hash: json["hash"],
        lengthChars: json["length_chars"]?.toDouble(),
        piiDetected: json["pii_detected"],
        sensitiveCategory: sensitiveCategoryValues.map[json["sensitive_category"]],
        tokenBucket: tokenBucketValues.map[json["token_bucket"]],
    );

    Map<String, dynamic> toJson() => {
        "capture_mode": captureModeValues.reverse[captureMode],
        "contains_attachment": containsAttachment,
        "contains_code": containsCode,
        "excerpt": excerpt,
        "hash": hash,
        "length_chars": lengthChars,
        "pii_detected": piiDetected,
        "sensitive_category": sensitiveCategoryValues.reverse[sensitiveCategory],
        "token_bucket": tokenBucketValues.reverse[tokenBucket],
    };
}

enum TokenBucket {
    THE_0,
    THE_10012000,
    THE_150,
    THE_2000,
    THE_201500,
    THE_5011000,
    THE_51200
}

final tokenBucketValues = EnumValues({
    "0": TokenBucket.THE_0,
    "1001-2000": TokenBucket.THE_10012000,
    "1-50": TokenBucket.THE_150,
    "2000+": TokenBucket.THE_2000,
    "201-500": TokenBucket.THE_201500,
    "501-1000": TokenBucket.THE_5011000,
    "51-200": TokenBucket.THE_51200
});

enum MaskMode {
    ALL,
    OFF,
    SENSITIVE
}

final maskModeValues = EnumValues({
    "all": MaskMode.ALL,
    "off": MaskMode.OFF,
    "sensitive": MaskMode.SENSITIVE
});

class PageleaveProps {
    String currentUrl;
    double? durationMs;
    double? lastContentPercentage;
    double? lastContentY;
    double? lastScrollPercentage;
    double? lastScrollY;
    double? maxContentPercentage;
    double? maxContentY;
    double? maxScrollPercentage;
    double? maxScrollY;
    String pathname;

    PageleaveProps({
        required this.currentUrl,
        this.durationMs,
        this.lastContentPercentage,
        this.lastContentY,
        this.lastScrollPercentage,
        this.lastScrollY,
        this.maxContentPercentage,
        this.maxContentY,
        this.maxScrollPercentage,
        this.maxScrollY,
        required this.pathname,
    });

    factory PageleaveProps.fromJson(Map<String, dynamic> json) => PageleaveProps(
        currentUrl: json["\u0024current_url"],
        durationMs: json["\u0024duration_ms"]?.toDouble(),
        lastContentPercentage: json["\u0024last_content_percentage"]?.toDouble(),
        lastContentY: json["\u0024last_content_y"]?.toDouble(),
        lastScrollPercentage: json["\u0024last_scroll_percentage"]?.toDouble(),
        lastScrollY: json["\u0024last_scroll_y"]?.toDouble(),
        maxContentPercentage: json["\u0024max_content_percentage"]?.toDouble(),
        maxContentY: json["\u0024max_content_y"]?.toDouble(),
        maxScrollPercentage: json["\u0024max_scroll_percentage"]?.toDouble(),
        maxScrollY: json["\u0024max_scroll_y"]?.toDouble(),
        pathname: json["\u0024pathname"],
    );

    Map<String, dynamic> toJson() => {
        "\u0024current_url": currentUrl,
        "\u0024duration_ms": durationMs,
        "\u0024last_content_percentage": lastContentPercentage,
        "\u0024last_content_y": lastContentY,
        "\u0024last_scroll_percentage": lastScrollPercentage,
        "\u0024last_scroll_y": lastScrollY,
        "\u0024max_content_percentage": maxContentPercentage,
        "\u0024max_content_y": maxContentY,
        "\u0024max_scroll_percentage": maxScrollPercentage,
        "\u0024max_scroll_y": maxScrollY,
        "\u0024pathname": pathname,
    };
}

class PageviewProps {
    String currentUrl;
    String pathname;
    String? referrer;

    PageviewProps({
        required this.currentUrl,
        required this.pathname,
        this.referrer,
    });

    factory PageviewProps.fromJson(Map<String, dynamic> json) => PageviewProps(
        currentUrl: json["\u0024current_url"],
        pathname: json["\u0024pathname"],
        referrer: json["\u0024referrer"],
    );

    Map<String, dynamic> toJson() => {
        "\u0024current_url": currentUrl,
        "\u0024pathname": pathname,
        "\u0024referrer": referrer,
    };
}

class RageclickProps {
    double? clickCount;
    String elementsChain;

    RageclickProps({
        this.clickCount,
        required this.elementsChain,
    });

    factory RageclickProps.fromJson(Map<String, dynamic> json) => RageclickProps(
        clickCount: json["\u0024click_count"]?.toDouble(),
        elementsChain: json["\u0024elements_chain"],
    );

    Map<String, dynamic> toJson() => {
        "\u0024click_count": clickCount,
        "\u0024elements_chain": elementsChain,
    };
}

class ScrollDepthProps {
    double? lastContentPercentage;
    double? lastContentY;
    double? lastScrollPercentage;
    double? lastScrollY;
    double? maxContentPercentage;
    double? maxContentY;
    double? maxScrollPercentage;
    double? maxScrollY;

    ScrollDepthProps({
        this.lastContentPercentage,
        this.lastContentY,
        this.lastScrollPercentage,
        this.lastScrollY,
        this.maxContentPercentage,
        this.maxContentY,
        this.maxScrollPercentage,
        this.maxScrollY,
    });

    factory ScrollDepthProps.fromJson(Map<String, dynamic> json) => ScrollDepthProps(
        lastContentPercentage: json["\u0024last_content_percentage"]?.toDouble(),
        lastContentY: json["\u0024last_content_y"]?.toDouble(),
        lastScrollPercentage: json["\u0024last_scroll_percentage"]?.toDouble(),
        lastScrollY: json["\u0024last_scroll_y"]?.toDouble(),
        maxContentPercentage: json["\u0024max_content_percentage"]?.toDouble(),
        maxContentY: json["\u0024max_content_y"]?.toDouble(),
        maxScrollPercentage: json["\u0024max_scroll_percentage"]?.toDouble(),
        maxScrollY: json["\u0024max_scroll_y"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "\u0024last_content_percentage": lastContentPercentage,
        "\u0024last_content_y": lastContentY,
        "\u0024last_scroll_percentage": lastScrollPercentage,
        "\u0024last_scroll_y": lastScrollY,
        "\u0024max_content_percentage": maxContentPercentage,
        "\u0024max_content_y": maxContentY,
        "\u0024max_scroll_percentage": maxScrollPercentage,
        "\u0024max_scroll_y": maxScrollY,
    };
}

class EnumValues<T> {
    Map<String, T> map;
    late Map<T, String> reverseMap;

    EnumValues(this.map);

    Map<T, String> get reverse {
            reverseMap = map.map((k, v) => MapEntry(v, k));
            return reverseMap;
    }
}
