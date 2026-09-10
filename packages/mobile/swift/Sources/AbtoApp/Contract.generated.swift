// GENERATED FILE — DO NOT EDIT.

public let abtoSchemaVersion = "2026-09-02"
package let abtoDefaultCollectEndpoint = "https://api.abto.app/v1/collect/events"
public let abtoDefaultBatchSize = 20
package let abtoMinBatchSize = 1
package let abtoCustomMetricFields: Set<String> = ["value", "scale"]
package let abtoMetricAbsoluteLimit = 1e+38
package let abtoMetricMaxFractionDigits = 12
package let abtoScaleMaxLength = 16
package let abtoLoopbackHosts: Set<String> = ["localhost", "::1"]
package let abtoLoopbackHostPrefixes: [String] = ["127."]
public let abtoDefaultFlushInterval: Double = 5
package let abtoErrProjectKeyRequired = "[abto] projectKey is required. Check your init config."
package let abtoErrEndpointHTTPSRequired = "[abto] endpoint must use HTTPS outside development loopback."
package let abtoErrEndpointInvalidPrefix = "[abto] endpoint is not a valid http(s) URL: "
package let abtoErrBatchSizeRange = "[abto] batchSize must be between 1 and 100."
package let abtoErrInteractionDropped = "[abto] response interaction was dropped: unsupported canonical type. Use a custom event for other product actions."
package let abtoErrEventNameBlank = "must not be blank"
package let abtoErrEventNameNul = "must not contain U+0000"
package let abtoErrEventNameDollarPrefix = "must not start with $"
package let abtoErrEventNameReserved = "must not use an ABTO system event name"
package let abtoErrEventNameTooLong = "must be at most 200 UTF-16 code units"
package let abtoErrEventDropped = "[abto] event was dropped: {issue}."
package let abtoErrCustomCaptureInvalid = "[abto] custom event was dropped: optional value and scale must satisfy the collector contract; properties must contain JSON values and no reserved keys."
package let abtoErrMetricValueOmitted = "[abto] metric value is outside the collector contract and was omitted."
package let abtoErrMetricScaleOmitted = "[abto] metric scale is outside the collector contract and was omitted."
package let abtoConformanceScenarios = ["identity.anonymous_persists", "identity.session_rotates", "identity.uuidv7", "identity.identify_and_reset", "config.project_key_required", "config.endpoint_must_be_url", "config.endpoint_requires_https", "config.batch_size_range", "event.name_length_limit", "event.reserved_name_rejected", "event.metric_non_finite_rejected", "event.metric_precision_enforced", "event.metric_scale_limit", "event.properties_in_extra_json", "event.optional_scale_preserved", "event.optional_metrics_preserved", "event.promoted_fields_not_in_extra_json", "privacy.prompt_and_response_text_not_sent", "transport.request_id_header_case_insensitive", "transport.retry_marked_events_only", "transport.attempt_budget_stops_retry", "transport.response_body_cap", "transport.buffer_cap"]
package let abtoConformanceExemptions: [String] = ["transport.response_body_cap"]
let abtoEventNameMaxLength = 200
package let abtoMaxBufferedEvents = 1000
package let abtoMaxRetryDelay: Double = 120
package let abtoRetryJitterRatio = 0.5
package let abtoMaxAttempts = 5
package let abtoMaxEventAge: Double = 1800
package let abtoMaxBatchSize = 100
let abtoReservedEventNames: Set<String> = ["pageview", "pageleave", "interaction_autocaptured", "interaction_rageclick", "interaction_deadclick", "llm_prompt_submitted", "llm_response_rendered", "llm_response_interacted"]

public enum AbtoResponseInteraction: String, CaseIterable, Sendable {
    case copied = "copied"
    case inserted = "inserted"
    case accepted = "accepted"
    case rejected = "rejected"
    case shared = "shared"
    case downloaded = "downloaded"
    case expanded = "expanded"
    case collapsed = "collapsed"
    case ratedPositive = "rated_positive"
    case ratedNegative = "rated_negative"
    case regenerated = "regenerated"
    case aborted = "aborted"
}
