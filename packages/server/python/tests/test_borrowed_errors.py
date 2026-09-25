"""Regression: customer observer connection failures must never replay completed calls."""
import asyncio
import pytest
from abto import OpenAIDirectFallbackOptions, init_abto, wrap_httpx_transport

@pytest.mark.parametrize('asynchronous', [False, True], ids=['sync', 'async'])
@pytest.mark.parametrize('module', ['httpx', 'httpx2'])
@pytest.mark.parametrize('error_name', ['ConnectError', 'ConnectTimeout', 'ReadTimeout', 'WriteTimeout'])
@pytest.mark.parametrize('on_timeout', [False, True])
@pytest.mark.parametrize('failure_at', ['request_hook', 'response_hook', 'send_override'])
def test_observer_connection_failure_must_not_replay(asynchronous, module, error_name, failure_at, on_timeout, monkeypatch):
    httpx = pytest.importorskip(module)
    error_type = getattr(httpx, error_name)
    wire_calls = []
    failure = error_type('synthetic logger unavailable', request=httpx.Request('POST', 'https://logger.example/events'))

    def handler(request):
        wire_calls.append(request.url.host)
        return httpx.Response(200, json={'ok': True})

    failing = True

    def observe(value):
        request = value.request if isinstance(value, httpx.Response) else value
        if failing and request.url.host == 'gateway.example':
            raise failure

    async def async_observe(response):
        observe(response)

    class Customer(httpx.Client):
        def send(self, request, **kwargs):
            response = super().send(request, **kwargs)
            if failure_at == 'send_override':
                observe(response)
            return response

    class AsyncCustomer(httpx.AsyncClient):
        async def send(self, request, **kwargs):
            response = await super().send(request, **kwargs)
            if failure_at == 'send_override':
                observe(response)
            return response

    async def scenario():
        nonlocal failing
        abto = init_abto(
            api_key='synthetic-calling',
            gateway_base_url='https://gateway.example/v1',
            provider_keys={'openai': 'synthetic-provider'},
            fallback=OpenAIDirectFallbackOptions(base_url='https://provider.example/v1', on_timeout=on_timeout),
        )
        customer = (AsyncCustomer if asynchronous else Customer)(
            transport=wrap_httpx_transport(httpx.MockTransport(handler)),
            event_hooks={failure_at.removesuffix('_hook'): [async_observe if asynchronous else observe]} if failure_at != 'send_override' else {},
        )
        wrapper = (abto.async_openai_options if asynchronous else abto.openai_options)(http_client=customer)['http_client']
        abto._fallback_circuit.open()
        monkeypatch.setattr('abto.client.time.monotonic', lambda: 10**12)
        caught = None
        try:
            try:
                if asynchronous:
                    await wrapper.post('https://gateway.example/v1/chat/completions', json={})
                else:
                    wrapper.post('https://gateway.example/v1/chat/completions', json={})
            except error_type as error:
                caught = error
            assert wire_calls == ([] if failure_at == 'request_hook' else ['gateway.example'])
            assert caught is failure, 'Customer observer error was swallowed'
            failing = False
            wire_calls.clear()
            for _ in range(2):
                if asynchronous:
                    await wrapper.post('https://gateway.example/v1/chat/completions', json={})
                else:
                    wrapper.post('https://gateway.example/v1/chat/completions', json={})
            assert wire_calls == ['gateway.example', 'gateway.example']
        finally:
            if asynchronous:
                await wrapper.aclose()
                await customer.aclose()
            else:
                wrapper.close()
                customer.close()

    asyncio.run(scenario())


@pytest.mark.parametrize('module', ['httpx', 'httpx2'])
@pytest.mark.parametrize('asynchronous', [False, True], ids=['sync', 'async'])
def test_customer_retry_after_response_does_not_enable_direct_replay(module, asynchronous):
    h = pytest.importorskip(module)
    calls = []
    failure = h.ConnectError('synthetic customer retry failure')

    def handler(request):
        calls.append(request.url.host)
        if len(calls) > 1:
            raise failure
        return h.Response(200, json={})

    class Customer(h.Client):
        def send(self, request, **kwargs):
            super().send(request, **kwargs).close()
            return super().send(request, **kwargs)

    class AsyncCustomer(h.AsyncClient):
        async def send(self, request, **kwargs):
            response = await super().send(request, **kwargs)
            await response.aclose()
            return await super().send(request, **kwargs)

    async def run():
        abto = init_abto(api_key='synthetic-calling', gateway_base_url='https://gateway.example/v1',
                         provider_keys={'openai': 'synthetic-provider'},
                         fallback=OpenAIDirectFallbackOptions(base_url='https://provider.example/v1'))
        customer = (AsyncCustomer if asynchronous else Customer)(transport=wrap_httpx_transport(h.MockTransport(handler)))
        wrapper = (abto.async_openai_options if asynchronous else abto.openai_options)(http_client=customer)['http_client']
        try:
            with pytest.raises(h.ConnectError) as caught:
                if asynchronous:
                    await wrapper.post('https://gateway.example/v1/chat/completions', json={})
                else:
                    wrapper.post('https://gateway.example/v1/chat/completions', json={})
            assert caught.value is failure
            assert calls == ['gateway.example', 'gateway.example']
        finally:
            if asynchronous:
                await wrapper.aclose()
                await customer.aclose()
            else:
                wrapper.close()
                customer.close()

    asyncio.run(run())
