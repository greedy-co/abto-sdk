// GENERATED FILE — DO NOT EDIT.

const abtoSchemaVersion = "2026-09-02";
const abtoDefaultCollectEndpoint = "https://api.abto.app/v1/collect/events";
const abtoDefaultBatchSize = 20;
const abtoMinBatchSize = 1;
const abtoScaleMaxLength = 16;
const abtoLoopbackHosts = <String>{"localhost", "::1"};
const abtoLoopbackHostPrefixes = <String>["127."];
const abtoDefaultFlushInterval = Duration(milliseconds: 5000);
const abtoErrProjectKeyRequired = "[abto] projectKey is required. Check your init config.";
const abtoErrEndpointHttpsRequired = "[abto] endpoint must use HTTPS outside development loopback.";
const abtoErrEndpointInvalidPrefix = "[abto] endpoint is not a valid http(s) URL: ";
const abtoErrBatchSizeRange = "[abto] batchSize must be between 1 and 100.";
const abtoErrInteractionDropped = "[abto] response interaction was dropped: unsupported canonical type. Use a custom event for other product actions.";
const abtoConformanceScenarios = <String>["identity.anonymous_persists", "identity.session_rotates", "identity.uuidv7", "identity.identify_and_reset", "config.project_key_required", "config.endpoint_must_be_url", "config.endpoint_requires_https", "config.batch_size_range", "event.name_length_limit", "event.reserved_name_rejected", "event.metric_non_finite_omitted", "event.metric_precision_enforced", "event.metric_scale_limit", "privacy.prompt_and_response_text_not_sent", "transport.request_id_header_case_insensitive", "transport.retry_marked_events_only", "transport.attempt_budget_stops_retry", "transport.response_body_cap", "transport.buffer_cap"];
const abtoConformanceExemptions = <String>[];
const abtoEventNameMaxLength = 200;
const abtoMaxBufferedEvents = 1000;
const abtoMaxRetryDelayMs = 120000;
const abtoRetryJitterRatio = 0.5;
const abtoMaxAttempts = 5;
const abtoMaxEventAge = Duration(milliseconds: 1800000);
const abtoMaxBatchSize = 100;
const abtoMaxResponseBytes = 65536;
const abtoReservedEventNames = <String>{"pageview", "pageleave", "interaction_autocaptured", "interaction_rageclick", "interaction_deadclick", "llm_prompt_submitted", "llm_response_rendered", "llm_response_interacted"};

extension type const AbtoResponseInteraction._(String wireValue) implements String {
  static const copied = AbtoResponseInteraction._("copied");
  static const inserted = AbtoResponseInteraction._("inserted");
  static const accepted = AbtoResponseInteraction._("accepted");
  static const rejected = AbtoResponseInteraction._("rejected");
  static const shared = AbtoResponseInteraction._("shared");
  static const downloaded = AbtoResponseInteraction._("downloaded");
  static const expanded = AbtoResponseInteraction._("expanded");
  static const collapsed = AbtoResponseInteraction._("collapsed");
  static const ratedPositive = AbtoResponseInteraction._("rated_positive");
  static const ratedNegative = AbtoResponseInteraction._("rated_negative");
  static const regenerated = AbtoResponseInteraction._("regenerated");
  static const aborted = AbtoResponseInteraction._("aborted");

  static const values = <AbtoResponseInteraction>[
    copied,
    inserted,
    accepted,
    rejected,
    shared,
    downloaded,
    expanded,
    collapsed,
    ratedPositive,
    ratedNegative,
    regenerated,
    aborted,
  ];

  static AbtoResponseInteraction? fromWireValue(String value) {
    for (final interaction in values) {
      if (interaction.wireValue == value) return interaction;
    }
    return null;
  }
}
