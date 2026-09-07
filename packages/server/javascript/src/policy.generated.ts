// GENERATED FILE — DO NOT EDIT.

export const CIRCUIT_OPEN_MS = 30000 as const;
export const DEFAULT_FALLBACK_TIMEOUT_MS = 30000 as const;
export const DIRECT_PATH_SUFFIX = "chat/completions" as const;
export const DIRECT_HEADER_NAMES: ReadonlySet<string> = new Set(['accept', 'content-type', 'idempotency-key', 'user-agent']);
export const DIRECT_HEADER_PREFIXES = ['openai-', 'x-stainless-'] as const;
export const SAFE_GATEWAY_STATUSES: ReadonlySet<number> = new Set([502, 503, 504]);
export const PROVIDER_IDS = ['openai', 'anthropic', 'gemini'] as const;
export type ProviderKeyName = (typeof PROVIDER_IDS)[number];
export const HEADER_DEVICE_ID = "x-abto-device-id" as const;
export const HEADER_FEATURE_ID = "x-abto-feature-id" as const;
export const HEADER_PROVIDER_KEY_PREFIX = "x-abto-key-" as const;
export const HEADER_REQUEST_ID = "x-abto-request-id" as const;
export const HEADER_ATTEMPT = "x-abto-attempt" as const;
export const HEADER_PROVIDER = "x-abto-provider" as const;
export const HEADER_ERROR_SOURCE = "x-abto-error-source" as const;
export const ERR_FALLBACK_BASE_URL_REQUIRED = "[abto] fallback.baseURL is required to enable OpenAI direct fallback. Set it to the OpenAI-compatible endpoint this application used before ABTO." as const;
export const ERR_FALLBACK_BASE_URL_INVALID = "[abto] fallback.baseURL must be a valid http(s) URL." as const;
export const ERR_FALLBACK_OPENAI_KEY_REQUIRED = "[abto] fallback.baseURL is set but no OpenAI provider key is available. Direct fallback sends the request with that key, so configure it or remove the fallback setting." as const;
export const ERR_FALLBACK_TIMEOUT_POSITIVE = "[abto] fallback.timeoutMs must be greater than 0." as const;
export const ERR_GATEWAY_BASE_URL_INVALID = "[abto] gatewayBaseURL must be a valid http(s) URL." as const;
export const ERR_GATEWAY_BASE_URL_REQUIRED = "[abto] gatewayBaseURL is required. Pass it explicitly or set ABTO_GATEWAY_BASE_URL." as const;
export const ERR_API_KEY_REQUIRED = "[abto] abtoApiKey is required. Pass it explicitly or set ABTO_API_KEY." as const;
export const ERR_GATEWAY_REQUEST_URL_INVALID = "[abto] Gateway request URL is invalid." as const;
export const ERR_GATEWAY_ORIGIN_REFUSED = "[abto] Refusing to send credentials outside the configured Gateway origin." as const;
export const ERR_API_KEY_INVALID_CHARACTERS = "[abto] abtoApiKey contains invalid characters." as const;
export const ERR_PROVIDER_KEY_INVALID_CHARACTERS = "[abto] Provider key for {provider} contains invalid characters." as const;
