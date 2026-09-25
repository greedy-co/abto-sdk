"""Response lifecycle failures must not corrupt another Gateway recovery probe."""
import asyncio

import pytest

from abto import OpenAIDirectFallbackOptions
from abto.async_client import _build_async_fallback_http_client
from abto.client import _CircuitBreaker, _build_fallback_http_client, _resolve_fallback

GATEWAY = 'https://gateway.example/v1'
DIRECT = 'https://provider.example/v1'


@pytest.mark.parametrize('module', ['httpx', 'httpx2'])
@pytest.mark.parametrize('asynchronous', [False, True], ids=['sync', 'async'])
@pytest.mark.parametrize('failure_at', ['body', 'close', 'read'])
def test_response_failure_preserves_recovery(module, asynchronous, failure_at, monkeypatch):
    h = pytest.importorskip(module)
    calls = []
    closed = []
    clock = [0.0]
    monkeypatch.setattr('abto.client.time.monotonic', lambda: clock[0])
    circuit = _CircuitBreaker()
    failure = RuntimeError('synthetic close failure') if failure_at == 'close' else h.ReadError('synthetic body failure')

    class SyncBody(h.SyncByteStream):
        def __iter__(self):
            if failure_at != 'close':
                raise failure
            yield b'{}'

        def close(self):
            closed.append(True)
            if failure_at == 'close':
                raise failure

    class AsyncBody(h.AsyncByteStream):
        async def __aiter__(self):
            if failure_at != 'close':
                raise failure
            yield b'{}'

        async def aclose(self):
            closed.append(True)
            if failure_at == 'close':
                raise failure

    def gateway(request):
        calls.append(request.url.host)
        if len(calls) == 1:
            return h.Response(503 if failure_at == 'close' else 200,
                              stream=AsyncBody() if asynchronous else SyncBody())
        return h.Response(200, json={})

    def direct(request):
        calls.append(request.url.host)
        return h.Response(200, json={})

    async def run():
        builder = _build_async_fallback_http_client if asynchronous else _build_fallback_http_client
        client = builder(
            h, gateway_base_url=GATEWAY, api_key='synthetic',
            provider_keys={'openai': 'synthetic'},
            fallback=_resolve_fallback(OpenAIDirectFallbackOptions(base_url=DIRECT), has_openai_key_source=True),
            gateway_transport=h.MockTransport(gateway), direct_transport=h.MockTransport(direct), circuit=circuit,
        )
        try:
            if failure_at == 'read':
                with pytest.raises(h.ReadError) as caught:
                    if asynchronous:
                        await client.post(GATEWAY + '/chat/completions', json={})
                    else:
                        client.post(GATEWAY + '/chat/completions', json={})
                assert caught.value is failure
                assert closed == [True]
                assert calls == ['gateway.example']
                return
            if failure_at == 'body':
                request = client.build_request('POST', GATEWAY + '/chat/completions', json={})
                response = await client.send(request, stream=True) if asynchronous else client.send(request, stream=True)
                # A newer request has already reserved the recovery probe.
                circuit.open()
                clock[0] = 1000
                assert circuit.should_bypass() is False
                with pytest.raises(type(failure)) as caught:
                    if asynchronous:
                        await response.aread()
                    else:
                        response.read()
                assert caught.value is failure
                if asynchronous:
                    await response.aclose()
                else:
                    response.close()
            else:
                circuit.open()
                clock[0] = 1000
                with pytest.raises(RuntimeError) as caught:
                    if asynchronous:
                        await client.post(GATEWAY + '/chat/completions', json={})
                    else:
                        client.post(GATEWAY + '/chat/completions', json={})
                assert caught.value is failure
                assert calls == ['gateway.example']
                clock[0] = 2000
            if asynchronous:
                await client.post(GATEWAY + '/chat/completions', json={})
            else:
                client.post(GATEWAY + '/chat/completions', json={})
            assert calls == ['gateway.example', 'provider.example' if failure_at == 'body' else 'gateway.example']
        finally:
            if asynchronous:
                await client.aclose()
            else:
                client.close()

    asyncio.run(run())
