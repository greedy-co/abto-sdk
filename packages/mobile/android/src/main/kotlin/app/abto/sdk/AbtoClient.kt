package app.abto.sdk

import kotlin.math.abs

private const val METRIC_ABSOLUTE_LIMIT = 1e38
private const val METRIC_MAX_FRACTION_DIGITS = 12
private const val MAX_SCALE_LENGTH = 16

internal fun abtoMetricValue(value: Double?): Double? {
    if (value == null || !value.isFinite() || abs(value) >= METRIC_ABSOLUTE_LIMIT) return null
    val parts = abs(value).toString().lowercase().split("e", limit = 2)
    val fractionDigits = parts[0].substringAfter('.', "").trimEnd('0').length
    val exponent = parts.getOrNull(1)?.toIntOrNull() ?: 0
    return value.takeIf { maxOf(0, fractionDigits - exponent) <= METRIC_MAX_FRACTION_DIGITS }
}

internal fun abtoScaleValue(value: String?): String? =
    value?.takeIf { it.length <= MAX_SCALE_LENGTH }

internal fun abtoEventNameIssue(event: String, allowSystemEvent: Boolean = false): String? = when {
    event.isBlank() -> "must not be blank"
    event.contains('\u0000') -> "must not contain U+0000"
    event.startsWith("\$") -> "must not start with \$"
    !allowSystemEvent && event in ABTO_RESERVED_EVENT_NAMES ->
        "must not use an ABTO system event name"
    event.length > ABTO_EVENT_NAME_MAX_LENGTH ->
        "must be at most $ABTO_EVENT_NAME_MAX_LENGTH UTF-16 code units"
    else -> null
}

private val envelopeContextKeys = mapOf(
    "trace_id" to "\$trace_id",
    "feature_id" to "\$node_key",
    "task_type" to "\$task_type",
    "surface" to "\$surface",
    "request_id" to "\$request_id",
    "response_id" to "\$response_id",
)

/**
 * ABTO SDK entry point for Android/JVM.
 * Uses the same event contract as the Browser SDK and posts `{"batch": […]}`
 * to the Analytics ingestion contract: event_id, device_id, event_name, occurred_at, and extra_json.
 */
class AbtoClient(
    val config: AbtoConfig,
    store: AbtoKeyValueStore = AbtoInMemoryStore(),
) {
    private val context = AbtoContext(store)
    private val transport = AbtoTransport(config)

    /** Attribution axis shared by Analytics and the Gateway's `x-abto-device-id`. */
    val deviceId: String get() = context.anonymousId

    /** Session identifier for the current SDK client lifecycle. */
    val sessionId: String get() = context.sessionId

    fun identify(userId: String, tenantId: String? = null) {
        context.identify(userId, tenantId)
    }

    fun reset() {
        context.reset()
    }

    /** Manual event delivery, the default path for tracking behavior before an LLM call. */
    fun capture(
        event: String,
        properties: Map<String, Any?> = emptyMap(),
        envelope: Map<String, Any?> = emptyMap(),
        value: Double? = null,
        scale: String? = null,
    ): Boolean = captureEvent(event, properties, envelope, value, scale)

    internal fun captureSystemEvent(
        event: String,
        systemProperties: Map<String, Any?>,
        properties: Map<String, Any?> = emptyMap(),
        envelope: Map<String, Any?> = emptyMap(),
    ): Boolean = captureEvent(
        event,
        properties,
        envelope,
        systemProperties = systemProperties,
        allowSystemEvent = true,
    )

    private fun captureEvent(
        event: String,
        properties: Map<String, Any?> = emptyMap(),
        envelope: Map<String, Any?> = emptyMap(),
        value: Double? = null,
        scale: String? = null,
        systemProperties: Map<String, Any?> = emptyMap(),
        allowSystemEvent: Boolean = false,
    ): Boolean {
        abtoEventNameIssue(event, allowSystemEvent)?.let { issue ->
            System.err.println("[abto] event was dropped: $issue.")
            return false
        }
        val traceId = envelope["trace_id"] as? String
        val captured = buildMap<String, Any?> {
            put("event_id", uuidV7())
            put("device_id", context.anonymousId)
            put("session_id", context.sessionId)
            traceId?.let { put("trace_id", it) }
            put("event_name", event)
            abtoMetricValue(value)?.let { put("value", it) }
            abtoScaleValue(scale)?.let { put("scale", it) }
            put("occurred_at", isoTimestamp())
            put(
                "extra_json",
                buildMap {
                    putAll(
                        properties
                            .filterValues { it != null }
                            .filterKeys { !it.startsWith("\$") },
                    )
                    putAll(systemProperties.filterValues { it != null })
                    put("\$lib", "android")
                    put("\$environment", config.environment.wireName)
                    put("\$schema_version", ABTO_SCHEMA_VERSION)
                    put("\$device_id", context.anonymousId)
                    put("\$anonymous_id", context.anonymousId)
                    put("\$session_id", context.sessionId)
                    context.userId?.let { put("\$user_id", it) }
                    context.tenantId?.let { put("\$tenant_id", it) }
                    for ((key, item) in envelope) {
                        val contextKey = envelopeContextKeys[key] ?: continue
                        if (item != null) put(contextKey, item)
                    }
                },
            )
        }
        if (config.debug) {
            println("[abto] $event $captured")
        }
        transport.enqueue(captured)
        return true
    }

    fun startLlmTrace(featureId: String, taskType: String? = null, surface: String? = null): AbtoLlmTrace =
        AbtoLlmTrace(this, featureId, taskType, surface)

    fun flush(onComplete: Runnable? = null) {
        transport.flush(onComplete)
    }
}

/** Lifecycle of one LLM call, joining prior behavior by trace_id and Gateway cost and latency by request_id. */
class AbtoLlmTrace internal constructor(
    private val client: AbtoClient,
    val featureId: String,
    private val taskType: String?,
    private val surface: String?,
) {
    val traceId: String = uuidV7TraceId()
    var requestId: String? = null
        private set

    /** Reads x-abto-request-id from Gateway response headers and attaches it to later events. */
    fun attachRequestId(headers: Map<String?, List<String>>): String? {
        val id = headers.entries
            .firstOrNull { it.key?.lowercase() == "x-abto-request-id" }
            ?.value?.firstOrNull { it.isNotEmpty() }
        if (id != null) requestId = id
        return id
    }

    fun attach(requestId: String) {
        this.requestId = requestId
    }

    fun submitPrompt(prompt: String? = null, language: String? = null) {
        client.captureSystemEvent(
            "llm_prompt_submitted",
            systemProperties = buildMap {
                put("\$capture_mode", "metadata_only")
                prompt?.let {
                    put("\$prompt_length_chars", it.length)
                }
                language?.let { put("\$language", it) }
            },
            envelope = envelope(),
        )
    }

    fun markResponseVisible(responseId: String, responseText: String? = null, timeToVisibleMs: Int? = null) {
        client.captureSystemEvent(
            "llm_response_rendered",
            systemProperties = buildMap {
                put("\$capture_mode", "metadata_only")
                put("\$response_id", responseId)
                responseText?.let { put("\$output_length_chars", it.length) }
                timeToVisibleMs?.let { put("\$time_to_render_ms", it) }
            },
            envelope = envelope(mapOf("response_id" to responseId)),
        )
    }

    fun captureOutcome(
        interactionType: AbtoResponseInteraction,
        responseId: String? = null,
        extra: Map<String, Any?> = emptyMap(),
    ) {
        captureCanonicalOutcome(interactionType.wireValue, responseId, extra)
    }

    @Deprecated("Use the AbtoResponseInteraction overload. String values remain supported during the 0.x compatibility window.")
    fun captureOutcome(
        interactionType: String,
        responseId: String? = null,
        extra: Map<String, Any?> = emptyMap(),
    ) {
        val canonical = AbtoResponseInteraction.fromWireValue(interactionType)
        if (canonical == null) {
            System.err.println("[abto] response interaction was dropped: unsupported canonical type. Use a custom event for other product actions.")
            return
        }
        captureCanonicalOutcome(canonical.wireValue, responseId, extra)
    }

    private fun captureCanonicalOutcome(
        interactionType: String,
        responseId: String?,
        extra: Map<String, Any?>,
    ) {
        client.captureSystemEvent(
            "llm_response_interacted",
            systemProperties = buildMap {
                put("\$interaction_type", interactionType)
                responseId?.let { put("\$response_id", it) }
                requestId?.let { put("\$request_id", it) }
            },
            properties = extra,
            envelope = envelope(if (responseId != null) mapOf("response_id" to responseId) else emptyMap()),
        )
    }

    private fun envelope(overrides: Map<String, Any?> = emptyMap()): Map<String, Any?> = buildMap {
        put("feature_id", featureId)
        put("trace_id", traceId)
        taskType?.let { put("task_type", it) }
        surface?.let { put("surface", it) }
        requestId?.let { put("request_id", it) }
        putAll(overrides)
    }
}
