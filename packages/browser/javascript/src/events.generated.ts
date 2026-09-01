// GENERATED FILE — DO NOT EDIT.

export interface EventsGenerated {
    AiPromptSubmittedProps?:           AIPromptSubmittedProps;
    AiResponseInteractedProps?:        AIResponseInteractedProps;
    AiResponseRenderedProps?:          AIResponseRenderedProps;
    AutocaptureProps?:                 AutocaptureProps;
    BrowserAiPromptSubmittedEvent?:    BrowserAIPromptSubmittedEvent;
    BrowserAiResponseInteractedEvent?: BrowserAIResponseInteractedEvent;
    BrowserAiResponseRenderedEvent?:   BrowserAIResponseRenderedEvent;
    BrowserAutocaptureEvent?:          BrowserAutocaptureEvent;
    BrowserContextProperties?:         BrowserContextProperties;
    BrowserDeadClickEvent?:            BrowserDeadClickEvent;
    BrowserEventBatchRequest?:         BrowserEventBatchRequest;
    BrowserEventBatchResponse?:        BrowserEventBatchResponse;
    BrowserEventResult?:               BrowserEventResult;
    BrowserEventResultCode?:           BrowserEventResultCode;
    BrowserEventResultStatus?:         BrowserEventResultStatus;
    BrowserIngestEvent?:               BrowserIngestEvent;
    BrowserPageleaveEvent?:            BrowserPageleaveEvent;
    BrowserPageviewEvent?:             BrowserPageviewEvent;
    BrowserRageclickEvent?:            BrowserRageclickEvent;
    CustomEvent?:                      CustomEvent;
    DeadClickProps?:                   DeadClickProps;
    MetricValue?:                      number;
    PageleaveProps?:                   PageleaveProps;
    PageviewProps?:                    PageviewProps;
    RageclickProps?:                   RageclickProps;
    ScrollDepthProps?:                 ScrollDepthProps;
}

export interface AIPromptSubmittedProps {
    $capture_mode:             CaptureMode;
    $contains_attachment?:     boolean;
    $contains_code?:           boolean;
    $language?:                string;
    $pii_detected?:            boolean;
    $prompt_hash?:             string;
    $prompt_length_chars?:     number;
    $prompt_text?:             string;
    $prompt_tokens_estimated?: number;
    $sensitive_category?:      SensitiveCategory[] | SensitiveCategory;
}

export type CaptureMode = "off" | "hash" | "metadata_only" | "full";

export type SensitiveCategory = "pii" | "credential" | "source_code" | "legal" | "finance" | "healthcare" | "customer_data" | "internal_document" | "unknown_sensitive";

export interface AIResponseInteractedProps {
    $destination?:            string;
    $interaction_type:        AIInteractionType;
    $request_id?:             string;
    $response_id?:            string;
    $source?:                 string;
    $time_since_response_ms?: number;
    $visible_output_ratio?:   number;
}

export type AIInteractionType = "copied" | "inserted" | "accepted" | "rejected" | "shared" | "downloaded" | "expanded" | "collapsed" | "rated_positive" | "rated_negative" | "regenerated" | "aborted";

export interface AIResponseRenderedProps {
    $capture_mode:          ResponseCaptureMode;
    $output_length_chars?:  number;
    $response_id:           string;
    $response_text?:        string;
    $time_to_render_ms?:    number;
    $visible_output_ratio?: number;
}

export type ResponseCaptureMode = "off" | "metadata_only" | "full";

export interface AutocaptureProps {
    $ai_action?:        string;
    $ce_version:        number;
    $el_name?:          string;
    $el_text?:          string;
    $el_value?:         string;
    $elements_chain:    string;
    $event_type:        AutocaptureEventType;
    $href?:             string;
    $input_type?:       string;
    $request_id?:       string;
    $response_id?:      string;
    $selection_length?: number;
    $tag_name?:         string;
}

export type AutocaptureEventType = "click" | "change" | "submit" | "copy";

export interface BrowserAIPromptSubmittedEvent {
    device_id:   string;
    event_id:    string;
    event_name:  BrowserAIPromptSubmittedEventEventName;
    extra_json:  BrowserAIPromptSubmittedEventExtraJSON;
    occurred_at: string;
    scale?:      string;
    session_id?: string;
    trace_id?:   string;
    value?:      number;
}

export type BrowserAIPromptSubmittedEventEventName = "llm_prompt_submitted";

export interface BrowserAIPromptSubmittedEventExtraJSON {
    $anonymous_id?:            string;
    $app_version?:             string;
    $capture_mode:             CaptureMode;
    $contains_attachment?:     boolean;
    $contains_code?:           boolean;
    $conversation_id?:         string;
    $device_id?:               string;
    $entry_point?:             string;
    $environment?:             Environment;
    $feature_flag_key?:        string;
    $feature_flag_variant?:    string;
    $language?:                string;
    $lib?:                     LIB;
    $lib_version?:             string;
    $message_id?:              string;
    $node_key?:                string;
    $pageview_id?:             string;
    $pii_detected?:            boolean;
    $prompt_hash?:             string;
    $prompt_length_chars?:     number;
    $prompt_template_id?:      string;
    $prompt_text?:             string;
    $prompt_tokens_estimated?: number;
    $request_id?:              string;
    $response_id?:             string;
    $schema_version?:          string;
    $sensitive_category?:      SensitiveCategory[] | SensitiveCategory;
    $session_id?:              string;
    $surface?:                 string;
    $task_type?:               string;
    $tenant_id?:               string;
    $trace_id?:                string;
    $user_id?:                 string;
    $window_id?:               string;
}

export type Environment = "development" | "production";

export type LIB = "web" | "android" | "ios" | "flutter";

export interface BrowserAIResponseInteractedEvent {
    device_id:   string;
    event_id:    string;
    event_name:  BrowserAIResponseInteractedEventEventName;
    extra_json:  BrowserAIResponseInteractedEventExtraJSON;
    occurred_at: string;
    scale?:      string;
    session_id?: string;
    trace_id?:   string;
    value?:      number;
}

export type BrowserAIResponseInteractedEventEventName = "llm_response_interacted";

export interface BrowserAIResponseInteractedEventExtraJSON {
    $anonymous_id?:           string;
    $app_version?:            string;
    $conversation_id?:        string;
    $destination?:            string;
    $device_id?:              string;
    $entry_point?:            string;
    $environment?:            Environment;
    $feature_flag_key?:       string;
    $feature_flag_variant?:   string;
    $interaction_type:        AIInteractionType;
    $lib?:                    LIB;
    $lib_version?:            string;
    $message_id?:             string;
    $node_key?:               string;
    $pageview_id?:            string;
    $prompt_template_id?:     string;
    $request_id?:             string;
    $response_id?:            string;
    $schema_version?:         string;
    $session_id?:             string;
    $source?:                 string;
    $surface?:                string;
    $task_type?:              string;
    $tenant_id?:              string;
    $time_since_response_ms?: number;
    $trace_id?:               string;
    $user_id?:                string;
    $visible_output_ratio?:   number;
    $window_id?:              string;
}

export interface BrowserAIResponseRenderedEvent {
    device_id:   string;
    event_id:    string;
    event_name:  BrowserAIResponseRenderedEventEventName;
    extra_json:  BrowserAIResponseRenderedEventExtraJSON;
    occurred_at: string;
    scale?:      string;
    session_id?: string;
    trace_id?:   string;
    value?:      number;
}

export type BrowserAIResponseRenderedEventEventName = "llm_response_rendered";

export interface BrowserAIResponseRenderedEventExtraJSON {
    $anonymous_id?:         string;
    $app_version?:          string;
    $capture_mode:          ResponseCaptureMode;
    $conversation_id?:      string;
    $device_id?:            string;
    $entry_point?:          string;
    $environment?:          Environment;
    $feature_flag_key?:     string;
    $feature_flag_variant?: string;
    $lib?:                  LIB;
    $lib_version?:          string;
    $message_id?:           string;
    $node_key?:             string;
    $output_length_chars?:  number;
    $pageview_id?:          string;
    $prompt_template_id?:   string;
    $request_id?:           string;
    $response_id:           string;
    $response_text?:        string;
    $schema_version?:       string;
    $session_id?:           string;
    $surface?:              string;
    $task_type?:            string;
    $tenant_id?:            string;
    $time_to_render_ms?:    number;
    $trace_id?:             string;
    $user_id?:              string;
    $visible_output_ratio?: number;
    $window_id?:            string;
}

export interface BrowserAutocaptureEvent {
    device_id:   string;
    event_id:    string;
    event_name:  BrowserAutocaptureEventEventName;
    extra_json:  BrowserAutocaptureEventExtraJSON;
    occurred_at: string;
    scale?:      string;
    session_id?: string;
    trace_id?:   string;
    value?:      number;
}

export type BrowserAutocaptureEventEventName = "interaction_autocaptured";

export interface BrowserAutocaptureEventExtraJSON {
    $ai_action?:            string;
    $anonymous_id?:         string;
    $app_version?:          string;
    $ce_version:            number;
    $conversation_id?:      string;
    $device_id?:            string;
    $el_name?:              string;
    $el_text?:              string;
    $el_value?:             string;
    $elements_chain:        string;
    $entry_point?:          string;
    $environment?:          Environment;
    $event_type:            AutocaptureEventType;
    $feature_flag_key?:     string;
    $feature_flag_variant?: string;
    $href?:                 string;
    $input_type?:           string;
    $lib?:                  LIB;
    $lib_version?:          string;
    $message_id?:           string;
    $node_key?:             string;
    $pageview_id?:          string;
    $prompt_template_id?:   string;
    $request_id?:           string;
    $response_id?:          string;
    $schema_version?:       string;
    $selection_length?:     number;
    $session_id?:           string;
    $surface?:              string;
    $tag_name?:             string;
    $task_type?:            string;
    $tenant_id?:            string;
    $trace_id?:             string;
    $user_id?:              string;
    $window_id?:            string;
}

export interface BrowserContextProperties {
    $anonymous_id?:         string;
    $app_version?:          string;
    $conversation_id?:      string;
    $device_id?:            string;
    $entry_point?:          string;
    $environment?:          Environment;
    $feature_flag_key?:     string;
    $feature_flag_variant?: string;
    $lib?:                  LIB;
    $lib_version?:          string;
    $message_id?:           string;
    $node_key?:             string;
    $pageview_id?:          string;
    $prompt_template_id?:   string;
    $request_id?:           string;
    $response_id?:          string;
    $schema_version?:       string;
    $session_id?:           string;
    $surface?:              string;
    $task_type?:            string;
    $tenant_id?:            string;
    $trace_id?:             string;
    $user_id?:              string;
    $window_id?:            string;
}

export interface BrowserDeadClickEvent {
    device_id:   string;
    event_id:    string;
    event_name:  BrowserDeadClickEventEventName;
    extra_json:  BrowserDeadClickEventExtraJSON;
    occurred_at: string;
    scale?:      string;
    session_id?: string;
    trace_id?:   string;
    value?:      number;
}

export type BrowserDeadClickEventEventName = "interaction_deadclick";

export interface BrowserDeadClickEventExtraJSON {
    $anonymous_id?:         string;
    $app_version?:          string;
    $conversation_id?:      string;
    $device_id?:            string;
    $elements_chain:        string;
    $entry_point?:          string;
    $environment?:          Environment;
    $feature_flag_key?:     string;
    $feature_flag_variant?: string;
    $lib?:                  LIB;
    $lib_version?:          string;
    $message_id?:           string;
    $node_key?:             string;
    $pageview_id?:          string;
    $prompt_template_id?:   string;
    $request_id?:           string;
    $response_id?:          string;
    $schema_version?:       string;
    $session_id?:           string;
    $surface?:              string;
    $task_type?:            string;
    $tenant_id?:            string;
    $trace_id?:             string;
    $user_id?:              string;
    $window_id?:            string;
}

export interface BrowserEventBatchRequest {
    batch:        BrowserEvent[];
    diagnostics?: BrowserDiagnosticsEnvelope;
}

export interface BrowserEvent {
    device_id:   string;
    event_id:    string;
    event_name:  string;
    extra_json:  ExtraJSONObject;
    occurred_at: string;
    scale?:      string;
    session_id?: string;
    trace_id?:   string;
    value?:      number;
}

export interface ExtraJSONObject {
    $anonymous_id?:            Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $app_version?:             Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $conversation_id?:         Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $current_url?:             Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $device_id?:               Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $entry_point?:             Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $environment?:             Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $feature_flag_key?:        Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $feature_flag_variant?:    Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $lib?:                     Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $lib_version?:             Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $message_id?:              Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $node_key?:                Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $pageview_id?:             Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $pathname?:                Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $prompt_template_id?:      Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $referrer?:                Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $request_id?:              Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $response_id?:             Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $schema_version?:          Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $session_id?:              Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $surface?:                 Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $task_type?:               Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $tenant_id?:               Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $trace_id?:                Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $user_id?:                 Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $window_id?:               Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $duration_ms?:             Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $last_content_percentage?: Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $last_content_y?:          Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $last_scroll_percentage?:  Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $last_scroll_y?:           Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $max_content_percentage?:  Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $max_content_y?:           Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $max_scroll_percentage?:   Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $max_scroll_y?:            Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $ai_action?:               Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $ce_version?:              Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $el_name?:                 Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $el_text?:                 Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $el_value?:                Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $elements_chain?:          Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $event_type?:              Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $href?:                    Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $input_type?:              Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $selection_length?:        Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $tag_name?:                Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $click_count?:             Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $capture_mode?:            Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $contains_attachment?:     Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $contains_code?:           Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $language?:                Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $pii_detected?:            Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $prompt_hash?:             Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $prompt_length_chars?:     Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $prompt_text?:             Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $prompt_tokens_estimated?: Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $sensitive_category?:      Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $output_length_chars?:     Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $response_text?:           Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $time_to_render_ms?:       Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $visible_output_ratio?:    Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $destination?:             Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $interaction_type?:        Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $source?:                  Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    $time_since_response_ms?:  Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
    [property: string]: Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string;
}

export interface BrowserDiagnosticsEnvelope {
    counters: BrowserDiagnosticCounters;
    sdk_name: SDKName;
}

export interface BrowserDiagnosticCounters {
    identity_persist_failed?: number;
    outbox_write_failed?:     number;
    send_failed?:             number;
    storage_unavailable?:     number;
}

export type SDKName = "browser-javascript";

export interface BrowserEventBatchResponse {
    results: { [key: string]: BrowserEventResult };
}

export interface BrowserEventResult {
    code?:  BrowserEventResultCode;
    result: BrowserEventResultStatus;
}

export type BrowserEventResultCode = "schema_discovered" | "schema_drift" | "schema_required_missing" | "schema_type_mismatch" | "schema_enum_mismatch" | "missing_required" | "reserved_name" | "invalid_event" | "storage_unavailable";

export type BrowserEventResultStatus = "ok" | "warning" | "drop" | "retry";

export interface BrowserIngestEvent {
    device_id:   string;
    event_id:    string;
    event_name:  string;
    extra_json:  { [key: string]: Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string };
    occurred_at: string;
    scale?:      string;
    session_id?: string;
    trace_id?:   string;
    /**
     * Finite decimal with at most 38 integer digits and 12 fractional digits
     */
    value?: number;
}

export interface BrowserPageleaveEvent {
    device_id:   string;
    event_id:    string;
    event_name:  BrowserPageleaveEventEventName;
    extra_json:  BrowserPageleaveEventExtraJSON;
    occurred_at: string;
    scale?:      string;
    session_id?: string;
    trace_id?:   string;
    value?:      number;
}

export type BrowserPageleaveEventEventName = "pageleave";

export interface BrowserPageleaveEventExtraJSON {
    $anonymous_id?:            string;
    $app_version?:             string;
    $conversation_id?:         string;
    $current_url:              string;
    $device_id?:               string;
    $duration_ms?:             number;
    $entry_point?:             string;
    $environment?:             Environment;
    $feature_flag_key?:        string;
    $feature_flag_variant?:    string;
    $last_content_percentage?: number;
    $last_content_y?:          number;
    $last_scroll_percentage?:  number;
    $last_scroll_y?:           number;
    $lib?:                     LIB;
    $lib_version?:             string;
    $max_content_percentage?:  number;
    $max_content_y?:           number;
    $max_scroll_percentage?:   number;
    $max_scroll_y?:            number;
    $message_id?:              string;
    $node_key?:                string;
    $pageview_id?:             string;
    $pathname:                 string;
    $prompt_template_id?:      string;
    $request_id?:              string;
    $response_id?:             string;
    $schema_version?:          string;
    $session_id?:              string;
    $surface?:                 string;
    $task_type?:               string;
    $tenant_id?:               string;
    $trace_id?:                string;
    $user_id?:                 string;
    $window_id?:               string;
}

export interface BrowserPageviewEvent {
    device_id:   string;
    event_id:    string;
    event_name:  BrowserPageviewEventEventName;
    extra_json:  BrowserPageviewEventExtraJSON;
    occurred_at: string;
    scale?:      string;
    session_id?: string;
    trace_id?:   string;
    value?:      number;
}

export type BrowserPageviewEventEventName = "pageview";

export interface BrowserPageviewEventExtraJSON {
    $anonymous_id?:         string;
    $app_version?:          string;
    $conversation_id?:      string;
    $current_url:           string;
    $device_id?:            string;
    $entry_point?:          string;
    $environment?:          Environment;
    $feature_flag_key?:     string;
    $feature_flag_variant?: string;
    $lib?:                  LIB;
    $lib_version?:          string;
    $message_id?:           string;
    $node_key?:             string;
    $pageview_id?:          string;
    $pathname:              string;
    $prompt_template_id?:   string;
    $referrer?:             string;
    $request_id?:           string;
    $response_id?:          string;
    $schema_version?:       string;
    $session_id?:           string;
    $surface?:              string;
    $task_type?:            string;
    $tenant_id?:            string;
    $trace_id?:             string;
    $user_id?:              string;
    $window_id?:            string;
}

export interface BrowserRageclickEvent {
    device_id:   string;
    event_id:    string;
    event_name:  BrowserRageclickEventEventName;
    extra_json:  BrowserRageclickEventExtraJSON;
    occurred_at: string;
    scale?:      string;
    session_id?: string;
    trace_id?:   string;
    value?:      number;
}

export type BrowserRageclickEventEventName = "interaction_rageclick";

export interface BrowserRageclickEventExtraJSON {
    $anonymous_id?:         string;
    $app_version?:          string;
    $click_count?:          number;
    $conversation_id?:      string;
    $device_id?:            string;
    $elements_chain:        string;
    $entry_point?:          string;
    $environment?:          Environment;
    $feature_flag_key?:     string;
    $feature_flag_variant?: string;
    $lib?:                  LIB;
    $lib_version?:          string;
    $message_id?:           string;
    $node_key?:             string;
    $pageview_id?:          string;
    $prompt_template_id?:   string;
    $request_id?:           string;
    $response_id?:          string;
    $schema_version?:       string;
    $session_id?:           string;
    $surface?:              string;
    $task_type?:            string;
    $tenant_id?:            string;
    $trace_id?:             string;
    $user_id?:              string;
    $window_id?:            string;
}

export interface CustomEvent {
    device_id:   string;
    event_id:    string;
    event_name:  string;
    extra_json:  { [key: string]: Array<boolean | number | null | string> | boolean | number | { [key: string]: boolean | number | null | string } | null | string };
    occurred_at: string;
    scale?:      string;
    session_id?: string;
    trace_id?:   string;
    value?:      number;
}

export interface DeadClickProps {
    $elements_chain: string;
}

export interface PageleaveProps {
    $current_url:              string;
    $duration_ms?:             number;
    $last_content_percentage?: number;
    $last_content_y?:          number;
    $last_scroll_percentage?:  number;
    $last_scroll_y?:           number;
    $max_content_percentage?:  number;
    $max_content_y?:           number;
    $max_scroll_percentage?:   number;
    $max_scroll_y?:            number;
    $pathname:                 string;
}

export interface PageviewProps {
    $current_url: string;
    $pathname:    string;
    $referrer?:   string;
}

export interface RageclickProps {
    $click_count?:   number;
    $elements_chain: string;
}

export interface ScrollDepthProps {
    $last_content_percentage?: number;
    $last_content_y?:          number;
    $last_scroll_percentage?:  number;
    $last_scroll_y?:           number;
    $max_content_percentage?:  number;
    $max_content_y?:           number;
    $max_scroll_percentage?:   number;
    $max_scroll_y?:            number;
}
