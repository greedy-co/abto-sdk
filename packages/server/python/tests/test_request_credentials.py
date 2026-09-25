"""Regression: OpenAI error.request must not retain ABTO provider credentials."""
import asyncio
import openai
import pytest
from abto import init_abto, OpenAIDirectFallbackOptions, wrap_httpx_transport

@pytest.mark.parametrize('module', ['httpx', 'httpx2'])
@pytest.mark.parametrize('asynchronous', [False, True], ids=['sync', 'async'])
def test_bypass_exception_request_has_no_provider_credentials(module, asynchronous):
    h = pytest.importorskip(module)
    def handler(request):
        raise h.ConnectError('synthetic direct provider unavailable', request=request)
    async def run():
        abto = init_abto(
            api_key='synthetic-calling', gateway_base_url='https://gateway.example/v1',
            provider_keys={'openai':'synthetic-provider'},
            fallback=OpenAIDirectFallbackOptions(base_url='https://provider.example/v1'),
        )
        customer = (h.AsyncClient if asynchronous else h.Client)(transport=wrap_httpx_transport(h.MockTransport(handler)))
        options = (abto.async_openai_options if asynchronous else abto.openai_options)(http_client=customer)
        client = (openai.AsyncOpenAI if asynchronous else openai.OpenAI)(**options, max_retries=0)
        abto._fallback_circuit.open()
        try:
            with pytest.raises(openai.APIConnectionError) as caught:
                if asynchronous:
                    await client.chat.completions.create(model='gpt-4.1-mini', messages=[{'role':'user','content':'synthetic'}])
                else:
                    client.chat.completions.create(model='gpt-4.1-mini', messages=[{'role':'user','content':'synthetic'}])
            assert 'synthetic-provider' not in repr(caught.value.request.extensions)
        finally:
            if asynchronous:
                await client.close()
                await customer.aclose()
            else:
                client.close()
                customer.close()
    asyncio.run(run())


@pytest.mark.parametrize('module', ['httpx', 'httpx2'])
@pytest.mark.parametrize('asynchronous', [False, True], ids=['sync', 'async'])
@pytest.mark.parametrize('outcome', ['bypass-success', 'bypass-error', 'body-error', 'customer-closed'])
def test_original_request_extensions_stay_private_during_dispatch(module, asynchronous, outcome):
    import json
    h = pytest.importorskip(module)
    snapshots, calls = [], []
    request = None

    def snapshot():
        snapshots.append(json.dumps(request.extensions))

    class Body(h.SyncByteStream):
        def __iter__(self):
            snapshot()
            raise h.ReadError('synthetic request body failure')
            yield b''  # pragma: no cover

    class AsyncBody(h.AsyncByteStream):
        async def __aiter__(self):
            snapshot()
            raise h.ReadError('synthetic request body failure')
            yield b''  # pragma: no cover

    def handler(outgoing):
        snapshot()
        calls.append(outgoing.url.host)
        if outcome == 'bypass-error':
            raise h.ConnectError('synthetic provider unavailable', request=outgoing)
        return h.Response(200, json={})

    async def run():
        nonlocal request
        abto = init_abto(api_key='synthetic-calling', gateway_base_url='https://gateway.example/v1',
                         provider_keys={'openai': 'synthetic-provider'},
                         fallback=OpenAIDirectFallbackOptions(base_url='https://provider.example/v1'))
        customer = (h.AsyncClient if asynchronous else h.Client)(transport=wrap_httpx_transport(h.MockTransport(handler)))
        wrapper = (abto.async_openai_options if asynchronous else abto.openai_options)(http_client=customer)['http_client']
        content = (AsyncBody() if asynchronous else Body()) if outcome == 'body-error' else b'{}'
        request = wrapper.build_request('POST', 'https://gateway.example/v1/chat/completions', content=content)
        request.extensions['customer'] = {'tracking': 'preserved'}
        if outcome.startswith('bypass'):
            abto._fallback_circuit.open()
        elif outcome == 'customer-closed':
            if asynchronous:
                await customer.aclose()
            else:
                customer.close()
        expected = {'bypass-error': h.ConnectError, 'body-error': h.ReadError, 'customer-closed': RuntimeError}
        try:
            async def send():
                return await wrapper.send(request) if asynchronous else wrapper.send(request)
            if outcome in expected:
                with pytest.raises(expected[outcome]):
                    await send()
            else:
                response = await send()
                assert response.status_code == 200
            snapshot()
            assert request.extensions['customer'] == {'tracking': 'preserved'}
            assert calls == (['provider.example'] if outcome.startswith('bypass') else [])
            assert all('synthetic-provider' not in value and 'synthetic-calling' not in value for value in snapshots)
        finally:
            if asynchronous:
                await wrapper.aclose()
                await customer.aclose()
            else:
                wrapper.close()
                customer.close()

    asyncio.run(run())
