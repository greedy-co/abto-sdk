// GENERATED FILE — DO NOT EDIT.

package app.abto.sdk

data class Events (
    val aiPromptSubmittedProps: AIPromptSubmittedProps? = null,
    val aiResponseInteractedProps: AIResponseInteractedProps? = null,
    val aiResponseRenderedProps: AIResponseRenderedProps? = null,
    val autocaptureProps: AutocaptureProps? = null,
    val browserAIPromptSubmittedEvent: BrowserAIPromptSubmittedEvent? = null,
    val browserAIResponseInteractedEvent: BrowserAIResponseInteractedEvent? = null,
    val browserAIResponseRenderedEvent: BrowserAIResponseRenderedEvent? = null,
    val browserAutocaptureEvent: BrowserAutocaptureEvent? = null,
    val browserContextProperties: BrowserContextProperties? = null,
    val browserDeadClickEvent: BrowserDeadClickEvent? = null,
    val browserEventBatchRequest: BrowserEventBatchRequest? = null,
    val browserEventBatchResponse: BrowserEventBatchResponse? = null,
    val browserEventResult: BrowserEventResult? = null,
    val browserEventResultCode: BrowserEventResultCode? = null,
    val browserEventResultStatus: BrowserEventResultStatus? = null,
    val browserIngestEvent: BrowserIngestEvent? = null,
    val browserPageleaveEvent: BrowserPageleaveEvent? = null,
    val browserPageviewEvent: BrowserPageviewEvent? = null,
    val browserRageclickEvent: BrowserRageclickEvent? = null,
    val customEvent: CustomEvent? = null,
    val deadClickProps: DeadClickProps? = null,
    val derivedTextMeta: DerivedTextMeta? = null,
    val maskMode: MaskMode? = null,
    val metricValue: Double? = null,
    val pageleaveProps: PageleaveProps? = null,
    val pageviewProps: PageviewProps? = null,
    val rageclickProps: RageclickProps? = null,
    val scrollDepthProps: ScrollDepthProps? = null,
    val tokenBucket: TokenBucket? = null
)

data class AIPromptSubmittedProps (
    val captureMode: CaptureMode,
    val containsAttachment: Boolean? = null,
    val containsCode: Boolean? = null,
    val language: String? = null,
    val piiDetected: Boolean? = null,
    val promptHash: String? = null,
    val promptLengthChars: Double? = null,
    val promptText: String? = null,
    val promptTokensEstimated: Double? = null,
    val sensitiveCategory: SensitiveCategoryUnion? = null
)

enum class CaptureMode {
    Full,
    Hash,
    MetadataOnly,
    Off
}

sealed class SensitiveCategoryUnion {
    class EnumArrayValue(val value: List<SensitiveCategory>) : SensitiveCategoryUnion()
    class EnumValue(val value: SensitiveCategory)            : SensitiveCategoryUnion()
}

enum class SensitiveCategory {
    Credential,
    CustomerData,
    Finance,
    Healthcare,
    InternalDocument,
    Legal,
    Pii,
    SourceCode,
    UnknownSensitive
}

data class AIResponseInteractedProps (
    val destination: String? = null,
    val interactionType: AIInteractionType,
    val requestID: String? = null,
    val responseID: String? = null,
    val source: String? = null,
    val timeSinceResponseMS: Double? = null,
    val visibleOutputRatio: Double? = null
)

enum class AIInteractionType {
    Aborted,
    Accepted,
    Collapsed,
    Copied,
    Downloaded,
    Expanded,
    Inserted,
    RatedNegative,
    RatedPositive,
    Regenerated,
    Rejected,
    Shared
}

data class AIResponseRenderedProps (
    val captureMode: CaptureMode,
    val outputLengthChars: Double? = null,
    val responseID: String,
    val responseText: String? = null,
    val timeToRenderMS: Double? = null,
    val visibleOutputRatio: Double? = null
)

data class AutocaptureProps (
    val aiAction: String? = null,
    val ceVersion: Double,
    val elName: String? = null,
    val elText: String? = null,
    val elValue: String? = null,
    val elementsChain: String,
    val eventType: AutocaptureEventType,
    val href: String? = null,
    val inputType: String? = null,
    val requestID: String? = null,
    val responseID: String? = null,
    val selectionLength: Double? = null,
    val tagName: String? = null
)

enum class AutocaptureEventType {
    Change,
    Click,
    Copy,
    Submit
}

data class BrowserAIPromptSubmittedEvent (
    val deviceID: String,
    val eventID: String,
    val eventName: BrowserAIPromptSubmittedEventEventName,
    val extraJSON: BrowserAIPromptSubmittedEventExtraJSON,
    val occurredAt: String,
    val scale: String? = null,
    val sessionID: String? = null,
    val traceID: String? = null,
    val value: Double? = null
)

enum class BrowserAIPromptSubmittedEventEventName {
    LlmPromptSubmitted
}

data class BrowserAIPromptSubmittedEventExtraJSON (
    val anonymousID: String? = null,
    val appVersion: String? = null,
    val captureMode: CaptureMode,
    val containsAttachment: Boolean? = null,
    val containsCode: Boolean? = null,
    val conversationID: String? = null,
    val deviceID: String? = null,
    val entryPoint: String? = null,
    val environment: Environment? = null,
    val featureFlagKey: String? = null,
    val featureFlagVariant: String? = null,
    val language: String? = null,
    val lib: LIB? = null,
    val libVersion: String? = null,
    val messageID: String? = null,
    val nodeKey: String? = null,
    val pageviewID: String? = null,
    val piiDetected: Boolean? = null,
    val promptHash: String? = null,
    val promptLengthChars: Double? = null,
    val promptTemplateID: String? = null,
    val promptText: String? = null,
    val promptTokensEstimated: Double? = null,
    val requestID: String? = null,
    val responseID: String? = null,
    val schemaVersion: String? = null,
    val sensitiveCategory: SensitiveCategoryUnion? = null,
    val sessionID: String? = null,
    val surface: String? = null,
    val taskType: String? = null,
    val tenantID: String? = null,
    val traceID: String? = null,
    val userID: String? = null,
    val windowID: String? = null
)

enum class Environment {
    Development,
    Production
}

enum class LIB {
    Android,
    Flutter,
    Ios,
    Web
}

data class BrowserAIResponseInteractedEvent (
    val deviceID: String,
    val eventID: String,
    val eventName: BrowserAIResponseInteractedEventEventName,
    val extraJSON: BrowserAIResponseInteractedEventExtraJSON,
    val occurredAt: String,
    val scale: String? = null,
    val sessionID: String? = null,
    val traceID: String? = null,
    val value: Double? = null
)

enum class BrowserAIResponseInteractedEventEventName {
    LlmResponseInteracted
}

data class BrowserAIResponseInteractedEventExtraJSON (
    val anonymousID: String? = null,
    val appVersion: String? = null,
    val conversationID: String? = null,
    val destination: String? = null,
    val deviceID: String? = null,
    val entryPoint: String? = null,
    val environment: Environment? = null,
    val featureFlagKey: String? = null,
    val featureFlagVariant: String? = null,
    val interactionType: AIInteractionType,
    val lib: LIB? = null,
    val libVersion: String? = null,
    val messageID: String? = null,
    val nodeKey: String? = null,
    val pageviewID: String? = null,
    val promptTemplateID: String? = null,
    val requestID: String? = null,
    val responseID: String? = null,
    val schemaVersion: String? = null,
    val sessionID: String? = null,
    val source: String? = null,
    val surface: String? = null,
    val taskType: String? = null,
    val tenantID: String? = null,
    val timeSinceResponseMS: Double? = null,
    val traceID: String? = null,
    val userID: String? = null,
    val visibleOutputRatio: Double? = null,
    val windowID: String? = null
)

data class BrowserAIResponseRenderedEvent (
    val deviceID: String,
    val eventID: String,
    val eventName: BrowserAIResponseRenderedEventEventName,
    val extraJSON: BrowserAIResponseRenderedEventExtraJSON,
    val occurredAt: String,
    val scale: String? = null,
    val sessionID: String? = null,
    val traceID: String? = null,
    val value: Double? = null
)

enum class BrowserAIResponseRenderedEventEventName {
    LlmResponseRendered
}

data class BrowserAIResponseRenderedEventExtraJSON (
    val anonymousID: String? = null,
    val appVersion: String? = null,
    val captureMode: CaptureMode,
    val conversationID: String? = null,
    val deviceID: String? = null,
    val entryPoint: String? = null,
    val environment: Environment? = null,
    val featureFlagKey: String? = null,
    val featureFlagVariant: String? = null,
    val lib: LIB? = null,
    val libVersion: String? = null,
    val messageID: String? = null,
    val nodeKey: String? = null,
    val outputLengthChars: Double? = null,
    val pageviewID: String? = null,
    val promptTemplateID: String? = null,
    val requestID: String? = null,
    val responseID: String,
    val responseText: String? = null,
    val schemaVersion: String? = null,
    val sessionID: String? = null,
    val surface: String? = null,
    val taskType: String? = null,
    val tenantID: String? = null,
    val timeToRenderMS: Double? = null,
    val traceID: String? = null,
    val userID: String? = null,
    val visibleOutputRatio: Double? = null,
    val windowID: String? = null
)

data class BrowserAutocaptureEvent (
    val deviceID: String,
    val eventID: String,
    val eventName: BrowserAutocaptureEventEventName,
    val extraJSON: BrowserAutocaptureEventExtraJSON,
    val occurredAt: String,
    val scale: String? = null,
    val sessionID: String? = null,
    val traceID: String? = null,
    val value: Double? = null
)

enum class BrowserAutocaptureEventEventName {
    InteractionAutocaptured
}

data class BrowserAutocaptureEventExtraJSON (
    val aiAction: String? = null,
    val anonymousID: String? = null,
    val appVersion: String? = null,
    val ceVersion: Double,
    val conversationID: String? = null,
    val deviceID: String? = null,
    val elName: String? = null,
    val elText: String? = null,
    val elValue: String? = null,
    val elementsChain: String,
    val entryPoint: String? = null,
    val environment: Environment? = null,
    val eventType: AutocaptureEventType,
    val featureFlagKey: String? = null,
    val featureFlagVariant: String? = null,
    val href: String? = null,
    val inputType: String? = null,
    val lib: LIB? = null,
    val libVersion: String? = null,
    val messageID: String? = null,
    val nodeKey: String? = null,
    val pageviewID: String? = null,
    val promptTemplateID: String? = null,
    val requestID: String? = null,
    val responseID: String? = null,
    val schemaVersion: String? = null,
    val selectionLength: Double? = null,
    val sessionID: String? = null,
    val surface: String? = null,
    val tagName: String? = null,
    val taskType: String? = null,
    val tenantID: String? = null,
    val traceID: String? = null,
    val userID: String? = null,
    val windowID: String? = null
)

data class BrowserContextProperties (
    val anonymousID: String? = null,
    val appVersion: String? = null,
    val conversationID: String? = null,
    val deviceID: String? = null,
    val entryPoint: String? = null,
    val environment: Environment? = null,
    val featureFlagKey: String? = null,
    val featureFlagVariant: String? = null,
    val lib: LIB? = null,
    val libVersion: String? = null,
    val messageID: String? = null,
    val nodeKey: String? = null,
    val pageviewID: String? = null,
    val promptTemplateID: String? = null,
    val requestID: String? = null,
    val responseID: String? = null,
    val schemaVersion: String? = null,
    val sessionID: String? = null,
    val surface: String? = null,
    val taskType: String? = null,
    val tenantID: String? = null,
    val traceID: String? = null,
    val userID: String? = null,
    val windowID: String? = null
)

data class BrowserDeadClickEvent (
    val deviceID: String,
    val eventID: String,
    val eventName: BrowserDeadClickEventEventName,
    val extraJSON: BrowserDeadClickEventExtraJSON,
    val occurredAt: String,
    val scale: String? = null,
    val sessionID: String? = null,
    val traceID: String? = null,
    val value: Double? = null
)

enum class BrowserDeadClickEventEventName {
    InteractionDeadclick
}

data class BrowserDeadClickEventExtraJSON (
    val anonymousID: String? = null,
    val appVersion: String? = null,
    val conversationID: String? = null,
    val deviceID: String? = null,
    val elementsChain: String,
    val entryPoint: String? = null,
    val environment: Environment? = null,
    val featureFlagKey: String? = null,
    val featureFlagVariant: String? = null,
    val lib: LIB? = null,
    val libVersion: String? = null,
    val messageID: String? = null,
    val nodeKey: String? = null,
    val pageviewID: String? = null,
    val promptTemplateID: String? = null,
    val requestID: String? = null,
    val responseID: String? = null,
    val schemaVersion: String? = null,
    val sessionID: String? = null,
    val surface: String? = null,
    val taskType: String? = null,
    val tenantID: String? = null,
    val traceID: String? = null,
    val userID: String? = null,
    val windowID: String? = null
)

data class BrowserEventBatchRequest (
    val batch: List<BrowserEvent>
)

data class BrowserEvent (
    val deviceID: String,
    val eventID: String,
    val eventName: String,
    val extraJSON: Map<String, JSONValue>,
    val occurredAt: String,
    val scale: String? = null,
    val sessionID: String? = null,
    val traceID: String? = null,
    val value: Double? = null
)

sealed class JSONValue {
    class BoolValue(val value: Boolean)                           : JSONValue()
    class DoubleValue(val value: Double)                          : JSONValue()
    class StringValue(val value: String)                          : JSONValue()
    class UnionArrayValue(val value: List<JSONValueElement>)      : JSONValue()
    class UnionMapValue(val value: Map<String, JSONValueElement>) : JSONValue()
    class NullValue()                                             : JSONValue()
}

sealed class JSONValueElement {
    class BoolValue(val value: Boolean)  : JSONValueElement()
    class DoubleValue(val value: Double) : JSONValueElement()
    class StringValue(val value: String) : JSONValueElement()
    class NullValue()                    : JSONValueElement()
}

data class BrowserEventBatchResponse (
    val results: Map<String, BrowserEventResult>
)

data class BrowserEventResult (
    val code: BrowserEventResultCode? = null,
    val result: BrowserEventResultStatus
)

enum class BrowserEventResultCode {
    InvalidEvent,
    MissingRequired,
    ReservedName,
    SchemaDiscovered,
    SchemaDrift,
    SchemaEnumMismatch,
    SchemaRequiredMissing,
    SchemaTypeMismatch,
    StorageUnavailable
}

enum class BrowserEventResultStatus {
    Drop,
    Ok,
    Retry,
    Warning
}

data class BrowserIngestEvent (
    val deviceID: String,
    val eventID: String,
    val eventName: String,
    val extraJSON: Map<String, JSONValue>,
    val occurredAt: String,
    val scale: String? = null,
    val sessionID: String? = null,
    val traceID: String? = null,

    /**
     * Finite decimal with at most 38 integer digits and 12 fractional digits
     */
    val value: Double? = null
)

data class BrowserPageleaveEvent (
    val deviceID: String,
    val eventID: String,
    val eventName: BrowserPageleaveEventEventName,
    val extraJSON: BrowserPageleaveEventExtraJSON,
    val occurredAt: String,
    val scale: String? = null,
    val sessionID: String? = null,
    val traceID: String? = null,
    val value: Double? = null
)

enum class BrowserPageleaveEventEventName {
    Pageleave
}

data class BrowserPageleaveEventExtraJSON (
    val anonymousID: String? = null,
    val appVersion: String? = null,
    val conversationID: String? = null,
    val currentURL: String,
    val deviceID: String? = null,
    val durationMS: Double? = null,
    val entryPoint: String? = null,
    val environment: Environment? = null,
    val featureFlagKey: String? = null,
    val featureFlagVariant: String? = null,
    val lastContentPercentage: Double? = null,
    val lastContentY: Double? = null,
    val lastScrollPercentage: Double? = null,
    val lastScrollY: Double? = null,
    val lib: LIB? = null,
    val libVersion: String? = null,
    val maxContentPercentage: Double? = null,
    val maxContentY: Double? = null,
    val maxScrollPercentage: Double? = null,
    val maxScrollY: Double? = null,
    val messageID: String? = null,
    val nodeKey: String? = null,
    val pageviewID: String? = null,
    val pathname: String,
    val promptTemplateID: String? = null,
    val requestID: String? = null,
    val responseID: String? = null,
    val schemaVersion: String? = null,
    val sessionID: String? = null,
    val surface: String? = null,
    val taskType: String? = null,
    val tenantID: String? = null,
    val traceID: String? = null,
    val userID: String? = null,
    val windowID: String? = null
)

data class BrowserPageviewEvent (
    val deviceID: String,
    val eventID: String,
    val eventName: BrowserPageviewEventEventName,
    val extraJSON: BrowserPageviewEventExtraJSON,
    val occurredAt: String,
    val scale: String? = null,
    val sessionID: String? = null,
    val traceID: String? = null,
    val value: Double? = null
)

enum class BrowserPageviewEventEventName {
    Pageview
}

data class BrowserPageviewEventExtraJSON (
    val anonymousID: String? = null,
    val appVersion: String? = null,
    val conversationID: String? = null,
    val currentURL: String,
    val deviceID: String? = null,
    val entryPoint: String? = null,
    val environment: Environment? = null,
    val featureFlagKey: String? = null,
    val featureFlagVariant: String? = null,
    val lib: LIB? = null,
    val libVersion: String? = null,
    val messageID: String? = null,
    val nodeKey: String? = null,
    val pageviewID: String? = null,
    val pathname: String,
    val promptTemplateID: String? = null,
    val referrer: String? = null,
    val requestID: String? = null,
    val responseID: String? = null,
    val schemaVersion: String? = null,
    val sessionID: String? = null,
    val surface: String? = null,
    val taskType: String? = null,
    val tenantID: String? = null,
    val traceID: String? = null,
    val userID: String? = null,
    val windowID: String? = null
)

data class BrowserRageclickEvent (
    val deviceID: String,
    val eventID: String,
    val eventName: BrowserRageclickEventEventName,
    val extraJSON: BrowserRageclickEventExtraJSON,
    val occurredAt: String,
    val scale: String? = null,
    val sessionID: String? = null,
    val traceID: String? = null,
    val value: Double? = null
)

enum class BrowserRageclickEventEventName {
    InteractionRageclick
}

data class BrowserRageclickEventExtraJSON (
    val anonymousID: String? = null,
    val appVersion: String? = null,
    val clickCount: Double? = null,
    val conversationID: String? = null,
    val deviceID: String? = null,
    val elementsChain: String,
    val entryPoint: String? = null,
    val environment: Environment? = null,
    val featureFlagKey: String? = null,
    val featureFlagVariant: String? = null,
    val lib: LIB? = null,
    val libVersion: String? = null,
    val messageID: String? = null,
    val nodeKey: String? = null,
    val pageviewID: String? = null,
    val promptTemplateID: String? = null,
    val requestID: String? = null,
    val responseID: String? = null,
    val schemaVersion: String? = null,
    val sessionID: String? = null,
    val surface: String? = null,
    val taskType: String? = null,
    val tenantID: String? = null,
    val traceID: String? = null,
    val userID: String? = null,
    val windowID: String? = null
)

data class CustomEvent (
    val deviceID: String,
    val eventID: String,
    val eventName: String,
    val extraJSON: Map<String, JSONValue>,
    val occurredAt: String,
    val scale: String? = null,
    val sessionID: String? = null,
    val traceID: String? = null,
    val value: Double? = null
)

data class DeadClickProps (
    val elementsChain: String
)

data class DerivedTextMeta (
    val captureMode: CaptureMode,
    val containsAttachment: Boolean? = null,
    val containsCode: Boolean? = null,
    val excerpt: String? = null,
    val hash: String? = null,
    val lengthChars: Double? = null,
    val piiDetected: Boolean? = null,
    val sensitiveCategory: SensitiveCategory? = null,
    val tokenBucket: TokenBucket? = null
)

enum class TokenBucket {
    The0,
    The10012000,
    The150,
    The2000,
    The201500,
    The5011000,
    The51200
}

enum class MaskMode {
    All,
    Off,
    Sensitive
}

data class PageleaveProps (
    val currentURL: String,
    val durationMS: Double? = null,
    val lastContentPercentage: Double? = null,
    val lastContentY: Double? = null,
    val lastScrollPercentage: Double? = null,
    val lastScrollY: Double? = null,
    val maxContentPercentage: Double? = null,
    val maxContentY: Double? = null,
    val maxScrollPercentage: Double? = null,
    val maxScrollY: Double? = null,
    val pathname: String
)

data class PageviewProps (
    val currentURL: String,
    val pathname: String,
    val referrer: String? = null
)

data class RageclickProps (
    val clickCount: Double? = null,
    val elementsChain: String
)

data class ScrollDepthProps (
    val lastContentPercentage: Double? = null,
    val lastContentY: Double? = null,
    val lastScrollPercentage: Double? = null,
    val lastScrollY: Double? = null,
    val maxContentPercentage: Double? = null,
    val maxContentY: Double? = null,
    val maxScrollPercentage: Double? = null,
    val maxScrollY: Double? = null
)
