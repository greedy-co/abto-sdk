import pytest

import abto.client as client_module
from abto import OpenAIDirectFallbackOptions, init_abto
from abto.client import (
    DEFAULT_GATEWAY_BASE_URL,
    _build_fallback_http_client,
    _resolve_fallback,
    abto_request_hook,
)


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
            "x-abto-feature-id": "attacker-feature",
            "x-abto-key-openai": "attacker-openai-key",
            "x-abto-key-gemini": "attacker-gemini-key",
            "traceparent": "00-0123456789abcdef0123456789abcdef-0123456789abcdef-01",
        },
    )

    with abto.with_context(device_id="trusted-device", feature_id="trusted.feature"):
        abto.httpx_event_hooks()["request"][0](request)

    assert request.headers["x-client-header"] == "preserved"
    assert request.headers["Authorization"] == "Bearer abto-test"
    assert request.headers["x-abto-device-id"] == "trusted-device"
    assert request.headers["x-abto-feature-id"] == "trusted.feature"
    assert request.headers["x-abto-key-openai"] == "openai-trusted"
    assert request.headers["x-abto-key-anthropic"] == "anthropic-trusted"
    assert "x-abto-key-gemini" not in request.headers
    assert "traceparent" not in request.headers


def test_hook_adds_gateway_authorization_without_request_context():
    hook = abto_request_hook(
        DEFAULT_GATEWAY_BASE_URL,
        api_key="abto-test",
        provider_keys={"openai": "sk-openai"},
    )
    request = Request(f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions")

    hook(request)

    assert request.headers["Authorization"] == "Bearer abto-test"
    assert request.headers["x-abto-key-openai"] == "sk-openai"


def test_hook_rejects_provider_key_header_injection():
    abto = init_abto(
        api_key="abto-test",
        provider_keys={"openai": "safe\r\nX-Leaked: value"},
    )
    request = Request("https://gateway.abto.app/v1/chat/completions")

    with pytest.raises(ValueError, match="provider key for openai contains invalid characters"):
        abto.httpx_event_hooks()["request"][0](request)


def test_direct_fallback_preserves_request_and_strips_abto_headers():
    httpx = pytest.importorskip("httpx")
    gateway_requests = []
    direct_requests = []

    def gateway_handler(request):
        gateway_requests.append(request)
        raise httpx.ConnectError("dns failed", request=request)

    def direct_handler(request):
        direct_requests.append(request)
        return httpx.Response(200, json={"id": "chatcmpl-direct", "choices": []})

    client = _build_fallback_http_client(
        httpx,
        gateway_base_url=DEFAULT_GATEWAY_BASE_URL,
        api_key="abto-test",
        provider_keys={
            "openai": "sk-openai",
            "anthropic": "sk-anthropic",
        },
        fallback=_resolve_fallback(
            OpenAIDirectFallbackOptions(),
            has_openai_key_source=True,
        ),
        gateway_transport=httpx.MockTransport(gateway_handler),
        direct_transport=httpx.MockTransport(direct_handler),
    )
    body = b'{"model":"gpt-4o-mini","messages":[{"role":"user","content":"hello"}]}'

    try:
        response = client.post(
            f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
            headers={
                "content-type": "application/json",
                "x-client-header": "preserved",
                "cookie": "gateway-session=secret",
                "proxy-authorization": "Bearer proxy-secret",
                "x-api-key": "gateway-secret",
                "openai-project": "project-safe",
                "idempotency-key": "request-safe",
            },
            content=body,
        )
    finally:
        client.close()

    assert response.status_code == 200
    assert len(gateway_requests) == 1
    assert len(direct_requests) == 1
    direct = direct_requests[0]
    assert str(direct.url) == "https://api.openai.com/v1/chat/completions"
    assert direct.content == body
    assert direct.headers["authorization"] == "Bearer sk-openai"
    assert "x-client-header" not in direct.headers
    assert "cookie" not in direct.headers
    assert "proxy-authorization" not in direct.headers
    assert "x-api-key" not in direct.headers
    assert direct.headers["openai-project"] == "project-safe"
    assert direct.headers["idempotency-key"] == "request-safe"
    assert "x-abto-key-anthropic" not in direct.headers
    assert "x-abto-feature-id" not in direct.headers


def test_direct_fallback_preserves_the_request_timeout():
    httpx = pytest.importorskip("httpx")
    observed_timeout = None
    caller_timeout = {
        "connect": 1.0,
        "read": 2.0,
        "write": 3.0,
        "pool": 4.0,
    }

    def gateway_handler(request):
        raise httpx.ConnectError("refused", request=request)

    def direct_handler(request):
        nonlocal observed_timeout
        observed_timeout = request.extensions["timeout"]
        return httpx.Response(200, json={})

    client = _build_fallback_http_client(
        httpx,
        gateway_base_url=DEFAULT_GATEWAY_BASE_URL,
        api_key="abto-test",
        provider_keys={"openai": "sk-openai"},
        fallback=_resolve_fallback(
            OpenAIDirectFallbackOptions(),
            has_openai_key_source=True,
        ),
        gateway_transport=httpx.MockTransport(gateway_handler),
        direct_transport=httpx.MockTransport(direct_handler),
    )
    request = client.build_request(
        "POST",
        f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
        content=b"{}",
    )
    request.extensions["timeout"] = caller_timeout

    try:
        response = client.send(request)
    finally:
        client.close()

    assert response.status_code == 200
    assert observed_timeout == caller_timeout


def test_open_circuit_never_bypasses_the_gateway_origin_boundary():
    httpx = pytest.importorskip("httpx")
    direct_calls = 0

    def direct_handler(_request):
        nonlocal direct_calls
        direct_calls += 1
        return httpx.Response(200, json={})

    client = _build_fallback_http_client(
        httpx,
        gateway_base_url=DEFAULT_GATEWAY_BASE_URL,
        api_key="abto-test",
        provider_keys={"openai": "sk-openai"},
        fallback=_resolve_fallback(
            OpenAIDirectFallbackOptions(),
            has_openai_key_source=True,
        ),
        gateway_transport=httpx.MockTransport(
            lambda _request: httpx.Response(200, json={})
        ),
        direct_transport=httpx.MockTransport(direct_handler),
    )
    client._circuit.open()

    try:
        with pytest.raises(ValueError, match="outside the configured Gateway origin"):
            client.post(
                "https://attacker.example/v1/chat/completions",
                content=b'{"secret":"foreign"}',
            )
    finally:
        client.close()

    assert direct_calls == 0


def test_non_fallback_request_reaches_transport_without_sdk_buffering():
    httpx = pytest.importorskip("httpx")
    stream_reads = 0

    class TrackingStream(httpx.SyncByteStream):
        def __iter__(self):
            nonlocal stream_reads
            stream_reads += 1
            yield b'{"input":"hello"}'

    class InspectingTransport(httpx.BaseTransport):
        def handle_request(self, request):
            assert stream_reads == 0
            return httpx.Response(200, json={"data": []})

    client = _build_fallback_http_client(
        httpx,
        gateway_base_url=DEFAULT_GATEWAY_BASE_URL,
        api_key="abto-test",
        provider_keys={"openai": "sk-openai"},
        fallback=_resolve_fallback(
            OpenAIDirectFallbackOptions(),
            has_openai_key_source=True,
        ),
        gateway_transport=InspectingTransport(),
        direct_transport=httpx.MockTransport(
            lambda _request: httpx.Response(200, json={})
        ),
    )

    try:
        response = client.send(
            httpx.Request(
                "POST",
                f"{DEFAULT_GATEWAY_BASE_URL}/embeddings",
                stream=TrackingStream(),
            )
        )
    finally:
        client.close()

    assert response.status_code == 200
    assert stream_reads == 0


def test_missing_runtime_openai_key_does_not_buffer_the_request():
    httpx = pytest.importorskip("httpx")
    stream_reads = 0

    class TrackingStream(httpx.SyncByteStream):
        def __iter__(self):
            nonlocal stream_reads
            stream_reads += 1
            yield b'{"messages":[]}'

    class InspectingTransport(httpx.BaseTransport):
        def handle_request(self, request):
            assert stream_reads == 0
            return httpx.Response(200, json={})

    client = _build_fallback_http_client(
        httpx,
        gateway_base_url=DEFAULT_GATEWAY_BASE_URL,
        api_key="abto-test",
        provider_keys={"openai": lambda: None},
        fallback=_resolve_fallback(
            True,
            has_openai_key_source=True,
        ),
        gateway_transport=InspectingTransport(),
        direct_transport=httpx.MockTransport(
            lambda _request: httpx.Response(200, json={})
        ),
    )

    try:
        response = client.send(
            httpx.Request(
                "POST",
                f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
                stream=TrackingStream(),
            )
        )
    finally:
        client.close()

    assert response.status_code == 200
    assert stream_reads == 0


def test_callable_provider_key_is_resolved_once_per_request():
    httpx = pytest.importorskip("httpx")
    resolver_calls = 0

    def provider_key():
        nonlocal resolver_calls
        resolver_calls += 1
        return "sk-openai" if resolver_calls == 1 else None

    def gateway_handler(request):
        assert request.headers["x-abto-key-openai"] == "sk-openai"
        return httpx.Response(200, json={})

    client = _build_fallback_http_client(
        httpx,
        gateway_base_url=DEFAULT_GATEWAY_BASE_URL,
        api_key="abto-test",
        provider_keys={"openai": provider_key},
        fallback=_resolve_fallback(
            OpenAIDirectFallbackOptions(),
            has_openai_key_source=True,
        ),
        gateway_transport=httpx.MockTransport(gateway_handler),
        direct_transport=httpx.MockTransport(
            lambda _request: httpx.Response(200, json={})
        ),
    )

    try:
        response = client.post(
            f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
            content=b"{}",
        )
    finally:
        client.close()

    assert response.status_code == 200
    assert resolver_calls == 1


def test_fallback_timeout_only_applies_to_eligible_gateway_requests():
    httpx = pytest.importorskip("httpx")
    observed_timeouts = []

    def gateway_handler(request):
        observed_timeouts.append(request.extensions["timeout"])
        return httpx.Response(200, json={})

    def build_client(*, enabled, provider_keys):
        return _build_fallback_http_client(
            httpx,
            gateway_base_url=DEFAULT_GATEWAY_BASE_URL,
            api_key="abto-test",
            provider_keys=provider_keys,
            fallback=_resolve_fallback(
                OpenAIDirectFallbackOptions(
                    enabled=enabled,
                    timeout_seconds=2.5,
                ),
                has_openai_key_source=provider_keys.get("openai") is not None,
            ),
            gateway_transport=httpx.MockTransport(gateway_handler),
            direct_transport=httpx.MockTransport(
                lambda _request: httpx.Response(200, json={})
            ),
            direct_timeout=httpx.Timeout(123.0, connect=7.0),
        )

    disabled_client = build_client(
        enabled=False,
        provider_keys={"openai": "sk-openai"},
    )
    keyless_client = build_client(
        enabled=True,
        provider_keys={"openai": lambda: None},
    )
    eligible_client = build_client(
        enabled=True,
        provider_keys={"openai": "sk-openai"},
    )

    try:
        disabled_client.post(
            f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
            content=b"{}",
        )
        keyless_client.post(
            f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
            content=b"{}",
        )
        eligible_client.post(
            f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
            content=b"{}",
        )
    finally:
        disabled_client.close()
        keyless_client.close()
        eligible_client.close()

    assert observed_timeouts[0]["read"] == 123.0
    assert observed_timeouts[0]["connect"] == 7.0
    assert observed_timeouts[1]["read"] == 123.0
    assert observed_timeouts[1]["connect"] == 7.0
    assert observed_timeouts[2] == {
        "connect": 2.5,
        "read": 2.5,
        "write": 2.5,
        "pool": 2.5,
    }


def test_stream_body_restores_the_caller_read_timeout_after_headers():
    httpx = pytest.importorskip("httpx")
    observed_header_timeout = None
    observed_body_timeout = None

    class InspectingStream(httpx.SyncByteStream):
        def __init__(self, request):
            self._request = request

        def __iter__(self):
            nonlocal observed_body_timeout
            observed_body_timeout = self._request.extensions["timeout"]["read"]
            yield b"data: done\n\n"

    def gateway_handler(request):
        nonlocal observed_header_timeout
        observed_header_timeout = request.extensions["timeout"]["read"]
        return httpx.Response(200, stream=InspectingStream(request))

    client = _build_fallback_http_client(
        httpx,
        gateway_base_url=DEFAULT_GATEWAY_BASE_URL,
        api_key="abto-test",
        provider_keys={"openai": "sk-openai"},
        fallback=_resolve_fallback(
            OpenAIDirectFallbackOptions(
                timeout_seconds=2.5,
            ),
            has_openai_key_source=True,
        ),
        gateway_transport=httpx.MockTransport(gateway_handler),
        direct_transport=httpx.MockTransport(
            lambda _request: httpx.Response(200, json={})
        ),
        direct_timeout=httpx.Timeout(123.0, connect=7.0),
    )

    try:
        with client.stream(
            "POST",
            f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
            content=b"{}",
        ) as response:
            assert list(response.iter_bytes()) == [b"data: done\n\n"]
    finally:
        client.close()

    assert observed_header_timeout == 2.5
    assert observed_body_timeout == 123.0


@pytest.mark.parametrize(
    ("headers", "expected_direct_calls"),
    [
        ({"x-abto-request-id": "req-admission"}, 1),
        (
            {
                "x-abto-request-id": "req-provider",
                "x-abto-error-source": "provider",
            },
            0,
        ),
        (
            {
                "x-abto-request-id": "req-transport",
                "x-abto-error-source": "transport",
            },
            0,
        ),
    ],
)
def test_only_admission_503_falls_back(headers, expected_direct_calls):
    httpx = pytest.importorskip("httpx")
    direct_calls = 0

    def gateway_handler(_request):
        return httpx.Response(503, headers=headers, json={"error": {}})

    def direct_handler(_request):
        nonlocal direct_calls
        direct_calls += 1
        return httpx.Response(200, json={})

    client = _build_fallback_http_client(
        httpx,
        gateway_base_url=DEFAULT_GATEWAY_BASE_URL,
        api_key="abto-test",
        provider_keys={"openai": "sk-openai"},
        fallback=_resolve_fallback(
            OpenAIDirectFallbackOptions(),
            has_openai_key_source=True,
        ),
        gateway_transport=httpx.MockTransport(gateway_handler),
        direct_transport=httpx.MockTransport(direct_handler),
    )

    try:
        response = client.post(
            f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
            content=b"{}",
        )
    finally:
        client.close()

    assert response.status_code == (200 if expected_direct_calls else 503)
    assert direct_calls == expected_direct_calls


def test_timeout_does_not_open_direct_circuit_without_explicit_opt_in():
    httpx = pytest.importorskip("httpx")
    gateway_calls = 0
    direct_calls = 0

    def gateway_handler(request):
        nonlocal gateway_calls
        gateway_calls += 1
        if gateway_calls == 1:
            raise httpx.ReadTimeout("gateway timed out", request=request)
        return httpx.Response(200, json={})

    def direct_handler(_request):
        nonlocal direct_calls
        direct_calls += 1
        return httpx.Response(200, json={})

    client = _build_fallback_http_client(
        httpx,
        gateway_base_url=DEFAULT_GATEWAY_BASE_URL,
        api_key="abto-test",
        provider_keys={"openai": "sk-openai"},
        fallback=_resolve_fallback(
            OpenAIDirectFallbackOptions(),
            has_openai_key_source=True,
        ),
        gateway_transport=httpx.MockTransport(gateway_handler),
        direct_transport=httpx.MockTransport(direct_handler),
    )

    try:
        with pytest.raises(httpx.ReadTimeout):
            client.post(
                f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
                content=b"{}",
            )
        response = client.post(
            f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
            content=b"{}",
        )
    finally:
        client.close()

    assert response.status_code == 200
    assert gateway_calls == 2
    assert direct_calls == 0


def test_ambiguous_disconnect_does_not_open_direct_circuit():
    httpx = pytest.importorskip("httpx")
    gateway_calls = 0
    direct_calls = 0

    def gateway_handler(request):
        nonlocal gateway_calls
        gateway_calls += 1
        if gateway_calls == 1:
            raise httpx.ReadError("gateway disconnected", request=request)
        return httpx.Response(200, json={})

    def direct_handler(_request):
        nonlocal direct_calls
        direct_calls += 1
        return httpx.Response(200, json={})

    client = _build_fallback_http_client(
        httpx,
        gateway_base_url=DEFAULT_GATEWAY_BASE_URL,
        api_key="abto-test",
        provider_keys={"openai": "sk-openai"},
        fallback=_resolve_fallback(
            OpenAIDirectFallbackOptions(),
            has_openai_key_source=True,
        ),
        gateway_transport=httpx.MockTransport(gateway_handler),
        direct_transport=httpx.MockTransport(direct_handler),
    )

    try:
        with pytest.raises(httpx.ReadError):
            client.post(
                f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
                content=b"{}",
            )
        response = client.post(
            f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
            content=b"{}",
        )
    finally:
        client.close()

    assert response.status_code == 200
    assert gateway_calls == 2
    assert direct_calls == 0


def test_timeout_can_replay_current_request_when_explicitly_enabled():
    httpx = pytest.importorskip("httpx")
    direct_calls = 0

    def gateway_handler(request):
        raise httpx.ReadTimeout("gateway timed out", request=request)

    def direct_handler(_request):
        nonlocal direct_calls
        direct_calls += 1
        return httpx.Response(200, json={})

    client = _build_fallback_http_client(
        httpx,
        gateway_base_url=DEFAULT_GATEWAY_BASE_URL,
        api_key="abto-test",
        provider_keys={"openai": "sk-openai"},
        fallback=_resolve_fallback(
            OpenAIDirectFallbackOptions(
                on_timeout=True,
            ),
            has_openai_key_source=True,
        ),
        gateway_transport=httpx.MockTransport(gateway_handler),
        direct_transport=httpx.MockTransport(direct_handler),
    )

    try:
        response = client.post(
            f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
            content=b"{}",
        )
    finally:
        client.close()

    assert response.status_code == 200
    assert direct_calls == 1


def test_pool_timeout_does_not_open_the_gateway_circuit():
    httpx = pytest.importorskip("httpx")
    gateway_calls = 0
    direct_calls = 0

    def gateway_handler(request):
        nonlocal gateway_calls
        gateway_calls += 1
        if gateway_calls == 1:
            raise httpx.PoolTimeout("local pool exhausted", request=request)
        return httpx.Response(200, json={})

    def direct_handler(_request):
        nonlocal direct_calls
        direct_calls += 1
        return httpx.Response(200, json={})

    client = _build_fallback_http_client(
        httpx,
        gateway_base_url=DEFAULT_GATEWAY_BASE_URL,
        api_key="abto-test",
        provider_keys={"openai": "sk-openai"},
        fallback=_resolve_fallback(
            OpenAIDirectFallbackOptions(),
            has_openai_key_source=True,
        ),
        gateway_transport=httpx.MockTransport(gateway_handler),
        direct_transport=httpx.MockTransport(direct_handler),
    )

    try:
        with pytest.raises(httpx.PoolTimeout):
            client.post(
                f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
                content=b"{}",
            )
        response = client.post(
            f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
            content=b"{}",
        )
    finally:
        client.close()

    assert response.status_code == 200
    assert gateway_calls == 2
    assert direct_calls == 0


def test_keyless_pool_timeout_does_not_open_the_gateway_circuit():
    httpx = pytest.importorskip("httpx")
    gateway_calls = 0
    direct_calls = 0
    resolver_calls = 0

    def provider_key():
        nonlocal resolver_calls
        resolver_calls += 1
        return None if resolver_calls == 1 else "sk-openai"

    def gateway_handler(request):
        nonlocal gateway_calls
        gateway_calls += 1
        if gateway_calls == 1:
            raise httpx.PoolTimeout("local pool exhausted", request=request)
        return httpx.Response(200, json={})

    def direct_handler(_request):
        nonlocal direct_calls
        direct_calls += 1
        return httpx.Response(200, json={})

    client = _build_fallback_http_client(
        httpx,
        gateway_base_url=DEFAULT_GATEWAY_BASE_URL,
        api_key="abto-test",
        provider_keys={"openai": provider_key},
        fallback=_resolve_fallback(
            OpenAIDirectFallbackOptions(),
            has_openai_key_source=True,
        ),
        gateway_transport=httpx.MockTransport(gateway_handler),
        direct_transport=httpx.MockTransport(direct_handler),
    )

    try:
        with pytest.raises(httpx.PoolTimeout):
            client.post(
                f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
                content=b"{}",
            )
        response = client.post(
            f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
            content=b"{}",
        )
    finally:
        client.close()

    assert response.status_code == 200
    assert gateway_calls == 2
    assert direct_calls == 0


def test_half_open_pool_timeout_releases_the_probe_slot():
    httpx = pytest.importorskip("httpx")
    gateway_calls = 0
    direct_calls = 0

    def gateway_handler(request):
        nonlocal gateway_calls
        gateway_calls += 1
        if gateway_calls == 1:
            raise httpx.PoolTimeout("local pool exhausted", request=request)
        return httpx.Response(200, json={})

    def direct_handler(_request):
        nonlocal direct_calls
        direct_calls += 1
        return httpx.Response(200, json={})

    client = _build_fallback_http_client(
        httpx,
        gateway_base_url=DEFAULT_GATEWAY_BASE_URL,
        api_key="abto-test",
        provider_keys={"openai": "sk-openai"},
        fallback=_resolve_fallback(
            OpenAIDirectFallbackOptions(),
            has_openai_key_source=True,
        ),
        gateway_transport=httpx.MockTransport(gateway_handler),
        direct_transport=httpx.MockTransport(direct_handler),
    )

    try:
        client._circuit.open()
        client._circuit._opened_at = (
            client_module.time.monotonic()
            - client_module._CIRCUIT_OPEN_SECONDS
            - 1
        )
        with pytest.raises(httpx.PoolTimeout):
            client.post(
                f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
                content=b"{}",
            )
        response = client.post(
            f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
            content=b"{}",
        )
    finally:
        client.close()

    assert response.status_code == 200
    assert gateway_calls == 2
    assert direct_calls == 0


def test_keyless_gateway_recovery_closes_the_completion_circuit():
    httpx = pytest.importorskip("httpx")
    gateway_calls = 0
    direct_calls = 0
    current_key = "sk-openai"

    def provider_key():
        return current_key

    def gateway_handler(request):
        nonlocal gateway_calls
        gateway_calls += 1
        if gateway_calls == 1:
            raise httpx.ReadTimeout("gateway timed out", request=request)
        return httpx.Response(200, json={})

    def direct_handler(_request):
        nonlocal direct_calls
        direct_calls += 1
        return httpx.Response(200, json={})

    client = _build_fallback_http_client(
        httpx,
        gateway_base_url=DEFAULT_GATEWAY_BASE_URL,
        api_key="abto-test",
        provider_keys={"openai": provider_key},
        fallback=_resolve_fallback(
            OpenAIDirectFallbackOptions(),
            has_openai_key_source=True,
        ),
        gateway_transport=httpx.MockTransport(gateway_handler),
        direct_transport=httpx.MockTransport(direct_handler),
    )

    try:
        with pytest.raises(httpx.ReadTimeout):
            client.post(
                f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
                content=b"{}",
            )
        client._circuit._opened_at = (
            client_module.time.monotonic()
            - client_module._CIRCUIT_OPEN_SECONDS
            - 1
        )
        current_key = None
        keyless_recovery = client.post(
            f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
            content=b"{}",
        )
        current_key = "sk-openai"
        response = client.post(
            f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
            content=b"{}",
        )
    finally:
        client.close()

    assert keyless_recovery.status_code == 200
    assert response.status_code == 200
    assert gateway_calls == 3
    assert direct_calls == 0


def test_unrelated_gateway_success_does_not_close_completion_circuit():
    httpx = pytest.importorskip("httpx")
    gateway_calls = 0
    direct_calls = 0

    def gateway_handler(request):
        nonlocal gateway_calls
        gateway_calls += 1
        if request.url.path.endswith("/chat/completions"):
            raise httpx.ConnectError("gateway unavailable", request=request)
        return httpx.Response(200, json={"data": []})

    def direct_handler(_request):
        nonlocal direct_calls
        direct_calls += 1
        return httpx.Response(200, json={})

    client = _build_fallback_http_client(
        httpx,
        gateway_base_url=DEFAULT_GATEWAY_BASE_URL,
        api_key="abto-test",
        provider_keys={"openai": "sk-openai"},
        fallback=_resolve_fallback(
            OpenAIDirectFallbackOptions(),
            has_openai_key_source=True,
        ),
        gateway_transport=httpx.MockTransport(gateway_handler),
        direct_transport=httpx.MockTransport(direct_handler),
    )

    try:
        first_completion = client.post(
            f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
            content=b"{}",
        )
        models = client.get(f"{DEFAULT_GATEWAY_BASE_URL}/models")
        completion = client.post(
            f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
            content=b"{}",
        )
    finally:
        client.close()

    assert first_completion.status_code == 200
    assert models.status_code == 200
    assert completion.status_code == 200
    assert gateway_calls == 2
    assert direct_calls == 2


def test_separate_openai_clients_can_share_the_completion_circuit():
    httpx = pytest.importorskip("httpx")
    gateway_calls = 0
    direct_calls = 0

    def gateway_handler(request):
        nonlocal gateway_calls
        gateway_calls += 1
        raise httpx.ConnectError("refused", request=request)

    def direct_handler(_request):
        nonlocal direct_calls
        direct_calls += 1
        return httpx.Response(200, json={})

    fallback = _resolve_fallback(
        OpenAIDirectFallbackOptions(),
        has_openai_key_source=True,
    )
    first = _build_fallback_http_client(
        httpx,
        gateway_base_url=DEFAULT_GATEWAY_BASE_URL,
        api_key="abto-test",
        provider_keys={"openai": "sk-openai"},
        fallback=fallback,
        gateway_transport=httpx.MockTransport(gateway_handler),
        direct_transport=httpx.MockTransport(direct_handler),
    )
    second = _build_fallback_http_client(
        httpx,
        gateway_base_url=DEFAULT_GATEWAY_BASE_URL,
        api_key="abto-test",
        provider_keys={"openai": "sk-openai"},
        fallback=fallback,
        gateway_transport=httpx.MockTransport(gateway_handler),
        direct_transport=httpx.MockTransport(direct_handler),
        circuit=first._circuit,
    )

    try:
        first_response = first.post(
            f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
            content=b"{}",
        )
        second_response = second.post(
            f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
            content=b"{}",
        )
    finally:
        first.close()
        second.close()

    assert first_response.status_code == 200
    assert second_response.status_code == 200
    assert gateway_calls == 1
    assert direct_calls == 2


def test_direct_openai_error_is_returned_without_retry_or_reclassification():
    httpx = pytest.importorskip("httpx")
    gateway_calls = 0
    direct_calls = 0

    def gateway_handler(request):
        nonlocal gateway_calls
        gateway_calls += 1
        raise httpx.ConnectError("refused", request=request)

    def direct_handler(_request):
        nonlocal direct_calls
        direct_calls += 1
        return httpx.Response(500, json={})

    client = _build_fallback_http_client(
        httpx,
        gateway_base_url=DEFAULT_GATEWAY_BASE_URL,
        api_key="abto-test",
        provider_keys={"openai": "sk-openai"},
        fallback=_resolve_fallback(
            OpenAIDirectFallbackOptions(),
            has_openai_key_source=True,
        ),
        gateway_transport=httpx.MockTransport(gateway_handler),
        direct_transport=httpx.MockTransport(direct_handler),
    )

    try:
        response = client.post(
            f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
            content=b"{}",
        )
    finally:
        client.close()

    assert response.status_code == 500
    assert gateway_calls == 1
    assert direct_calls == 1


def test_fallback_defaults_off_without_an_openai_key_source():
    resolved = _resolve_fallback(None, has_openai_key_source=False)

    assert resolved.enabled is False


def test_fallback_configuration_is_validated():
    with pytest.raises(ValueError, match="fallback.timeout_seconds"):
        init_abto(
            api_key="abto-test",
            fallback=OpenAIDirectFallbackOptions(timeout_seconds=0),
        )
    for invalid_timeout in (float("nan"), float("inf"), float("-inf")):
        with pytest.raises(ValueError, match="fallback.timeout_seconds"):
            init_abto(
                api_key="abto-test",
                fallback=OpenAIDirectFallbackOptions(
                    timeout_seconds=invalid_timeout
                ),
            )


def test_stream_failure_after_response_headers_is_not_replayed():
    httpx = pytest.importorskip("httpx")
    gateway_calls = 0
    direct_calls = 0

    class FailingStream(httpx.SyncByteStream):
        def __iter__(self):
            raise httpx.ReadTimeout("stream interrupted")
            yield b""  # pragma: no cover

    def gateway_handler(_request):
        nonlocal gateway_calls
        gateway_calls += 1
        if gateway_calls > 1:
            return httpx.Response(200, json={})
        return httpx.Response(
            200,
            headers={"content-type": "text/event-stream"},
            stream=FailingStream(),
        )

    def direct_handler(_request):
        nonlocal direct_calls
        direct_calls += 1
        return httpx.Response(200, json={})

    client = _build_fallback_http_client(
        httpx,
        gateway_base_url=DEFAULT_GATEWAY_BASE_URL,
        api_key="abto-test",
        provider_keys={"openai": "sk-openai"},
        fallback=_resolve_fallback(
            OpenAIDirectFallbackOptions(on_timeout=True),
            has_openai_key_source=True,
        ),
        gateway_transport=httpx.MockTransport(gateway_handler),
        direct_transport=httpx.MockTransport(direct_handler),
    )

    try:
        with client.stream(
            "POST",
            f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
            content=b"{}",
        ) as response:
            with pytest.raises(httpx.ReadTimeout):
                list(response.iter_bytes())
        recovered = client.post(
            f"{DEFAULT_GATEWAY_BASE_URL}/chat/completions",
            content=b"{}",
        )
    finally:
        client.close()

    assert recovered.status_code == 200
    assert gateway_calls == 2
    assert direct_calls == 0


def test_openai_client_keeps_official_retry_default(monkeypatch):
    httpx = pytest.importorskip("httpx")
    openai_module = pytest.importorskip("openai")
    http_client = httpx.Client(
        transport=httpx.MockTransport(lambda _request: httpx.Response(200, json={}))
    )

    monkeypatch.setattr(
        client_module,
        "_build_fallback_http_client",
        lambda *_args, **_kwargs: http_client,
    )
    abto = init_abto(
        api_key="abto-test",
        provider_keys={"openai": "sk-openai"},
    )
    openai = abto.openai()

    try:
        assert openai.max_retries == openai_module.DEFAULT_MAX_RETRIES
    finally:
        openai.close()


def test_openai_client_preserves_outer_retry_setting(monkeypatch):
    httpx = pytest.importorskip("httpx")
    pytest.importorskip("openai")

    def handler(_request):
        return httpx.Response(
            200,
            json={
                "id": "chatcmpl-gateway",
                "object": "chat.completion",
                "created": 1,
                "model": "gpt-4o-mini",
                "choices": [
                    {
                        "index": 0,
                        "message": {"role": "assistant", "content": "ok"},
                        "finish_reason": "stop",
                    }
                ],
                "usage": {
                    "prompt_tokens": 1,
                    "completion_tokens": 1,
                    "total_tokens": 2,
                },
            },
        )

    http_client = httpx.Client(transport=httpx.MockTransport(handler))
    captured_builder_options = {}

    def build_http_client(*_args, **kwargs):
        captured_builder_options.update(kwargs)
        return http_client

    monkeypatch.setattr(
        client_module,
        "_build_fallback_http_client",
        build_http_client,
    )
    abto = init_abto(
        api_key="abto-test",
        provider_keys={"openai": "sk-openai"},
    )
    openai = abto.openai(max_retries=9, timeout=123.0)

    try:
        completion = openai.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": "hello"}],
        )
    finally:
        openai.close()

    assert openai.max_retries == 9
    assert captured_builder_options["direct_timeout"] == 123.0
    assert completion.id == "chatcmpl-gateway"
    assert completion.choices[0].message.content == "ok"
