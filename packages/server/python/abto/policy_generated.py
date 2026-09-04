# GENERATED FILE — DO NOT EDIT.

from typing import Final, FrozenSet, Tuple

CIRCUIT_OPEN_SECONDS: Final[float] = 30
DEFAULT_FALLBACK_TIMEOUT_SECONDS: Final[float] = 30
DIRECT_PATH_SUFFIX: Final[str] = "chat/completions"
DIRECT_HEADER_NAMES: Final[FrozenSet[str]] = frozenset({"accept", "content-type", "idempotency-key", "user-agent"})
DIRECT_HEADER_PREFIXES: Final[Tuple[str, ...]] = ("openai-", "x-stainless-",)
SAFE_GATEWAY_STATUSES: Final[FrozenSet[int]] = frozenset({502, 503, 504})
PROVIDER_IDS: Final[Tuple[str, ...]] = ("openai", "anthropic", "gemini",)
