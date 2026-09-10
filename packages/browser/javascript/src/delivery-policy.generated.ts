// GENERATED FILE — DO NOT EDIT.

export const ABTO_DEFAULT_API_HOST = "https://api.abto.app" as const;
export const ABTO_COLLECT_EVENTS_PATH = "/v1/collect/events" as const;
export const ABTO_HEADER_DEVICE_ID = "x-abto-device-id" as const;
export const ABTO_ERR_PROJECT_KEY_REQUIRED = "[abto] projectKey is required. Check your init config." as const;
export const ABTO_ERR_API_HOST_INVALID_PREFIX = "[abto] apiHost is not a valid http(s) URL: " as const;
export const ABTO_ERR_INTERACTION_DROPPED = "[abto] response interaction was dropped: unsupported canonical type. Use a custom event for other product actions." as const;
export const ABTO_ERR_EVENT_NAME_BLANK = "must not be blank" as const;
export const ABTO_ERR_EVENT_NAME_NUL = "must not contain U+0000" as const;
export const ABTO_ERR_EVENT_NAME_DOLLAR_PREFIX = "must not start with $" as const;
export const ABTO_ERR_EVENT_NAME_RESERVED = "must not use an ABTO system event name" as const;
export const ABTO_ERR_EVENT_NAME_TOO_LONG = "must be at most 200 UTF-16 code units" as const;
export const ABTO_ERR_EVENT_DROPPED = "[abto] event was dropped: {issue}." as const;
export const ABTO_ERR_CUSTOM_CAPTURE_INVALID = "[abto] custom event was dropped: optional value and scale must satisfy the collector contract; properties must contain JSON values and no reserved keys." as const;
export const ABTO_ERR_METRIC_VALUE_OMITTED = "[abto] metric value is outside the collector contract and was omitted." as const;
export const ABTO_ERR_METRIC_SCALE_OMITTED = "[abto] metric scale is outside the collector contract and was omitted." as const;
export const ABTO_CONFORMANCE_SCENARIOS = ['identity.anonymous_persists', 'identity.session_rotates', 'identity.uuidv7', 'identity.identify_and_reset', 'config.project_key_required', 'config.endpoint_must_be_url', 'config.endpoint_requires_https', 'config.batch_size_range', 'event.name_length_limit', 'event.reserved_name_rejected', 'event.metric_non_finite_rejected', 'event.metric_precision_enforced', 'event.metric_scale_limit', 'event.properties_in_extra_json', 'event.optional_scale_preserved', 'event.optional_metrics_preserved', 'event.promoted_fields_not_in_extra_json', 'privacy.prompt_and_response_text_not_sent', 'transport.request_id_header_case_insensitive', 'transport.retry_marked_events_only', 'transport.attempt_budget_stops_retry', 'transport.response_body_cap', 'transport.buffer_cap'] as const;
export const ABTO_CONFORMANCE_EXEMPTIONS = ['transport.response_body_cap', 'transport.attempt_budget_stops_retry', 'config.batch_size_range', 'config.endpoint_requires_https'] as const;
export const ABTO_MAX_BUFFERED_EVENTS = 1000 as const;
export const ABTO_MAX_RETRY_DELAY_MS = 120000 as const;
export const ABTO_RETRY_JITTER_RATIO = 0.5 as const;
export const ABTO_CUSTOM_METRIC_FIELDS = ["value","scale"] as const;
export const ABTO_METRIC_ABSOLUTE_LIMIT = 1e+38 as const;
export const ABTO_SCALE_MAX_LENGTH = 16 as const;
export const ABTO_METRIC_MAX_FRACTION_DIGITS = 12 as const;
