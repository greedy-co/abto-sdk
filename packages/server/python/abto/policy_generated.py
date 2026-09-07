# GENERATED FILE — DO NOT EDIT.

from typing import Final, FrozenSet, Tuple

CIRCUIT_OPEN_SECONDS: Final[float] = 30
DEFAULT_FALLBACK_TIMEOUT_SECONDS: Final[float] = 30
DIRECT_PATH_SUFFIX: Final[str] = "chat/completions"
DIRECT_HEADER_NAMES: Final[FrozenSet[str]] = frozenset({"accept", "content-type", "idempotency-key", "user-agent"})
DIRECT_HEADER_PREFIXES: Final[Tuple[str, ...]] = ("openai-", "x-stainless-",)
SAFE_GATEWAY_STATUSES: Final[FrozenSet[int]] = frozenset({502, 503, 504})
PROVIDER_IDS: Final[Tuple[str, ...]] = ("openai", "anthropic", "gemini",)
HEADER_DEVICE_ID: Final[str] = "x-abto-device-id"
HEADER_FEATURE_ID: Final[str] = "x-abto-feature-id"
HEADER_PROVIDER_KEY_PREFIX: Final[str] = "x-abto-key-"
HEADER_REQUEST_ID: Final[str] = "x-abto-request-id"
ERR_FALLBACK_BASE_URL_REQUIRED: Final[str] = "[abto] fallback.base_url is required to enable OpenAI direct fallback. Set it to the OpenAI-compatible endpoint this application used before ABTO."
ERR_FALLBACK_BASE_URL_INVALID: Final[str] = "[abto] fallback.base_url must be a valid http(s) URL."
ERR_FALLBACK_OPENAI_KEY_REQUIRED: Final[str] = "[abto] fallback.base_url is set but no OpenAI provider key is available. Direct fallback sends the request with that key, so configure it or remove the fallback setting."
ERR_FALLBACK_TIMEOUT_POSITIVE: Final[str] = "[abto] fallback.timeout_seconds must be greater than 0."
ERR_GATEWAY_BASE_URL_INVALID: Final[str] = "[abto] gateway_base_url must be a valid http(s) URL."
ERR_GATEWAY_BASE_URL_REQUIRED: Final[str] = "[abto] gateway_base_url is required. Pass it explicitly or set ABTO_GATEWAY_BASE_URL."
ERR_API_KEY_REQUIRED: Final[str] = "[abto] api_key is required. Pass it explicitly or set ABTO_API_KEY."
ERR_GATEWAY_REQUEST_URL_INVALID: Final[str] = "[abto] Gateway request URL is invalid."
ERR_GATEWAY_ORIGIN_REFUSED: Final[str] = "[abto] Refusing to send credentials outside the configured Gateway origin."
ERR_API_KEY_INVALID_CHARACTERS: Final[str] = "[abto] api_key contains invalid characters."
ERR_PROVIDER_KEY_INVALID_CHARACTERS: Final[str] = "[abto] Provider key for {provider} contains invalid characters."
