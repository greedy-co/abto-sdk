// Generated from the ABTO Calling SDK and wire contracts. Do not edit.
package app.abto.calling.internal;

import java.util.Set;

/** Shared wire and policy constants. */
public final class CallingContract {
    private CallingContract() {}
    public static final long CIRCUIT_OPEN_MS = 30000;
    public static final long DEFAULT_FALLBACK_TIMEOUT_MS = 30000;
    public static final String CHAT_COMPLETIONS_PATH = "chat/completions";
    public static final String HEADER_DEVICE_ID = "x-abto-device-id";
    public static final String HEADER_FEATURE_ID = "x-abto-feature-id";
    public static final String HEADER_NODE_ID = "x-abto-node-id";
    public static final String HEADER_TRACE_ID = "x-abto-trace-id";
    public static final String HEADER_PROVIDER_KEY_PREFIX = "x-abto-key-";
    public static final String HEADER_REQUEST_ID = "x-abto-request-id";
    public static final String HEADER_ATTEMPT = "x-abto-attempt";
    public static final String HEADER_PROVIDER = "x-abto-provider";
    public static final String HEADER_ERROR_SOURCE = "x-abto-error-source";
    public static final String ERROR_SOURCE_PROVIDER = "provider";
    public static final String ERROR_SOURCE_TRANSPORT = "transport";
    public static final String ERROR_SOURCE_GATEWAY = "gateway";
    public static final String GATEWAY_BASE_URL_ENV = "ABTO_GATEWAY_BASE_URL";
    public static final String API_KEY_ENV = "ABTO_API_KEY";
    public static final String ERR_FALLBACK_BASE_URL_REQUIRED = "[abto] fallback.baseUrl is required to enable OpenAI direct fallback. Set it to the OpenAI-compatible endpoint this application used before ABTO.";
    public static final String ERR_FALLBACK_BASE_URL_INVALID = "[abto] fallback.baseUrl must be a valid http(s) URL.";
    public static final String ERR_FALLBACK_OPENAI_KEY_REQUIRED = "[abto] fallback.baseUrl is set but no OpenAI provider key is available. Direct fallback sends the request with that key, so configure it or remove the fallback setting.";
    public static final String ERR_FALLBACK_TIMEOUT_POSITIVE = "[abto] fallback.timeout must be greater than 0.";
    public static final String ERR_GATEWAY_BASE_URL_INVALID = "[abto] gatewayBaseUrl must be a valid http(s) URL.";
    public static final String ERR_GATEWAY_BASE_URL_REQUIRED = "[abto] gatewayBaseUrl is required. Pass it explicitly or set ABTO_GATEWAY_BASE_URL.";
    public static final String ERR_API_KEY_REQUIRED = "[abto] apiKey is required. Pass it explicitly or set ABTO_API_KEY.";
    public static final String ERR_GATEWAY_REQUEST_URL_INVALID = "[abto] Gateway request URL is invalid.";
    public static final String ERR_GATEWAY_ORIGIN_REFUSED = "[abto] Refusing to send credentials outside the configured Gateway origin.";
    public static final String ERR_API_KEY_INVALID_CHARACTERS = "[abto] apiKey contains invalid characters.";
    public static final String ERR_PROVIDER_KEY_INVALID_CHARACTERS = "[abto] Provider key for {provider} contains invalid characters.";
    public static final Set<String> DIRECT_PATH_SUFFIXES = Set.of("chat/completions", "responses");
    public static final Set<String> DIRECT_HEADER_NAMES = Set.of("accept", "content-type", "idempotency-key", "traceparent", "tracestate", "user-agent");
    public static final Set<String> DIRECT_HEADER_PREFIXES = Set.of("openai-", "x-stainless-");
    public static final Set<String> TRUSTED_HEADER_NAMES = Set.of("authorization", "x-abto-device-id", "x-abto-feature-id", "x-abto-node-id", "x-abto-trace-id");
    public static final Set<String> PROVIDER_IDS = Set.of("openai", "anthropic", "gemini", "deepseek", "kimi");
    public static final Set<String> CONFORMANCE_SCENARIOS = Set.of("config.api_key_required", "config.gateway_base_url_required", "config.gateway_base_url_from_env", "fallback.destination_required", "fallback.destination_alone_enables", "fallback.rejected_without_openai_key", "fallback.off_when_unconfigured", "fallback.timeout_validated", "fallback.switches_on_connect_failure", "fallback.switches_on_admission_503", "fallback.no_switch_on_ambiguous_timeout", "fallback.no_switch_on_ambiguous_disconnect", "fallback.replays_timeout_when_opted_in", "fallback.sends_to_configured_destination", "fallback.covers_responses_path", "fallback.direct_error_returned_as_is", "security.rejects_cross_origin_request", "security.replaces_spoofed_context_headers", "security.rejects_provider_key_injection", "context.propagates_and_isolates", "context.emits_only_configured_identifiers", "context.opens_trace_when_absent", "context.node_change_keeps_trace", "retry.official_default_preserved", "retry.caller_setting_preserved", "circuit.shared_across_clients", "circuit.closes_on_gateway_recovery", "provider_key.resolved_per_request");
    public static final Set<Integer> SAFE_GATEWAY_STATUSES = Set.of(502, 503, 504);
}
