"""Real HTTPX clients and an in-memory transport; no network or real keys."""
import asyncio
from concurrent.futures import ThreadPoolExecutor

import pytest

from abto import wrap_httpx_transport, OpenAIDirectFallbackOptions, init_abto

GATEWAY = 'https://gateway.example/v1'
DIRECT = 'https://provider.example/v1'


def make(fallback):
    return init_abto(api_key='synthetic-calling', gateway_base_url=GATEWAY,
                     provider_keys={'openai': 'synthetic-provider'},
                     fallback=OpenAIDirectFallbackOptions(base_url=DIRECT) if fallback else False)


@pytest.mark.parametrize('module', ['httpx', 'httpx2'])
@pytest.mark.parametrize('asynchronous', [False, True], ids=['sync', 'async'])
@pytest.mark.parametrize('route', ['gateway', 'gateway-fallback-enabled', 'direct'])
@pytest.mark.parametrize('mutation', ['host', 'scheme', 'port', 'userinfo', 'host-header'])
def test_customer_hook_cannot_redirect_credentials(module, asynchronous, route, mutation):
    h = pytest.importorskip(module)
    sent, hooked, hook_headers = [], [], []

    def rewrite(request):
        hooked.append(request.url.host)
        hook_headers.append(str(request.headers))
        if route == 'direct' and request.url.host == 'gateway.example':
            return
        if mutation == 'host-header':
            request.headers['host'] = 'untrusted.example'
        else:
            request.url = request.url.copy_with(**{
                'host': {'host': 'untrusted.example'},
                'scheme': {'scheme': 'http'},
                'port': {'port': 8443},
                'userinfo': {'userinfo': b'other:password'},
            }[mutation])

    def handler(request):
        sent.append(request.url.host)
        assert request.headers['authorization'] == 'Bearer synthetic-calling'
        assert request.headers['x-abto-key-openai'] == 'synthetic-provider'
        return h.Response(503, json={})

    async def run():
        async def request_hook(request):
            await asyncio.sleep(0)
            rewrite(request)
        if asynchronous:
            async with h.AsyncClient(transport=wrap_httpx_transport(h.MockTransport(handler)), event_hooks={'request': [request_hook]}) as customer:
                original_hooks = customer.event_hooks['request']
                async with make(route != 'gateway').async_openai_options(http_client=customer)['http_client'] as client:
                    with pytest.raises(ValueError, match='configured destination'):
                        await client.post(GATEWAY + '/chat/completions', json={})
                assert customer.event_hooks['request'] is original_hooks
                assert original_hooks == [request_hook] and not customer.is_closed
        else:
            with h.Client(transport=wrap_httpx_transport(h.MockTransport(handler)), event_hooks={'request': [rewrite]}) as customer:
                original_hooks = customer.event_hooks['request']
                with make(route != 'gateway').openai_options(http_client=customer)['http_client'] as client:
                    with pytest.raises(ValueError, match='configured destination'):
                        client.post(GATEWAY + '/chat/completions', json={})
                assert customer.event_hooks['request'] is original_hooks
                assert original_hooks == [rewrite] and not customer.is_closed
    asyncio.run(run())
    assert all('synthetic-calling' not in row and 'synthetic-provider' not in row for row in hook_headers)
    assert sent == (['gateway.example'] if route == 'direct' else [])
    assert hooked == (['gateway.example', 'provider.example'] if route == 'direct' else ['gateway.example'])


@pytest.mark.parametrize('module', ['httpx', 'httpx2'])
@pytest.mark.parametrize('asynchronous', [False, True], ids=['sync', 'async'])
def test_borrowed_hooks_preserve_concurrent_clients_cookies_and_lifetime(module, asynchronous):
    h = pytest.importorskip(module)
    seen, hooks, responses = [], [], []
    def request_hook(request):
        hooks.append(request.url.host)
        request.headers['traceparent'] = 'customer-parent'
        request.headers['tracestate'] = 'customer=1'
        request.headers['authorization'] = 'Bearer customer-auth'
        request.headers['x-abto-key-openai'] = 'customer-provider'
    def handler(request):
        seen.append(request)
        if request.method == 'POST':
            assert int(request.headers['content-length']) == len(request.content)
        if request.url.host == 'gateway.example':
            assert request.headers['authorization'] == 'Bearer synthetic-calling'
            assert request.headers['x-abto-key-openai'] == 'synthetic-provider'
            return h.Response(503, json={})
        if request.url.host == 'provider.example':
            assert request.headers['authorization'] == 'Bearer synthetic-provider'
            assert not any(key.startswith('x-abto-') for key in request.headers)
        else:  # A normal customer call still uses the original client/hook policy.
            assert request.headers['authorization'] == 'Bearer customer-auth'
        assert request.headers['traceparent'] == 'customer-parent'
        return h.Response(200, headers={'set-cookie': 'session=updated; Path=/'}, json={})
    async def run():
        async def ahook(request):
            await asyncio.sleep(0)
            request_hook(request)
        async def response_hook(response): responses.append(response.status_code)
        if asynchronous:
            async with h.AsyncClient(transport=wrap_httpx_transport(h.MockTransport(handler)), event_hooks={'request':[ahook], 'response':[response_hook]}) as customer:
                clients = [make(True).async_openai_options(http_client=customer)['http_client'] for _ in range(2)]
                try:
                    await asyncio.gather(*(client.post(GATEWAY+'/chat/completions',json={}) for client in clients),
                                         customer.get('https://customer.example/ordinary'))
                    assert customer.cookies.get('session', domain='provider.example') == 'updated'
                    assert customer.event_hooks['request'] == [ahook]
                    # Changes made after ABTO initialization remain visible.
                    customer.event_hooks['request'].append(response_hook_for_request)
                    await clients[0].post(GATEWAY+'/chat/completions',json={})
                finally:
                    for client in clients: await client.aclose()
                assert not customer.is_closed
        else:
            with h.Client(transport=wrap_httpx_transport(h.MockTransport(handler)), event_hooks={'request':[request_hook], 'response':[lambda r: responses.append(r.status_code)]}) as customer:
                clients = [make(True).openai_options(http_client=customer)['http_client'] for _ in range(2)]
                try:
                    with ThreadPoolExecutor(max_workers=3) as pool:
                        futures = [pool.submit(client.post,GATEWAY+'/chat/completions',json={}) for client in clients]
                        futures.append(pool.submit(customer.get,'https://customer.example/ordinary'))
                        for future in futures: future.result()
                    assert customer.cookies.get('session', domain='provider.example') == 'updated'
                    assert customer.event_hooks['request'] == [request_hook]
                    customer.event_hooks['request'].append(lambda r: r.headers.update({'tracestate':'updated=1'}))
                    clients[0].post(GATEWAY+'/chat/completions',json={})
                finally:
                    for client in clients: client.close()
                assert not customer.is_closed
    async def response_hook_for_request(request): request.headers['tracestate'] = 'updated=1'
    asyncio.run(run())
    assert len(seen) == len(hooks) == len(responses) == 6
    assert seen[-1].headers['tracestate'] == 'updated=1'


@pytest.mark.parametrize('module', ['httpx', 'httpx2'])
@pytest.mark.parametrize('asynchronous', [False, True], ids=['sync', 'async'])
def test_response_hook_failure_closes_stream_without_closing_customer(module, asynchronous):
    h = pytest.importorskip(module)
    closed = []
    class SyncStream(h.SyncByteStream):
        def __iter__(self): yield b'{}'
        def close(self): closed.append(True)
    class AsyncStream(h.AsyncByteStream):
        async def __aiter__(self): yield b'{}'
        async def aclose(self): closed.append(True)
    def fail(response): raise ValueError('customer response hook')
    async def afail(response): raise asyncio.CancelledError()
    def handler(request): return h.Response(200, stream=AsyncStream() if asynchronous else SyncStream())
    async def run():
        if asynchronous:
            async with h.AsyncClient(transport=wrap_httpx_transport(h.MockTransport(handler)), event_hooks={'response':[afail]}) as customer:
                async with make(False).async_openai_options(http_client=customer)['http_client'] as client:
                    with pytest.raises(asyncio.CancelledError): await client.post(GATEWAY+'/chat/completions',json={})
                assert not customer.is_closed
        else:
            with h.Client(transport=wrap_httpx_transport(h.MockTransport(handler)), event_hooks={'response':[fail]}) as customer:
                with make(False).openai_options(http_client=customer)['http_client'] as client:
                    with pytest.raises(ValueError, match='customer response hook'): client.post(GATEWAY+'/chat/completions',json={})
                assert not customer.is_closed
    asyncio.run(run())
    assert closed == [True]


@pytest.mark.parametrize('asynchronous', [False, True], ids=['sync', 'async'])
def test_rejected_hook_releases_half_open_probe(asynchronous, monkeypatch):
    import httpx as h
    calls = []
    def handler(request):
        calls.append(request.url.host)
        return h.Response(200, json={})
    def rewrite(request): request.url = h.URL('https://untrusted.example/')
    async def arewrite(request): rewrite(request)
    async def run():
        abto = make(True)
        client_context = h.AsyncClient if asynchronous else h.Client
        customer = client_context(transport=wrap_httpx_transport(h.MockTransport(handler)), event_hooks={'request':[arewrite if asynchronous else rewrite]})
        client = (abto.async_openai_options if asynchronous else abto.openai_options)(http_client=customer)['http_client']
        abto._fallback_circuit.open()
        monkeypatch.setattr('abto.client.time.monotonic', lambda: 10**12)
        try:
            with pytest.raises(ValueError, match='configured destination'):
                if asynchronous: await client.post(GATEWAY+'/chat/completions',json={})
                else: client.post(GATEWAY+'/chat/completions',json={})
            customer.event_hooks['request'].clear()
            if asynchronous: await client.post(GATEWAY+'/chat/completions',json={})
            else: client.post(GATEWAY+'/chat/completions',json={})
        finally:
            if asynchronous:
                await client.aclose()
                await customer.aclose()
            else:
                client.close()
                customer.close()
    asyncio.run(run())
    assert calls == ['gateway.example']


@pytest.mark.parametrize('module', ['httpx', 'httpx2'])
@pytest.mark.parametrize('asynchronous', [False, True], ids=['sync', 'async'])
@pytest.mark.parametrize('failure_at', ['send', 'request', 'response'])
@pytest.mark.parametrize('error_type', [RuntimeError, asyncio.CancelledError])
def test_customer_failure_releases_half_open_probe(module, asynchronous, failure_at, error_type, monkeypatch):
    h = pytest.importorskip(module)
    calls = []
    failure = error_type('synthetic customer observer failure')
    failing = True

    def handler(request):
        calls.append(request.url.host)
        return h.Response(200, json={})

    def fail(value):
        if failing:
            raise failure

    async def afail(value):
        fail(value)

    class SyncCustomer(h.Client):
        def send(self, request, **kwargs):
            if failure_at == 'send':
                fail(request)
            return super().send(request, **kwargs)

    class AsyncCustomer(h.AsyncClient):
        async def send(self, request, **kwargs):
            if failure_at == 'send':
                fail(request)
            return await super().send(request, **kwargs)

    async def run():
        nonlocal failing
        abto = make(True)
        customer = (AsyncCustomer if asynchronous else SyncCustomer)(
            transport=wrap_httpx_transport(h.MockTransport(handler)),
            event_hooks={} if failure_at == 'send' else {failure_at: [afail if asynchronous else fail]},
        )
        client = (abto.async_openai_options if asynchronous else abto.openai_options)(http_client=customer)['http_client']
        abto._fallback_circuit.open()
        monkeypatch.setattr('abto.client.time.monotonic', lambda: 10**12)
        try:
            with pytest.raises(error_type) as caught:
                if asynchronous:
                    await client.post(GATEWAY + '/chat/completions', json={})
                else:
                    client.post(GATEWAY + '/chat/completions', json={})
            assert caught.value is failure
            # A customer error must not replay the failed request via fallback.
            assert calls == (['gateway.example'] if failure_at == 'response' else [])
            calls.clear()
            failing = False
            for _ in range(2):
                if asynchronous:
                    await client.post(GATEWAY + '/chat/completions', json={})
                else:
                    client.post(GATEWAY + '/chat/completions', json={})
            assert calls == ['gateway.example', 'gateway.example']
        finally:
            if asynchronous:
                await client.aclose()
                assert not customer.is_closed
                await customer.aclose()
            else:
                client.close()
                assert not customer.is_closed
                customer.close()

    asyncio.run(run())


@pytest.mark.parametrize('module', ['httpx', 'httpx2'])
@pytest.mark.parametrize('asynchronous', [False, True], ids=['sync', 'async'])
def test_real_http_fallback_preserves_body_framing_and_reuses_customer_pool(module, asynchronous):
    """Unlike MockTransport, h11 enforces actual request-body framing."""
    import json
    import threading
    from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
    h = pytest.importorskip(module)
    seen = []
    class Handler(BaseHTTPRequestHandler):
        protocol_version = 'HTTP/1.1'
        def do_POST(self):
            body = self.rfile.read(int(self.headers.get('content-length', 0)))
            seen.append((self.path, body, self.client_address[1], dict(self.headers)))
            payload = b'{"ok": true}'
            self.send_response(503 if self.path.startswith('/gateway/') else 200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
        def log_message(self, *args): pass
    server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    base = 'http://127.0.0.1:' + str(server.server_port)
    async def run():
        abto = init_abto(api_key='synthetic-calling', gateway_base_url=base+'/gateway/v1',
                         provider_keys={'openai':'synthetic-provider'},
                         fallback=OpenAIDirectFallbackOptions(base_url=base+'/provider/v1'))
        body = {'messages': [{'role':'user', 'content':'본문 보존'}]}
        if asynchronous:
            async with h.AsyncClient(transport=wrap_httpx_transport(h.AsyncHTTPTransport()), timeout=2, trust_env=False) as customer:
                async with abto.async_openai_options(http_client=customer)['http_client'] as client:
                    response = await client.post(base+'/gateway/v1/chat/completions',json=body)
                    assert response.status_code == 200
                    response = await client.post(base+'/gateway/v1/chat/completions',json=body)
        else:
            with h.Client(transport=wrap_httpx_transport(h.HTTPTransport()), timeout=2, trust_env=False) as customer:
                with abto.openai_options(http_client=customer)['http_client'] as client:
                    response = client.post(base+'/gateway/v1/chat/completions',json=body)
                    assert response.status_code == 200
                    response = client.post(base+'/gateway/v1/chat/completions',json=body)
        assert response.json() == {'ok': True}
        # The unread Gateway 503 is closed before failover. Consecutive direct
        # calls then reuse the customer's keep-alive connection.
        assert len(seen) == 3 and seen[1][2] == seen[2][2]
        assert [item[0] for item in seen] == ['/gateway/v1/chat/completions'] + ['/provider/v1/chat/completions'] * 2
        assert all(json.loads(item[1]) == body for item in seen)
        assert seen[0][3]['Authorization'] == 'Bearer synthetic-calling'
        assert seen[1][3]['Authorization'] == 'Bearer synthetic-provider'
        assert not any(key.lower().startswith('x-abto-') for key in seen[1][3])
    try:
        asyncio.run(run())
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=2)
        assert not thread.is_alive()


@pytest.mark.parametrize('module', ['httpx', 'httpx2'])
@pytest.mark.parametrize('asynchronous', [False, True], ids=['sync', 'async'])
@pytest.mark.parametrize('outcome', ['success', 'provider-error', 'fallback', 'network-error'])
def test_customer_send_and_hooks_keep_payload_context_and_hide_wire_keys(module, asynchronous, outcome):
    import json
    h = pytest.importorskip(module)
    snapshots, wire, send_calls = [], [], []
    def snapshot(request):
        snapshots.append(str(request.headers) + json.dumps(request.extensions))
    def handler(request):
        wire.append((str(request.url), dict(request.headers), json.loads(request.content)))
        if outcome == 'network-error':
            raise h.ConnectError('synthetic connection error', request=request)
        status = 503 if outcome == 'fallback' and request.url.host == 'gateway.example' else 429 if outcome == 'provider-error' else 200
        return h.Response(status, json={'ok': True})
    class CustomerClient(h.Client):
        def send(self, request, **kwargs):
            send_calls.append(str(request.url))
            request.headers['x-customer-send'] = 'preserved'
            snapshot(request)
            try:
                response = super().send(request, **kwargs)
                snapshot(response.request)
                return response
            except h.RequestError as exc:
                snapshot(exc.request)
                raise
    class CustomerAsyncClient(h.AsyncClient):
        async def send(self, request, **kwargs):
            send_calls.append(str(request.url))
            request.headers['x-customer-send'] = 'preserved'
            snapshot(request)
            try:
                response = await super().send(request, **kwargs)
                snapshot(response.request)
                return response
            except h.RequestError as exc:
                snapshot(exc.request)
                raise
    async def run():
        abto = make(outcome == 'fallback')
        body = {'messages': [{'role': 'user', 'content': '고객 문맥 그대로'}], 'temperature': 0.3}
        async def ahook(request): snapshot(request)
        async def arhook(response): snapshot(response.request)
        customer = (CustomerAsyncClient if asynchronous else CustomerClient)(
            transport=wrap_httpx_transport(h.MockTransport(handler)),
            event_hooks={'request': [ahook if asynchronous else snapshot],
                         'response': [arhook if asynchronous else lambda r: snapshot(r.request)]})
        options = (abto.async_openai_options if asynchronous else abto.openai_options)(http_client=customer)
        client = options['http_client']
        try:
            with abto.with_context(feature_id='reply', device_id='customer-device'):
                try:
                    if asynchronous:
                        response = await client.post(GATEWAY+'/chat/completions', json=body,
                                                     headers={'traceparent':'customer-parent','tracestate':'customer=1'})
                    else:
                        response = client.post(GATEWAY+'/chat/completions', json=body,
                                               headers={'traceparent':'customer-parent','tracestate':'customer=1'})
                except h.ConnectError:
                    assert outcome == 'network-error'
                else:
                    assert outcome != 'network-error'
                    assert response.status_code == (429 if outcome == 'provider-error' else 200)
            assert len(send_calls) == len(wire) == (2 if outcome == 'fallback' else 1)
            for url, headers, payload in wire:
                assert payload == body
                assert headers['traceparent'] == 'customer-parent'
                assert headers['tracestate'] == 'customer=1'
                if url.startswith(GATEWAY):
                    assert headers['x-customer-send'] == 'preserved'
                    assert headers['x-abto-device-id'] == 'customer-device'
                    assert headers['authorization'] == 'Bearer synthetic-calling'
                else:
                    assert headers['authorization'] == 'Bearer synthetic-provider'
                    assert not any(k.startswith('x-abto-') for k in headers)
            assert snapshots and all('synthetic-calling' not in s and 'synthetic-provider' not in s for s in snapshots)
        finally:
            if asynchronous:
                await client.aclose()
                assert not customer.is_closed
                await customer.aclose()
            else:
                client.close()
                assert not customer.is_closed
                customer.close()
    asyncio.run(run())


@pytest.mark.parametrize('asynchronous', [False, True], ids=['sync', 'async'])
def test_unwrapped_customer_transport_has_no_abto_credentials(asynchronous):
    import httpx as h
    seen = []
    def handler(request):
        seen.append(str(request.headers) + repr(request.extensions))
        return h.Response(401, json={})
    async def run():
        abto = make(True)
        customer = (h.AsyncClient if asynchronous else h.Client)(transport=h.MockTransport(handler))
        client = (abto.async_openai_options if asynchronous else abto.openai_options)(http_client=customer)['http_client']
        try:
            with pytest.raises(ValueError, match='wrap_httpx_transport'):
                if asynchronous: await client.post(GATEWAY+'/chat/completions', json={})
                else: client.post(GATEWAY+'/chat/completions', json={})
        finally:
            if asynchronous:
                await client.aclose()
                await customer.aclose()
            else:
                client.close()
                customer.close()
    asyncio.run(run())
    assert len(seen) == 1
    assert 'synthetic-calling' not in seen[0] and 'synthetic-provider' not in seen[0]


@pytest.mark.parametrize('module', ['httpx', 'httpx2'])
@pytest.mark.parametrize('asynchronous', [False, True], ids=['sync', 'async'])
def test_wrapped_mounts_preserve_selection_and_customer_lifecycle(module, asynchronous):
    h = pytest.importorskip(module)
    routes, closed = [], []
    class SyncWire(h.BaseTransport):
        def __init__(self, route): self.route = route
        def handle_request(self, request):
            routes.append(self.route)
            return h.Response(503 if self.route == 'gateway' else 200, json={})
        def close(self): closed.append(self.route)
    class AsyncWire(h.AsyncBaseTransport):
        def __init__(self, route): self.route = route
        async def handle_async_request(self, request):
            routes.append(self.route)
            return h.Response(503 if self.route == 'gateway' else 200, json={})
        async def aclose(self): closed.append(self.route)
    async def run():
        wire = AsyncWire if asynchronous else SyncWire
        mounts = {'https://gateway.example':wrap_httpx_transport(wire('gateway')),
                  'https://provider.example':wrap_httpx_transport(wire('direct'))}
        customer = (h.AsyncClient if asynchronous else h.Client)(
            transport=wrap_httpx_transport(wire('ordinary')), mounts=mounts, trust_env=False)
        abto = make(True)
        client = (abto.async_openai_options if asynchronous else abto.openai_options)(http_client=customer)['http_client']
        try:
            if asynchronous:
                await client.post(GATEWAY+'/chat/completions', json={})
                await customer.get('https://customer.example/')
                await client.aclose()
            else:
                client.post(GATEWAY+'/chat/completions', json={})
                customer.get('https://customer.example/')
                client.close()
            assert routes == ['gateway', 'direct', 'ordinary']
            assert closed == [] and not customer.is_closed
        finally:
            if asynchronous:
                await client.aclose()
                await customer.aclose()
            else:
                client.close()
                customer.close()
        assert sorted(closed) == ['direct','gateway','ordinary']
    asyncio.run(run())


@pytest.mark.parametrize('module', ['httpx', 'httpx2'])
@pytest.mark.parametrize('asynchronous', [False, True], ids=['sync', 'async'])
def test_customer_send_can_copy_request_and_make_unrelated_calls(module, asynchronous):
    h = pytest.importorskip(module)
    seen = []
    def handler(request):
        seen.append((request.url.host, dict(request.headers), dict(request.extensions)))
        return h.Response(200, json={})
    def copy(request):
        return h.Request(request.method, request.url, headers=request.headers,
                         stream=request.stream, extensions=dict(request.extensions))
    class Customer(h.Client):
        def send(self, request, **kwargs):
            if request.url.host == 'gateway.example':
                self.get('https://customer.example/preflight')
            return super().send(copy(request), **kwargs)
    class AsyncCustomer(h.AsyncClient):
        async def send(self, request, **kwargs):
            if request.url.host == 'gateway.example':
                await self.get('https://customer.example/preflight')
            return await super().send(copy(request), **kwargs)
    async def run():
        customer = (AsyncCustomer if asynchronous else Customer)(transport=wrap_httpx_transport(h.MockTransport(handler)))
        abto = make(False)
        client = (abto.async_openai_options if asynchronous else abto.openai_options)(http_client=customer)['http_client']
        try:
            if asynchronous: await client.post(GATEWAY+'/chat/completions', json={})
            else: client.post(GATEWAY+'/chat/completions', json={})
        finally:
            if asynchronous:
                await client.aclose()
                await customer.aclose()
            else:
                client.close()
                customer.close()
    asyncio.run(run())
    assert [host for host, _, _ in seen] == ['customer.example','gateway.example']
    assert 'authorization' not in seen[0][1]
    assert 'x-abto-key-openai' not in seen[0][1]
    assert seen[1][1]['authorization'] == 'Bearer synthetic-calling'
    assert 'abto.http_dispatch' not in seen[1][2]
