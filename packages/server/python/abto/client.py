"""Thin server facade: gateway baseURL + ABTO header injection.

It does not compute token/cost/latency. It routes provider SDK calls through the
ABTO Gateway and carries the x-abto-* identifiers from the current context.
"""

from __future__ import annotations

import os
from typing import Any, Callable, Dict, List, Mapping, MutableMapping, Optional, Tuple, Union
from urllib.parse import SplitResult, urlsplit

from .context import AbtoContext, create_trace_id, get_headers, with_context

DEFAULT_GATEWAY_BASE_URL = "https://gateway.abto.app/v1"
ProviderKeyValue = Union[str, Callable[[], Optional[str]]]
ProviderKeys = Mapping[str, ProviderKeyValue]
_PROVIDERS = ("openai", "anthropic", "gemini")


def _validated_gateway_url(value: str) -> str:
    parsed = urlsplit(value)
    if (
        parsed.scheme not in {"http", "https"}
        or not parsed.hostname
        or parsed.username is not None
        or parsed.password is not None
    ):
        raise ValueError("[abto] gateway_base_url must be a valid http(s) URL.")
    return value.rstrip("/")


def _origin(value: Any) -> Tuple[str, str, int]:
    parsed: SplitResult = urlsplit(str(value))
    if parsed.scheme not in {"http", "https"} or not parsed.hostname:
        raise ValueError("[abto] Gateway request URL is invalid.")
    default_port = 443 if parsed.scheme == "https" else 80
    return parsed.scheme, parsed.hostname.lower(), parsed.port or default_port


def _validated_api_key(value: str) -> str:
    resolved = value.strip()
    if not resolved:
        raise ValueError("[abto] api_key or ABTO_API_KEY is required.")
    if "\r" in resolved or "\n" in resolved:
        raise ValueError("[abto] api_key contains invalid characters.")
    return resolved


def resolve_provider_headers(provider_keys: Optional[ProviderKeys] = None) -> Dict[str, str]:
    """Return Gateway candidate-key headers for the supported provider ids."""

    headers: Dict[str, str] = {}
    for provider in _PROVIDERS:
        source = (provider_keys or {}).get(provider)
        value = source() if callable(source) else source
        if value is None:
            continue
        trimmed = value.strip()
        if not trimmed:
            continue
        if "\r" in trimmed or "\n" in trimmed:
            raise ValueError(f"[abto] provider key for {provider} contains invalid characters.")
        headers[f"x-abto-key-{provider}"] = trimmed
    return headers


def _remove_header(headers: MutableMapping[str, str], name: str) -> None:
    for key in list(headers.keys()):
        if key.lower() == name.lower():
            del headers[key]


def abto_request_hook(
    gateway_base_url: str,
    *,
    api_key: str,
    provider_keys: Optional[ProviderKeys] = None,
) -> Callable[[Any], None]:
    """Inject trusted Gateway credentials and request context for one origin."""

    gateway_origin = _origin(_validated_gateway_url(gateway_base_url))
    trusted_api_key = _validated_api_key(api_key)

    def hook(request: Any) -> None:
        if _origin(request.url) != gateway_origin:
            raise ValueError(
                "[abto] Refusing to send ABTO context outside the configured Gateway origin."
            )
        trusted_headers = get_headers()
        for name in ("authorization", "x-abto-device-id", "x-abto-node-key", "traceparent"):
            _remove_header(request.headers, name)
        for name in list(request.headers.keys()):
            if name.lower().startswith("x-abto-key-"):
                del request.headers[name]
        for key, value in resolve_provider_headers(provider_keys).items():
            request.headers[key] = value
        for key, value in trusted_headers.items():
            request.headers[key] = value
        request.headers["Authorization"] = f"Bearer {trusted_api_key}"

    return hook


class Abto:
    def __init__(
        self,
        api_key: Optional[str] = None,
        gateway_base_url: Optional[str] = None,
        provider_keys: Optional[ProviderKeys] = None,
    ) -> None:
        self.api_key = _validated_api_key(api_key or os.getenv("ABTO_API_KEY") or "")
        self._provider_keys = provider_keys if provider_keys is not None else {
            "openai": os.getenv("OPENAI_API_KEY"),
            "anthropic": os.getenv("ANTHROPIC_API_KEY"),
            "gemini": os.getenv("GEMINI_API_KEY"),
        }
        self.gateway_base_url = _validated_gateway_url(
            gateway_base_url
            or os.getenv("ABTO_GATEWAY_BASE_URL")
            or DEFAULT_GATEWAY_BASE_URL
        )

    def get_headers(self, ctx: Optional[AbtoContext] = None) -> Dict[str, str]:
        return get_headers(ctx)

    def with_context(self, **kwargs: Optional[str]):
        return with_context(**kwargs)

    def create_trace_id(self) -> str:
        return create_trace_id()

    def httpx_event_hooks(self) -> Dict[str, List[Callable[[Any], None]]]:
        return {
            "request": [
                abto_request_hook(
                    self.gateway_base_url,
                    api_key=self.api_key,
                    provider_keys=self._provider_keys,
                )
            ]
        }

    def openai(self, **client_kwargs: Any) -> Any:
        """Construct an OpenAI client pointed at the gateway with header injection.

        Requires the optional `openai` and `httpx` extras.
        """
        try:
            import httpx
            from openai import OpenAI
        except ImportError as exc:  # pragma: no cover - optional dependency
            raise ImportError("abto.openai() requires the 'openai' extra: pip install 'abto[openai]'") from exc

        reserved = {"api_key", "base_url", "http_client"}.intersection(client_kwargs)
        if reserved:
            names = ", ".join(sorted(reserved))
            raise ValueError(f"[abto] openai() does not allow overriding: {names}.")

        http_client = httpx.Client(event_hooks=self.httpx_event_hooks())
        return OpenAI(
            api_key=self.api_key,
            base_url=self.gateway_base_url,
            http_client=http_client,
            **client_kwargs,
        )


def init_abto(
    api_key: Optional[str] = None,
    gateway_base_url: Optional[str] = None,
    provider_keys: Optional[ProviderKeys] = None,
) -> Abto:
    return Abto(
        api_key=api_key,
        gateway_base_url=gateway_base_url,
        provider_keys=provider_keys,
    )
