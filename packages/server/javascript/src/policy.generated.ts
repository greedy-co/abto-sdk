// GENERATED FILE — DO NOT EDIT.

export const CIRCUIT_OPEN_MS = 30000 as const;
export const DEFAULT_FALLBACK_TIMEOUT_MS = 30000 as const;
export const DIRECT_PATH_SUFFIX = "chat/completions" as const;
export const DIRECT_HEADER_NAMES: ReadonlySet<string> = new Set(['accept', 'content-type', 'idempotency-key', 'user-agent']);
export const DIRECT_HEADER_PREFIXES = ['openai-', 'x-stainless-'] as const;
export const SAFE_GATEWAY_STATUSES: ReadonlySet<number> = new Set([502, 503, 504]);
export const PROVIDER_IDS = ['openai', 'anthropic', 'gemini'] as const;
export type ProviderKeyName = (typeof PROVIDER_IDS)[number];
