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
    "node_id" to "\$node_key",
    "node_key" to "\$node_key",
    "task_type" to "\$task_type",
    "surface" to "\$surface",
    "request_id" to "\$request_id",
    "response_id" to "\$response_id",
)

/**
 * Android/JVM 용 ABTO SDK 진입점.
 * 브라우저 SDK(packages/browser/javascript)와 동일한 이벤트 계약을 따른다:
 * Analytics 수신 계약(event_id·device_id·event_name·occurred_at·extra_json)으로
 * POST {"batch": […]} 한다.
 */
class AbtoClient(
    val config: AbtoConfig,
    store: AbtoKeyValueStore = AbtoInMemoryStore(),
) {
    private val context = AbtoContext(store)
    private val transport = AbtoTransport(config)

    /** Analytics와 Gateway의 `x-abto-device-id`에 함께 써야 하는 attribution 축. */
    val deviceId: String get() = context.anonymousId

    /** 현재 SDK client 생명주기의 session 식별자. */
    val sessionId: String get() = context.sessionId

    fun identify(userId: String, tenantId: String? = null) {
        context.identify(userId, tenantId)
    }

    fun reset() {
        context.reset()
    }

    /** 수동 event 전송 — LLM call 이전 행동 트래킹의 기본 경로. */
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

    fun startLlmTrace(nodeId: String, taskType: String? = null, surface: String? = null): AbtoLlmTrace =
        AbtoLlmTrace(this, nodeId, taskType, surface)

    fun flush(onComplete: Runnable? = null) {
        transport.flush(onComplete)
    }
}

/** LLM 호출 한 건의 생애주기 — trace_id 로 이전 행동을, request_id 로 게이트웨이 비용/latency 를 조인한다. */
class AbtoLlmTrace internal constructor(
    private val client: AbtoClient,
    val nodeId: String,
    private val taskType: String?,
    private val surface: String?,
) {
    val traceId: String = uuidV7TraceId()
    var requestId: String? = null
        private set

    /** 게이트웨이 응답 헤더(HttpURLConnection.headerFields 등)에서 x-abto-request-id 를 읽어 붙인다. */
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
        interactionType: String,
        responseId: String? = null,
        extra: Map<String, Any?> = emptyMap(),
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
        put("node_key", nodeId)
        put("trace_id", traceId)
        taskType?.let { put("task_type", it) }
        surface?.let { put("surface", it) }
        requestId?.let { put("request_id", it) }
        putAll(overrides)
    }
}
