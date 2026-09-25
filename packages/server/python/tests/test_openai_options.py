import asyncio
import json

import httpx
import pytest

from abto import wrap_httpx_transport, OpenAIDirectFallbackOptions, init_abto
from abto.async_client import _build_async_fallback_http_client
from abto.client import _CircuitBreaker, _build_fallback_http_client, _resolve_fallback

GATEWAY = 'https://gateway.example/v1'
DIRECT = 'https://provider.example/v1'


def make_abto(**kwargs):
    return init_abto(api_key='synthetic-calling-secret', gateway_base_url=GATEWAY,
                     provider_keys={'openai': 'synthetic-provider-secret'}, **kwargs)


def test_options_keep_customer_configuration_and_borrowed_client():
    requests, hooks = [], []
    def handler(request):
        requests.append(request)
        return httpx.Response(200, json={})
    customer = httpx.Client(transport=wrap_httpx_transport(httpx.MockTransport(handler)),
                            headers={'x-customer': 'kept'}, params={'tenant': 'one'},
                            event_hooks={'request': [lambda request: hooks.append(request.url)]}, timeout=17)
    abto = make_abto()
    options = abto.openai_options(http_client=customer, api_key='old-key', base_url=DIRECT,
                                  max_retries=0, organization='org', default_headers={'traceparent': 'customer'})
    assert options['api_key'] == 'abto-transport-placeholder'
    assert options['base_url'] == GATEWAY
    assert options['max_retries'] == 0 and options['organization'] == 'org'
    assert options['default_headers'] == {'traceparent': 'customer'}
    with options['http_client'] as client:
        with abto.with_context(feature_id='support.reply', device_id='device-one'):
            client.post(GATEWAY + '/chat/completions', json={})
        with pytest.raises(ValueError, match='outside the configured Gateway origin'):
            client.post(DIRECT + '/chat/completions', json={})
    assert not customer.is_closed
    assert options['http_client']._direct_client.is_closed
    customer.close()
    assert len(requests) == len(hooks) == 1
    request = requests[0]
    assert request.headers['authorization'] == 'Bearer synthetic-calling-secret'
    assert request.headers['x-abto-key-openai'] == 'synthetic-provider-secret'
    assert request.headers['x-abto-device-id'] == 'device-one'
    assert request.headers['x-customer'] == 'kept'
    assert request.url.params['tenant'] == 'one'
    assert request.extensions['timeout']['read'] == 17


def test_options_validate_client_type_before_use():
    abto = make_abto()
    with httpx.Client() as client:
        with pytest.raises(TypeError, match='AsyncClient'):
            abto.async_openai_options(http_client=client)


def test_async_options_preserve_concurrent_context_and_customer_hooks():
    async def run():
        seen, hooks = [], []
        async def hook(request):
            hooks.append(request.headers['x-abto-device-id'])
        async def handler(request):
            await asyncio.sleep(0.01)
            seen.append(dict(request.headers))
            return httpx.Response(200, json={})
        async with httpx.AsyncClient(transport=wrap_httpx_transport(httpx.MockTransport(handler)), event_hooks={'request': [hook]}) as customer:
            abto = make_abto()
            options = abto.async_openai_options(http_client=customer)
            async with options['http_client'] as client:
                async def call(device):
                    with abto.with_context(feature_id='reply', device_id=device, trace_id='a' * 32):
                        await client.post(GATEWAY + '/chat/completions', json={},
                                          headers={'traceparent': 'customer-' + device, 'tracestate': 'state=' + device})
                await asyncio.gather(call('one'), call('two'))
            assert not customer.is_closed
            assert client._direct_client.is_closed
        assert sorted(hooks) == ['one', 'two']
        assert {row['x-abto-device-id'] for row in seen} == {'one', 'two'}
        for row in seen:
            assert row['traceparent'] == 'customer-' + row['x-abto-device-id']
            assert row['tracestate'] == 'state=' + row['x-abto-device-id']
    asyncio.run(run())


@pytest.mark.parametrize('module', ['httpx', 'httpx2'])
@pytest.mark.parametrize('asynchronous', [False, True])
@pytest.mark.parametrize('status,headers,expected_direct', [
    (502, {}, True), (503, {}, True), (504, {}, True),
    (503, {'x-abto-request-id': 'req', 'x-abto-error-source': 'gateway'}, True),
    (503, {'x-abto-request-id': 'req', 'x-abto-error-source': 'provider'}, False),
    (503, {'x-abto-request-id': 'req', 'x-abto-error-source': 'transport'}, False),
    (429, {}, False), (400, {}, False), (200, {}, False),
])
def test_fallback_status_policy(module, asynchronous, status, headers, expected_direct):
    h = pytest.importorskip(module)
    direct, gateway = [], []

    def handler(request):
        gateway.append(request)
        return h.Response(status, headers=headers, json={})

    def direct_handler(request):
        direct.append(request)
        return h.Response(200, json={})

    builder = _build_async_fallback_http_client if asynchronous else _build_fallback_http_client
    client = builder(
        h, gateway_base_url=GATEWAY, api_key='synthetic-calling-secret',
        provider_keys={'openai': 'synthetic-provider-secret'},
        fallback=_resolve_fallback(OpenAIDirectFallbackOptions(base_url=DIRECT), has_openai_key_source=True),
        gateway_transport=wrap_httpx_transport(h.MockTransport(handler)),
        direct_transport=wrap_httpx_transport(h.MockTransport(direct_handler)))
    request_options = {
        'json': {'messages': ['unchanged']},
        'headers': {'traceparent': 'customer', 'tracestate': 'customer=1',
                    'cookie': 'private', 'x-customer': 'private'},
    }
    if asynchronous:
        async def run():
            async with client:
                for _ in range(2):
                    await client.post(GATEWAY + '/chat/completions', **request_options)
        asyncio.run(run())
    else:
        with client:
            for _ in range(2):
                client.post(GATEWAY + '/chat/completions', **request_options)

    assert len(direct) == (2 if expected_direct else 0)
    assert len(gateway) == (1 if expected_direct else 2)
    for request in direct:
        assert request.headers['authorization'] == 'Bearer synthetic-provider-secret'
        assert request.headers['traceparent'] == 'customer'
        assert request.headers['tracestate'] == 'customer=1'
        assert not any(key.startswith('x-abto-') for key in request.headers)
        assert 'cookie' not in request.headers and 'x-customer' not in request.headers
        assert json.loads(request.content) == {'messages': ['unchanged']}


@pytest.mark.parametrize('module', ['httpx', 'httpx2'])
@pytest.mark.parametrize('asynchronous', [False, True])
@pytest.mark.parametrize('error_name,on_timeout,expected_direct', [
    ('ConnectError', False, True), ('ConnectTimeout', False, True),
    ('ReadTimeout', False, False), ('WriteTimeout', False, False),
    ('ReadTimeout', True, True), ('WriteTimeout', True, True),
    ('PoolTimeout', True, False), ('ReadError', True, False),
])
def test_fallback_network_policy(module, asynchronous, error_name, on_timeout, expected_direct):
    h = pytest.importorskip(module)
    error = getattr(h, error_name)
    direct, gateway_timeouts = [], []
    failure = error('Synthetic network failure')

    def handler(request):
        gateway_timeouts.append(dict(request.extensions['timeout']))
        raise failure

    def direct_handler(request):
        direct.append(request)
        return h.Response(200, json={})

    builder = _build_async_fallback_http_client if asynchronous else _build_fallback_http_client
    client = builder(
        h, gateway_base_url=GATEWAY, api_key='synthetic', provider_keys={'openai': 'synthetic'},
        fallback=_resolve_fallback(OpenAIDirectFallbackOptions(
            base_url=DIRECT, on_timeout=on_timeout, timeout_seconds=2), has_openai_key_source=True),
        gateway_transport=wrap_httpx_transport(h.MockTransport(handler)),
        direct_transport=wrap_httpx_transport(h.MockTransport(direct_handler)))
    request = client.build_request('POST', GATEWAY + '/chat/completions', json={}, timeout=17)
    original_timeout = request.extensions['timeout']
    if asynchronous:
        async def run():
            async with client:
                if expected_direct:
                    await client.send(request)
                else:
                    with pytest.raises(error) as caught:
                        await client.send(request)
                    assert caught.value is failure
        asyncio.run(run())
    else:
        with client:
            if expected_direct:
                client.send(request)
            else:
                with pytest.raises(error) as caught:
                    client.send(request)
                assert caught.value is failure

    assert request.extensions['timeout'] is original_timeout
    assert original_timeout == h.Timeout(17).as_dict()
    assert gateway_timeouts == [h.Timeout(2).as_dict()]
    assert len(direct) == int(expected_direct)


def test_async_body_failure_does_not_replay():
    async def run():
        direct = []
        class FailingBody(httpx.AsyncByteStream):
            async def __aiter__(self):
                yield b'partial'
                raise httpx.ReadTimeout('Synthetic body failure')
        async with _build_async_fallback_http_client(
            httpx, gateway_base_url=GATEWAY, api_key='synthetic', provider_keys={'openai': 'synthetic'},
            fallback=_resolve_fallback(OpenAIDirectFallbackOptions(base_url=DIRECT, on_timeout=True), has_openai_key_source=True),
            gateway_transport=httpx.MockTransport(lambda r: httpx.Response(200, stream=FailingBody())),
            direct_transport=httpx.MockTransport(lambda r: direct.append(r))) as client:
            with pytest.raises(httpx.ReadTimeout):
                await client.post(GATEWAY + '/chat/completions', json={})
        assert not direct
    asyncio.run(run())


def test_async_cancelled_half_open_probe_can_retry(monkeypatch):
    async def run():
        circuit = _CircuitBreaker()
        circuit.open()
        monkeypatch.setattr('abto.client.time.monotonic', lambda: 10**12)
        async def handler(request):
            raise asyncio.CancelledError()
        async with _build_async_fallback_http_client(
            httpx, gateway_base_url=GATEWAY, api_key='synthetic', provider_keys={'openai': 'synthetic'},
            fallback=_resolve_fallback(OpenAIDirectFallbackOptions(base_url=DIRECT), has_openai_key_source=True),
            gateway_transport=wrap_httpx_transport(httpx.MockTransport(handler)), circuit=circuit) as client:
            with pytest.raises(asyncio.CancelledError):
                await client.post(GATEWAY + '/chat/completions', json={})
        assert circuit.should_bypass() is False
    asyncio.run(run())


def test_sync_and_async_options_share_circuit():
    async def run():
        abto = make_abto(fallback=OpenAIDirectFallbackOptions(base_url=DIRECT))
        sync = abto.openai_options()
        asynchronous = abto.async_openai_options()
        try:
            assert sync['http_client']._circuit is asynchronous['http_client']._circuit
        finally:
            sync['http_client'].close()
            await asynchronous['http_client'].aclose()
    asyncio.run(run())


def test_borrowed_client_hooks_observe_fallback_without_default_auth_or_header_leaks():
    observed = []
    def handler(request):
        observed.append(request)
        if request.url.host == 'gateway.example':
            return httpx.Response(503, json={})
        return httpx.Response(200, json={})
    hooks = []
    with httpx.Client(transport=wrap_httpx_transport(httpx.MockTransport(handler)), auth=('old-user', 'old-password'),
                      headers={'x-private': 'gateway-only'}, event_hooks={'response': [lambda r: hooks.append(r.status_code)]}) as customer:
        abto = make_abto(fallback=OpenAIDirectFallbackOptions(base_url=DIRECT))
        with abto.openai_options(http_client=customer)['http_client'] as client:
            client.post(GATEWAY + '/chat/completions', json={})
    assert hooks == [503, 200]
    assert observed[0].headers['authorization'] == 'Bearer synthetic-calling-secret'
    assert observed[1].headers['authorization'] == 'Bearer synthetic-provider-secret'
    assert 'x-private' not in observed[1].headers
    assert not any(key.startswith('x-abto-') for key in observed[1].headers)


def test_borrowed_client_does_not_follow_credential_redirects():
    observed = []
    def handler(request):
        observed.append(request)
        return httpx.Response(307, headers={'location': 'https://untrusted.example/steal'})
    with httpx.Client(transport=wrap_httpx_transport(httpx.MockTransport(handler)), follow_redirects=True) as customer:
        with make_abto().openai_options(http_client=customer)['http_client'] as client:
            assert client.post(GATEWAY + '/chat/completions', json={}).status_code == 307
    assert len(observed) == 1


def test_borrowed_client_keeps_live_defaults_and_cookie_updates():
    seen = []
    def handler(request):
        seen.append(request)
        return httpx.Response(200, headers={'set-cookie': 'session=updated; Path=/v1'}, json={})
    with httpx.Client(transport=wrap_httpx_transport(httpx.MockTransport(handler))) as customer:
        with make_abto().openai_options(http_client=customer)['http_client'] as client:
            client.post(GATEWAY + '/chat/completions', json={})
            customer.headers['x-customer'] = 'updated'
            customer.params = {'tenant': 'updated'}
            client.post(GATEWAY + '/chat/completions', json={})
    assert seen[1].headers['cookie'] == 'session=updated'
    assert seen[1].headers['x-customer'] == 'updated'
    assert seen[1].url.params['tenant'] == 'updated'
