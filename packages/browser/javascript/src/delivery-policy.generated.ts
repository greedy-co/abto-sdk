// GENERATED FILE — DO NOT EDIT.

export const ABTO_DEFAULT_API_HOST = "https://api.abto.app" as const;
export const ABTO_COLLECT_EVENTS_PATH = "/v1/collect/events" as const;
export const ABTO_HEADER_DEVICE_ID = "x-abto-device-id" as const;
export const ABTO_ERR_PROJECT_KEY_REQUIRED = "[abto] projectKey is required. Check your init config." as const;
export const ABTO_ERR_API_HOST_INVALID_PREFIX = "[abto] apiHost is not a valid http(s) URL: " as const;
export const ABTO_CONFORMANCE_SCENARIOS = ['identity.anonymous_persists', 'identity.session_rotates', 'identity.uuidv7', 'identity.identify_and_reset', 'config.project_key_required', 'config.endpoint_must_be_url', 'config.endpoint_requires_https', 'config.batch_size_range', 'event.name_length_limit', 'event.reserved_name_rejected', 'event.metric_non_finite_omitted', 'event.metric_precision_enforced', 'event.metric_scale_limit', 'event.no_free_form_properties', 'event.promoted_fields_not_in_extra_json', 'privacy.prompt_and_response_text_not_sent', 'transport.request_id_header_case_insensitive', 'transport.retry_marked_events_only', 'transport.attempt_budget_stops_retry', 'transport.response_body_cap', 'transport.buffer_cap'] as const;
export const ABTO_CONFORMANCE_EXEMPTIONS = ['transport.response_body_cap', 'transport.attempt_budget_stops_retry', 'config.batch_size_range', 'config.endpoint_requires_https'] as const;
export const ABTO_MAX_BUFFERED_EVENTS = 1000 as const;
export const ABTO_MAX_RETRY_DELAY_MS = 120000 as const;
export const ABTO_RETRY_JITTER_RATIO = 0.5 as const;
export const ABTO_SCALE_MAX_LENGTH = 16 as const;
export const ABTO_METRIC_MAX_FRACTION_DIGITS = 12 as const;
