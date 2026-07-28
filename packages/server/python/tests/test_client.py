import pytest

from abto import init_abto
from abto.client import DEFAULT_GATEWAY_BASE_URL, abto_request_hook


class Request:
    def __init__(self, url, headers=None):
        self.url = url
        self.headers = dict(headers or {})


def test_requires_abto_key_without_falling_back_to_provider_key(monkeypatch):
    monkeypatch.delenv("ABTO_API_KEY", raising=False)
    monkeypatch.setenv("OPENAI_API_KEY", "sk-provider-only")

    with pytest.raises(ValueError, match="ABTO_API_KEY is required"):
        init_abto()


def test_uses_canonical_gateway_default(monkeypatch):
    monkeypatch.delenv("ABTO_GATEWAY_BASE_URL", raising=False)

    abto = init_abto(api_key="abto-test")

    assert abto.gateway_base_url == DEFAULT_GATEWAY_BASE_URL


def test_hook_rejects_cross_origin_before_adding_context():
    hook = abto_request_hook("https://gateway.abto.app/v1", api_key="abto-test")
    request = Request("https://attacker.example/steal")

    with pytest.raises(ValueError, match="outside the configured Gateway origin"):
        hook(request)
    assert request.headers == {}


def test_hook_replaces_spoofed_context_and_preserves_ordinary_headers():
    abto = init_abto(
        api_key="abto-test",
        provider_keys={
            "openai": "openai-trusted",
            "anthropic": lambda: "anthropic-trusted",
        },
    )
    request = Request(
        "https://gateway.abto.app/v1/chat/completions",
        {
            "x-client-header": "preserved",
            "Authorization": "Bearer attacker-abto-key",
            "x-abto-device-id": "attacker-device",
            "x-abto-node-key": "attacker-node",
            "x-abto-key-openai": "attacker-openai-key",
            "x-abto-key-gemini": "attacker-gemini-key",
            "traceparent": "00-0123456789abcdef0123456789abcdef-0123456789abcdef-01",
        },
    )

    with abto.with_context(device_id="trusted-device", node_key="trusted.node"):
        abto.httpx_event_hooks()["request"][0](request)

    assert request.headers["x-client-header"] == "preserved"
    assert request.headers["Authorization"] == "Bearer abto-test"
    assert request.headers["x-abto-device-id"] == "trusted-device"
    assert request.headers["x-abto-node-key"] == "trusted.node"
    assert request.headers["x-abto-key-openai"] == "openai-trusted"
    assert request.headers["x-abto-key-anthropic"] == "anthropic-trusted"
    assert "x-abto-key-gemini" not in request.headers
    assert "traceparent" not in request.headers


def test_hook_rejects_provider_key_header_injection():
    abto = init_abto(
        api_key="abto-test",
        provider_keys={"openai": "safe\r\nX-Leaked: value"},
    )
    request = Request("https://gateway.abto.app/v1/chat/completions")

    with pytest.raises(ValueError, match="provider key for openai contains invalid characters"):
        abto.httpx_event_hooks()["request"][0](request)
