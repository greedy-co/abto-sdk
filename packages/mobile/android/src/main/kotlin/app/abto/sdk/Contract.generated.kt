// GENERATED FILE — DO NOT EDIT.

package app.abto.sdk

const val ABTO_SCHEMA_VERSION = "2026-09-02"
const val ABTO_DEFAULT_COLLECT_ENDPOINT = "https://api.abto.app/v1/collect/events"
const val ABTO_DEFAULT_BATCH_SIZE = 20
const val ABTO_MIN_BATCH_SIZE = 1
val ABTO_CUSTOM_METRIC_FIELDS = setOf("value", "scale")
const val ABTO_METRIC_ABSOLUTE_LIMIT = 1e+38
const val ABTO_METRIC_MAX_FRACTION_DIGITS = 12
const val ABTO_SCALE_MAX_LENGTH = 16
val ABTO_LOOPBACK_HOSTS = setOf("localhost", "::1")
val ABTO_LOOPBACK_HOST_PREFIXES = listOf("127.")
const val ABTO_DEFAULT_FLUSH_INTERVAL_MS = 5000L
const val ABTO_ERR_PROJECT_KEY_REQUIRED = "[abto] projectKey is required. Check your init config."
const val ABTO_ERR_ENDPOINT_HTTPS_REQUIRED = "[abto] endpoint must use HTTPS outside development loopback."
const val ABTO_ERR_ENDPOINT_INVALID_PREFIX = "[abto] endpoint is not a valid http(s) URL: "
const val ABTO_ERR_BATCH_SIZE_RANGE = "[abto] batchSize must be between 1 and 100."
const val ABTO_ERR_INTERACTION_DROPPED = "[abto] response interaction was dropped: unsupported canonical type. Use a custom event for other product actions."
const val ABTO_ERR_EVENT_NAME_BLANK = "must not be blank"
const val ABTO_ERR_EVENT_NAME_NUL = "must not contain U+0000"
const val ABTO_ERR_EVENT_NAME_DOLLAR_PREFIX = "must not start with $"
const val ABTO_ERR_EVENT_NAME_RESERVED = "must not use an ABTO system event name"
const val ABTO_ERR_EVENT_NAME_TOO_LONG = "must be at most 200 UTF-16 code units"
const val ABTO_ERR_EVENT_DROPPED = "[abto] event was dropped: {issue}."
const val ABTO_ERR_CUSTOM_CAPTURE_INVALID = "[abto] custom event was dropped: optional value and scale must satisfy the collector contract; properties must contain JSON values and no reserved keys."
const val ABTO_ERR_METRIC_VALUE_OMITTED = "[abto] metric value is outside the collector contract and was omitted."
const val ABTO_ERR_METRIC_SCALE_OMITTED = "[abto] metric scale is outside the collector contract and was omitted."
val ABTO_CONFORMANCE_SCENARIOS = listOf("identity.anonymous_persists", "identity.session_rotates", "identity.uuidv7", "identity.identify_and_reset", "config.project_key_required", "config.endpoint_must_be_url", "config.endpoint_requires_https", "config.batch_size_range", "event.name_length_limit", "event.reserved_name_rejected", "event.metric_non_finite_rejected", "event.metric_precision_enforced", "event.metric_scale_limit", "event.properties_in_extra_json", "event.optional_scale_preserved", "event.optional_metrics_preserved", "event.promoted_fields_not_in_extra_json", "privacy.prompt_and_response_text_not_sent", "transport.request_id_header_case_insensitive", "transport.retry_marked_events_only", "transport.attempt_budget_stops_retry", "transport.response_body_cap", "transport.buffer_cap")
val ABTO_CONFORMANCE_EXEMPTIONS = listOf<String>()
const val ABTO_EVENT_NAME_MAX_LENGTH = 200
const val ABTO_MAX_BUFFERED_EVENTS = 1000
const val ABTO_MAX_RETRY_DELAY_MS = 120000L
const val ABTO_RETRY_JITTER_RATIO = 0.5
const val ABTO_MAX_ATTEMPTS = 5
const val ABTO_MAX_EVENT_AGE_MS = 1800000L
const val ABTO_MAX_BATCH_SIZE = 100
const val ABTO_MAX_RESPONSE_BYTES = 65536
val ABTO_RESERVED_EVENT_NAMES = setOf("pageview", "pageleave", "interaction_autocaptured", "interaction_rageclick", "interaction_deadclick", "llm_prompt_submitted", "llm_response_rendered", "llm_response_interacted")

enum class AbtoResponseInteraction(val wireValue: String) {
    COPIED("copied"),
    INSERTED("inserted"),
    ACCEPTED("accepted"),
    REJECTED("rejected"),
    SHARED("shared"),
    DOWNLOADED("downloaded"),
    EXPANDED("expanded"),
    COLLAPSED("collapsed"),
    RATED_POSITIVE("rated_positive"),
    RATED_NEGATIVE("rated_negative"),
    REGENERATED("regenerated"),
    ABORTED("aborted");

    companion object {
        fun fromWireValue(value: String): AbtoResponseInteraction? = entries.firstOrNull { it.wireValue == value }
    }
}
