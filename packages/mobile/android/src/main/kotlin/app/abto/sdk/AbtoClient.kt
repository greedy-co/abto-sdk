package app.abto.sdk

import kotlin.math.abs


internal fun abtoMetricValue(value: Double?): Double? {
    if (value == null || !value.isFinite() || abs(value) >= ABTO_METRIC_ABSOLUTE_LIMIT) return null
    val parts = abs(value).toString().lowercase().split("e", limit = 2)
    val fractionDigits = parts[0].substringAfter('.', "").trimEnd('0').length
    val exponent = parts.getOrNull(1)?.toIntOrNull() ?: 0
    return value.takeIf { maxOf(0, fractionDigits - exponent) <= ABTO_METRIC_MAX_FRACTION_DIGITS }
}

internal fun abtoScaleValue(value: String?): String? =
    value?.takeIf { !it.contains('\u0000') && it.length <= ABTO_SCALE_MAX_LENGTH }

// Mirrors the shallow JsonValue contract using native collection types.
internal fun abtoValidProperties(properties: Map<String, Any?>): Boolean {
    fun scalar(v: Any?): Boolean = v == null || v is Boolean ||
        (v is String && !v.contains('\u0000')) || (v is Number && v.toDouble().isFinite())
    fun value(v: Any?): Boolean = scalar(v) || (v is List<*> && v.all(::scalar)) ||
        (v is Map<*, *> && v.all { (k, item) -> k is String && !k.contains('\u0000') && scalar(item) })
    return properties.all { (k, v) -> !k.startsWith("$") && !k.contains('\u0000') && k !in ABTO_CUSTOM_METRIC_FIELDS && value(v) }
}

internal fun abtoEventNameIssue(event: String): String? = when {
    event.isBlank() -> ABTO_ERR_EVENT_NAME_BLANK
    event.contains('\u0000') -> ABTO_ERR_EVENT_NAME_NUL
    event.startsWith("\$") -> ABTO_ERR_EVENT_NAME_DOLLAR_PREFIX
    event in ABTO_RESERVED_EVENT_NAMES -> ABTO_ERR_EVENT_NAME_RESERVED
    event.length > ABTO_EVENT_NAME_MAX_LENGTH -> ABTO_ERR_EVENT_NAME_TOO_LONG
    else -> null
}

// trace_id rides as a first-class wire field, so it is not copied into the bag.
private val envelopeContextKeys = mapOf(
    "feature_id" to "\$feature_id",
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

    /** Sends optional [value] and [scale] as metric columns and optional [properties] as extra_json. */
    fun capture(
        event: String,
        value: Number? = null,
        scale: String? = null,
        properties: Map<String, Any?> = emptyMap(),
    ) {
        abtoEventNameIssue(event)?.let { issue ->
            System.err.println(ABTO_ERR_EVENT_DROPPED.replace("{issue}", issue))
            return
        }
        if ((value != null && abtoMetricValue(value.toDouble()) == null) || (scale != null && abtoScaleValue(scale) == null) || !abtoValidProperties(properties)) {
            System.err.println(ABTO_ERR_CUSTOM_CAPTURE_INVALID)
            return
        }
        captureEvent(event, value = value?.toDouble(), scale = scale, properties = properties)
    }

    internal fun captureSystemEvent(
        event: String,
        systemProperties: Map<String, Any?>,
        envelope: Map<String, Any?> = emptyMap(),
    ) = captureEvent(event, envelope, systemProperties = systemProperties)

    /**
     * Builds and enqueues one event. Names are checked by the public [capture]; the SDK's own
     * system event names are constants and need no check.
     */
    private fun captureEvent(
        event: String,
        envelope: Map<String, Any?> = emptyMap(),
        value: Double? = null,
        scale: String? = null,
        systemProperties: Map<String, Any?> = emptyMap(),
        properties: Map<String, Any?> = emptyMap(),
    ) {
        val traceId = envelope["trace_id"] as? String
        val captured = buildMap<String, Any?> {
            put("event_id", uuidV7())
            put("device_id", context.anonymousId)
            put("session_id", context.sessionId)
            traceId?.let { put("trace_id", it) }
            put("event_name", event)
            value?.let { put("value", it) }
            scale?.let { put("scale", it) }
            put("occurred_at", isoTimestamp())
            // The bag holds only what no first-class wire field carries. device_id, session_id and
            // trace_id ride at the top level, so a copy here would be a duplicate no aggregation
            // reads, stored forever in every event's jsonb. Context with no column of its own
            // stays, because the bag is its only carrier.
            put(
                "extra_json",
                buildMap {
                    putAll(properties)
                    putAll(systemProperties.filterValues { it != null })
                    put("\$lib", "android")
                    put("\$environment", config.environment.wireName)
                    put("\$schema_version", ABTO_SCHEMA_VERSION)
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
    ) {
        captureCanonicalOutcome(interactionType.wireValue, responseId)
    }

    private fun captureCanonicalOutcome(
        interactionType: String,
        responseId: String?,
    ) {
        client.captureSystemEvent(
            "llm_response_interacted",
            systemProperties = buildMap {
                put("\$interaction_type", interactionType)
                responseId?.let { put("\$response_id", it) }
                requestId?.let { put("\$request_id", it) }
            },
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
