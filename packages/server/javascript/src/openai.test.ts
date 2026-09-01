// @vitest-environment node

import { afterEach, describe, expect, it, vi } from 'vitest';
import {
  buildOpenAIClientOptions,
  createAbtoOpenAI,
  createGatewayFetch,
} from './openai.js';

function receivedRequest(
  input: string | URL | Request,
  init?: RequestInit,
): Request {
  return input instanceof Request ? input : new Request(input, init);
}

describe('ABTO OpenAI Gateway client', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it('adds candidate provider keys and request context to each Gateway call', async () => {
    let capturedHeaders: Headers | undefined;
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: {
        openai: 'sk-openai',
        anthropic: async () => 'sk-anthropic',
      },
      getContext: () => ({
        deviceId: 'device-1',
        featureId: 'chat.default',
      }),
      fetchImpl: async (input, init) => {
        const request = receivedRequest(input, init);
        capturedHeaders = new Headers(request.headers);
        expect(request.redirect).toBe('manual');
        return new Response('{}', { status: 200 });
      },
    });

    await gatewayFetch('https://gateway.abto.app/v1/chat/completions', {
      method: 'POST',
      headers: { Authorization: 'Bearer caller-override' },
    });

    expect(capturedHeaders?.get('authorization')).toBe('Bearer abto-test');
    expect(capturedHeaders?.get('x-abto-key-openai')).toBe('sk-openai');
    expect(capturedHeaders?.get('x-abto-key-anthropic')).toBe('sk-anthropic');
    expect(capturedHeaders?.get('x-abto-device-id')).toBe('device-1');
    expect(capturedHeaders?.get('x-abto-feature-id')).toBe('chat.default');
  });

  it('resolves Provider credentials again for every request', async () => {
    let currentKey = 'sk-first';
    const capturedKeys: string[] = [];
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: { openai: () => currentKey },
      fallback: false,
      fetchImpl: async (input, init) => {
        capturedKeys.push(
          receivedRequest(input, init).headers.get('x-abto-key-openai') ?? '',
        );
        return new Response('{}', { status: 200 });
      },
    });

    await gatewayFetch('https://gateway.abto.app/v1/chat/completions');
    currentKey = 'sk-rotated';
    await gatewayFetch('https://gateway.abto.app/v1/chat/completions');

    expect(capturedKeys).toEqual(['sk-first', 'sk-rotated']);
  });

  it('rejects invalid ABTO credentials before issuing a request', async () => {
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-safe\nX-Leaked: value',
      fetchImpl: async () => new Response('{}'),
    });

    await expect(
      gatewayFetch('https://gateway.abto.app/v1/chat/completions'),
    ).rejects.toThrow('ABTO API key contains invalid characters.');
  });

  it('rejects a blank ABTO credential before issuing a request', async () => {
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: '   ',
      fetchImpl: async () => new Response('{}'),
    });

    await expect(
      gatewayFetch('https://gateway.abto.app/v1/chat/completions'),
    ).rejects.toThrow('ABTO API key is required.');
  });

  it('keeps Gateway security options authoritative over caller client options', () => {
    const protectedFetch = async () => new Response('{}');
    const options = buildOpenAIClientOptions({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      fetch: protectedFetch,
      clientOptions: {
        baseURL: 'https://example.com/steal',
        apiKey: 'wrong-key',
        fetch: async () => new Response('stolen'),
        maxRetries: 9,
        timeout: 12_345,
      },
    });

    expect(options.baseURL).toBe('https://gateway.abto.app/v1');
    expect(options.apiKey).toBe('abto-test');
    expect(options.fetch).toBe(protectedFetch);
    expect(options.maxRetries).toBe(9);
    expect(options.timeout).toBe(12_345);
  });

  it('leaves the official OpenAI retry default unset when the caller does not configure it', () => {
    const options = buildOpenAIClientOptions({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      fetch: async () => new Response('{}'),
    });

    expect(options).not.toHaveProperty('maxRetries');
  });

  it('rejects absolute requests outside the configured Gateway origin before resolving keys', async () => {
    let providerKeyResolved = false;
    let requestIssued = false;
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: {
        openai: () => {
          providerKeyResolved = true;
          return 'sk-openai';
        },
      },
      fetchImpl: async () => {
        requestIssued = true;
        return new Response('{}');
      },
    });

    await expect(gatewayFetch('https://attacker.example/steal')).rejects.toThrow(
      'outside the configured Gateway origin',
    );
    expect(providerKeyResolved).toBe(false);
    expect(requestIssued).toBe(false);
  });

  it('preserves ordinary Request headers but replaces reserved credential headers', async () => {
    let capturedHeaders: Headers | undefined;
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: { openai: 'sk-trusted' },
      getContext: () => ({ deviceId: 'trusted-device' }),
      fetchImpl: async (input, init) => {
        capturedHeaders = new Headers(receivedRequest(input, init).headers);
        return new Response('{}');
      },
    });
    const request = new Request('https://gateway.abto.app/v1/chat/completions', {
      headers: {
        'x-client-header': 'preserved',
        Authorization: 'Bearer attacker',
        'x-abto-key-openai': 'sk-attacker',
        'x-abto-device-id': 'attacker-device',
      },
    });

    await gatewayFetch(request);

    expect(capturedHeaders?.get('x-client-header')).toBe('preserved');
    expect(capturedHeaders?.get('authorization')).toBe('Bearer abto-test');
    expect(capturedHeaders?.get('x-abto-key-openai')).toBe('sk-trusted');
    expect(capturedHeaders?.get('x-abto-device-id')).toBe('trusted-device');
  });

  it('falls back directly on a connection failure and preserves the OpenAI request', async () => {
    const requests: Request[] = [];
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: {
        openai: 'sk-openai',
        anthropic: 'sk-anthropic',
      },
      fallback: {},
      fetchImpl: async (input, init) => {
        const request = receivedRequest(input, init);
        requests.push(request);
        if (new URL(request.url).hostname === 'gateway.abto.app') {
          const cause = Object.assign(new Error('lookup failed'), { code: 'ENOTFOUND' });
          throw new TypeError('fetch failed', { cause });
        }
        return new Response(
          '{"id":"chatcmpl-direct","choices":[]}',
          { status: 200, headers: { 'content-type': 'application/json' } },
        );
      },
    });
    const body = JSON.stringify({
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: 'hello' }],
      temperature: 0.25,
    });

    const response = await gatewayFetch(
      'https://gateway.abto.app/v1/chat/completions',
      {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'x-client-header': 'preserved',
          cookie: 'gateway-session=secret',
          'proxy-authorization': 'Bearer proxy-secret',
          'x-api-key': 'gateway-secret',
          'openai-project': 'project-safe',
          'idempotency-key': 'request-safe',
        },
        body,
      },
    );

    expect(response.status).toBe(200);
    expect(requests.map((request) => request.url)).toEqual([
      'https://gateway.abto.app/v1/chat/completions',
      'https://api.openai.com/v1/chat/completions',
    ]);
    expect(await requests[1]?.text()).toBe(body);
    expect(requests[1]?.headers.get('authorization')).toBe('Bearer sk-openai');
    expect(requests[1]?.headers.has('x-client-header')).toBe(false);
    expect(requests[1]?.headers.has('cookie')).toBe(false);
    expect(requests[1]?.headers.has('proxy-authorization')).toBe(false);
    expect(requests[1]?.headers.has('x-api-key')).toBe(false);
    expect(requests[1]?.headers.get('openai-project')).toBe('project-safe');
    expect(requests[1]?.headers.get('idempotency-key')).toBe('request-safe');
    expect(requests[1]?.headers.has('x-abto-key-anthropic')).toBe(false);
    expect(requests[1]?.headers.has('x-abto-feature-id')).toBe(false);
  });

  it('preserves caller transport options on Gateway and direct requests', async () => {
    const dispatcher = {};
    const observedDispatchers: unknown[] = [];
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: { openai: 'sk-openai' },
      fallback: {},
      fetchImpl: async (input, init) => {
        observedDispatchers.push(init?.dispatcher);
        const request = receivedRequest(input, init);
        if (new URL(request.url).hostname === 'gateway.abto.app') {
          const cause = Object.assign(new Error('refused'), { code: 'ECONNREFUSED' });
          throw new TypeError('fetch failed', { cause });
        }
        return new Response('{}', { status: 200 });
      },
    });

    await gatewayFetch('https://gateway.abto.app/v1/chat/completions', {
      method: 'POST',
      body: '{}',
      dispatcher,
    } as RequestInit & { dispatcher: object });

    expect(observedDispatchers).toEqual([dispatcher, dispatcher]);
  });

  it('falls back for Undici connection timeouts before the request is sent', async () => {
    const urls: string[] = [];
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: { openai: 'sk-openai' },
      fallback: {},
      fetchImpl: async (input, init) => {
        const request = receivedRequest(input, init);
        urls.push(request.url);
        if (new URL(request.url).hostname === 'gateway.abto.app') {
          const cause = Object.assign(new Error('connect timed out'), {
            code: 'UND_ERR_CONNECT_TIMEOUT',
          });
          throw new TypeError('fetch failed', { cause });
        }
        return new Response('{}', { status: 200 });
      },
    });

    const response = await gatewayFetch(
      'https://gateway.abto.app/v1/chat/completions',
      { method: 'POST', body: '{}' },
    );

    expect(response.status).toBe(200);
    expect(urls).toEqual([
      'https://gateway.abto.app/v1/chat/completions',
      'https://api.openai.com/v1/chat/completions',
    ]);
  });

  it.each([
    'ERR_SSL_WRONG_VERSION_NUMBER',
    'ERR_SSL_SSLV3_ALERT_HANDSHAKE_FAILURE',
    'CERT_REVOKED',
    'UNABLE_TO_GET_ISSUER_CERT_LOCALLY',
  ])('falls back for the pre-request TLS failure %s', async (code) => {
    let directCalls = 0;
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: { openai: 'sk-openai' },
      fallback: {},
      fetchImpl: async (input, init) => {
        const request = receivedRequest(input, init);
        if (new URL(request.url).hostname === 'gateway.abto.app') {
          const cause = Object.assign(new Error('TLS handshake failed'), { code });
          throw new TypeError('fetch failed', { cause });
        }
        directCalls += 1;
        return new Response('{}', { status: 200 });
      },
    });

    const response = await gatewayFetch(
      'https://gateway.abto.app/v1/chat/completions',
      { method: 'POST', body: '{}' },
    );

    expect(response.status).toBe(200);
    expect(directCalls).toBe(1);
  });

  it('falls back on an admission 503 but not on provider or transport failures', async () => {
    const scenarios = [
      {
        headers: { 'x-abto-request-id': 'req-admission' },
        expectedCalls: 2,
      },
      {
        headers: {
          'x-abto-request-id': 'req-provider',
          'x-abto-error-source': 'provider',
        },
        expectedCalls: 1,
      },
      {
        headers: {
          'x-abto-request-id': 'req-transport',
          'x-abto-error-source': 'transport',
        },
        expectedCalls: 1,
      },
    ];

    for (const scenario of scenarios) {
      const urls: string[] = [];
      const gatewayFetch = createGatewayFetch({
        gatewayBaseURL: 'https://gateway.abto.app/v1',
        abtoApiKey: 'abto-test',
        providerKeys: { openai: 'sk-openai' },
        fallback: {},
        fetchImpl: async (input, init) => {
          const request = receivedRequest(input, init);
          urls.push(request.url);
          if (new URL(request.url).hostname === 'gateway.abto.app') {
            return new Response('{}', {
              status: 503,
              headers: scenario.headers,
            });
          }
          return new Response('{}', { status: 200 });
        },
      });

      await gatewayFetch('https://gateway.abto.app/v1/chat/completions', {
        method: 'POST',
        body: '{}',
      });

      expect(urls).toHaveLength(scenario.expectedCalls);
    }
  });

  it('does not open the direct circuit on an ambiguous timeout by default', async () => {
    const urls: string[] = [];
    let gatewayCalls = 0;
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: { openai: 'sk-openai' },
      fallback: {},
      fetchImpl: async (input, init) => {
        const request = receivedRequest(input, init);
        urls.push(request.url);
        if (new URL(request.url).hostname === 'gateway.abto.app') {
          gatewayCalls += 1;
          if (gatewayCalls === 1) {
            throw new DOMException('Gateway request timed out.', 'TimeoutError');
          }
        }
        return new Response('{}', { status: 200 });
      },
    });

    let timeoutError: unknown;
    try {
      await gatewayFetch('https://gateway.abto.app/v1/chat/completions', {
        method: 'POST',
        body: '{}',
      });
    } catch (error) {
      timeoutError = error;
    }
    expect(timeoutError).toBeInstanceOf(DOMException);
    expect((timeoutError as DOMException).name).toBe('TimeoutError');

    const second = await gatewayFetch(
      'https://gateway.abto.app/v1/chat/completions',
      { method: 'POST', body: '{}' },
    );

    expect(second.status).toBe(200);
    expect(gatewayCalls).toBe(2);
    expect(urls).toEqual([
      'https://gateway.abto.app/v1/chat/completions',
      'https://gateway.abto.app/v1/chat/completions',
    ]);
  });

  it('does not open the circuit for a caller timeout', async () => {
    const controller = new AbortController();
    controller.abort(new DOMException('Caller deadline exceeded.', 'TimeoutError'));
    let gatewayCalls = 0;
    let directCalls = 0;
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: { openai: 'sk-openai' },
      fallback: {},
      fetchImpl: async (input, init) => {
        const request = receivedRequest(input, init);
        if (new URL(request.url).hostname === 'gateway.abto.app') {
          gatewayCalls += 1;
          if (init?.signal?.aborted) throw init.signal.reason;
          return new Response('{}', { status: 200 });
        }
        directCalls += 1;
        return new Response('{}', { status: 200 });
      },
    });

    await expect(
      gatewayFetch('https://gateway.abto.app/v1/chat/completions', {
        method: 'POST',
        body: '{}',
        signal: controller.signal,
      }),
    ).rejects.toMatchObject({ name: 'TimeoutError' });
    const response = await gatewayFetch(
      'https://gateway.abto.app/v1/chat/completions',
      { method: 'POST', body: '{}' },
    );

    expect(response.status).toBe(200);
    expect(gatewayCalls).toBe(2);
    expect(directCalls).toBe(0);
  });

  it('keeps caller aborts connected after Gateway response headers', async () => {
    const controller = new AbortController();
    let gatewaySignal: AbortSignal | null | undefined;
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: { openai: 'sk-openai' },
      fallback: {},
      fetchImpl: async (_input, init) => {
        gatewaySignal = init?.signal;
        return new Response(new ReadableStream({
          start() {
            // Simulate an SSE body that remains open after the response headers.
          },
        }));
      },
    });

    const response = await gatewayFetch(
      'https://gateway.abto.app/v1/chat/completions',
      { method: 'POST', body: '{}', signal: controller.signal },
    );
    controller.abort(new DOMException('Caller cancelled.', 'AbortError'));

    expect(gatewaySignal?.aborted).toBe(true);
    await response.body?.cancel();
  });

  it('releases a half-open probe when its caller aborts', async () => {
    let now = 0;
    vi.spyOn(performance, 'now').mockImplementation(() => now);
    let gatewayCalls = 0;
    let directCalls = 0;
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: { openai: 'sk-openai' },
      fallback: {},
      fetchImpl: async (input, init) => {
        const request = receivedRequest(input, init);
        if (new URL(request.url).hostname === 'gateway.abto.app') {
          gatewayCalls += 1;
          if (gatewayCalls === 1) {
            const cause = Object.assign(new Error('socket closed'), {
              code: 'ECONNRESET',
            });
            throw new TypeError('fetch failed', { cause });
          }
          if (init?.signal?.aborted) throw init.signal.reason;
          return new Response('{}', { status: 200 });
        }
        directCalls += 1;
        return new Response('{}', { status: 200 });
      },
    });

    await expect(
      gatewayFetch('https://gateway.abto.app/v1/chat/completions', {
        method: 'POST',
        body: '{}',
      }),
    ).rejects.toThrow('fetch failed');
    now = 31_000;
    const controller = new AbortController();
    controller.abort(new DOMException('Caller cancelled.', 'AbortError'));
    await expect(
      gatewayFetch('https://gateway.abto.app/v1/chat/completions', {
        method: 'POST',
        body: '{}',
        signal: controller.signal,
      }),
    ).rejects.toMatchObject({ name: 'AbortError' });
    const response = await gatewayFetch(
      'https://gateway.abto.app/v1/chat/completions',
      { method: 'POST', body: '{}' },
    );

    expect(response.status).toBe(200);
    expect(gatewayCalls).toBe(3);
    expect(directCalls).toBe(0);
  });

  it('closes a stale circuit after a keyless Gateway recovery', async () => {
    let currentKey: string | undefined = 'sk-openai';
    let gatewayCalls = 0;
    let directCalls = 0;
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: { openai: () => currentKey },
      fallback: {},
      fetchImpl: async (input, init) => {
        const request = receivedRequest(input, init);
        if (new URL(request.url).hostname === 'gateway.abto.app') {
          gatewayCalls += 1;
          if (gatewayCalls === 1) {
            const cause = Object.assign(new Error('refused'), {
              code: 'ECONNREFUSED',
            });
            throw new TypeError('fetch failed', { cause });
          }
          return new Response('{}', { status: 200 });
        }
        directCalls += 1;
        return new Response('{}', { status: 200 });
      },
    });

    await (
      await gatewayFetch('https://gateway.abto.app/v1/chat/completions', {
        method: 'POST',
        body: '{}',
      })
    ).text();
    currentKey = undefined;
    await (
      await gatewayFetch('https://gateway.abto.app/v1/chat/completions', {
        method: 'POST',
        body: '{}',
      })
    ).text();
    currentKey = 'sk-openai';
    await (
      await gatewayFetch('https://gateway.abto.app/v1/chat/completions', {
        method: 'POST',
        body: '{}',
      })
    ).text();

    expect(gatewayCalls).toBe(3);
    expect(directCalls).toBe(1);
  });

  it('does not open the direct circuit after an ambiguous disconnect', async () => {
    let gatewayCalls = 0;
    let directCalls = 0;
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: { openai: 'sk-openai' },
      fallback: {},
      fetchImpl: async (input, init) => {
        const request = receivedRequest(input, init);
        if (new URL(request.url).hostname === 'gateway.abto.app') {
          gatewayCalls += 1;
          if (gatewayCalls === 1) {
            const cause = Object.assign(new Error('socket closed'), {
              code: 'ECONNRESET',
            });
            throw new TypeError('fetch failed', { cause });
          }
          return new Response('{}', { status: 200 });
        }
        directCalls += 1;
        return new Response('{}', { status: 200 });
      },
    });

    await expect(
      gatewayFetch('https://gateway.abto.app/v1/chat/completions', {
        method: 'POST',
        body: '{}',
      }),
    ).rejects.toThrow('fetch failed');
    const response = await gatewayFetch(
      'https://gateway.abto.app/v1/chat/completions',
      { method: 'POST', body: '{}' },
    );

    expect(response.status).toBe(200);
    expect(gatewayCalls).toBe(2);
    expect(directCalls).toBe(0);
  });

  it('does not open the direct circuit when the Gateway body disconnects after headers', async () => {
    let gatewayCalls = 0;
    let directCalls = 0;
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: { openai: 'sk-openai' },
      fallback: {},
      fetchImpl: async (input, init) => {
        const request = receivedRequest(input, init);
        if (new URL(request.url).hostname === 'gateway.abto.app') {
          gatewayCalls += 1;
          if (gatewayCalls > 1) {
            return new Response('{}', { status: 200 });
          }
          return new Response(new ReadableStream({
            pull(controller) {
              controller.error(new TypeError('Gateway body disconnected.'));
            },
          }));
        }
        directCalls += 1;
        return new Response('{}', { status: 200 });
      },
    });

    const interrupted = await gatewayFetch(
      'https://gateway.abto.app/v1/chat/completions',
      { method: 'POST', body: '{}' },
    );
    await expect(interrupted.text()).rejects.toThrow('Gateway body disconnected.');
    const recovered = await gatewayFetch(
      'https://gateway.abto.app/v1/chat/completions',
      { method: 'POST', body: '{}' },
    );

    expect(recovered.status).toBe(200);
    expect(gatewayCalls).toBe(2);
    expect(directCalls).toBe(0);
  });

  it('can opt into direct fallback for the timed-out current request', async () => {
    const urls: string[] = [];
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: { openai: 'sk-openai' },
      fallback: { onTimeout: true },
      fetchImpl: async (input, init) => {
        const request = receivedRequest(input, init);
        urls.push(request.url);
        if (new URL(request.url).hostname === 'gateway.abto.app') {
          throw new DOMException('Gateway request timed out.', 'TimeoutError');
        }
        return new Response('{}', { status: 200 });
      },
    });

    const response = await gatewayFetch(
      'https://gateway.abto.app/v1/chat/completions',
      { method: 'POST', body: '{}' },
    );

    expect(response.status).toBe(200);
    expect(urls).toEqual([
      'https://gateway.abto.app/v1/chat/completions',
      'https://api.openai.com/v1/chat/completions',
    ]);
  });

  it('returns a direct OpenAI error without retrying or reclassifying it', async () => {
    let gatewayCalls = 0;
    let directCalls = 0;
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: { openai: 'sk-openai' },
      fallback: {},
      fetchImpl: async (input, init) => {
        const request = receivedRequest(input, init);
        if (new URL(request.url).hostname === 'gateway.abto.app') {
          gatewayCalls += 1;
          const cause = Object.assign(new Error('refused'), { code: 'ECONNREFUSED' });
          throw new TypeError('fetch failed', { cause });
        }
        directCalls += 1;
        return new Response('{}', { status: 500 });
      },
    });

    const response = await gatewayFetch(
      'https://gateway.abto.app/v1/chat/completions',
      { method: 'POST', body: '{}' },
    );

    expect(response.status).toBe(500);
    expect(gatewayCalls).toBe(1);
    expect(directCalls).toBe(1);
  });

  it('does not enable direct fallback without an OpenAI key source', async () => {
    const urls: string[] = [];
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: { anthropic: 'sk-anthropic' },
      fetchImpl: async (input, init) => {
        const request = receivedRequest(input, init);
        urls.push(request.url);
        return new Response('{}', { status: 503 });
      },
    });

    const response = await gatewayFetch(
      'https://gateway.abto.app/v1/chat/completions',
      { method: 'POST', body: '{}' },
    );

    expect(response.status).toBe(503);
    expect(urls).toEqual(['https://gateway.abto.app/v1/chat/completions']);
  });

  it('does not buffer a streaming body when direct fallback is disabled', async () => {
    const body = new ReadableStream({
      start(controller) {
        controller.enqueue(new TextEncoder().encode('streamed'));
        controller.close();
      },
    });
    let observedBody: BodyInit | null | undefined;
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: { openai: 'sk-openai' },
      fallback: false,
      fetchImpl: async (_input, init) => {
        observedBody = init?.body;
        return new Response('{}', { status: 200 });
      },
    });

    await gatewayFetch('https://gateway.abto.app/v1/chat/completions', {
      method: 'POST',
      body,
      duplex: 'half',
    } as RequestInit & { duplex: 'half' });

    expect(observedBody).toBeInstanceOf(ReadableStream);
  });

  it('validates direct fallback timeout settings', () => {
    expect(() =>
      createGatewayFetch({
        gatewayBaseURL: 'https://gateway.abto.app/v1',
        abtoApiKey: 'abto-test',
        fallback: { timeoutMs: 0 },
      }),
    ).toThrow('fallback.timeoutMs');
  });

  it('uses a caller OpenAI fetch underneath the ABTO routing wrapper', async () => {
    const requests: Request[] = [];
    const callerFetch = vi.fn(async (input: string | URL | Request, init?: RequestInit) => {
      requests.push(receivedRequest(input, init));
      return new Response(JSON.stringify({
        id: 'chatcmpl-gateway',
        object: 'chat.completion',
        created: 1,
        model: 'gpt-4o-mini',
        choices: [{
          index: 0,
          message: { role: 'assistant', content: 'ok' },
          finish_reason: 'stop',
        }],
        usage: {
          prompt_tokens: 1,
          completion_tokens: 1,
          total_tokens: 2,
        },
      }), {
        status: 200,
        headers: { 'content-type': 'application/json' },
      });
    });
    const client = await createAbtoOpenAI({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: { openai: 'sk-openai' },
      clientOptions: {
        fetch: callerFetch,
        maxRetries: 0,
      },
    }) as {
      chat: {
        completions: {
          create(input: Record<string, unknown>): Promise<{ id: string }>;
        };
      };
    };

    const completion = await client.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: 'hello' }],
    });

    expect(completion.id).toBe('chatcmpl-gateway');
    expect(callerFetch).toHaveBeenCalledTimes(1);
    expect(requests[0]?.url).toBe('https://gateway.abto.app/v1/chat/completions');
    expect(requests[0]?.headers.get('authorization')).toBe('Bearer abto-test');
    expect(requests[0]?.headers.get('x-abto-key-openai')).toBe('sk-openai');
  });

  it('rejects a non-function OpenAI fetch option before creating a client', async () => {
    await expect(createAbtoOpenAI({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      clientOptions: { fetch: 'not-a-function' },
    })).rejects.toThrow('clientOptions.fetch must be a function');
  });

  it('preserves the OpenAI SDK retry setting across direct fallback', async () => {
    const urls: string[] = [];
    let directCalls = 0;
    vi.stubGlobal('fetch', async (input: string | URL | Request, init?: RequestInit) => {
      const request = receivedRequest(input, init);
      urls.push(request.url);
      if (new URL(request.url).hostname === 'gateway.abto.app') {
        const cause = Object.assign(new Error('refused'), { code: 'ECONNREFUSED' });
        throw new TypeError('fetch failed', { cause });
      }
      directCalls += 1;
      expect(request.headers.get('authorization')).toBe('Bearer sk-openai');
      if (directCalls === 1) {
        return new Response(JSON.stringify({
          error: { message: 'temporary', type: 'server_error' },
        }), {
          status: 500,
          headers: {
            'content-type': 'application/json',
            'retry-after-ms': '1',
          },
        });
      }
      return new Response(JSON.stringify({
        id: 'chatcmpl-direct',
        object: 'chat.completion',
        created: 1,
        model: 'gpt-4o-mini',
        choices: [{
          index: 0,
          message: { role: 'assistant', content: 'fallback ok' },
          finish_reason: 'stop',
        }],
        usage: {
          prompt_tokens: 1,
          completion_tokens: 2,
          total_tokens: 3,
        },
      }), {
        status: 200,
        headers: { 'content-type': 'application/json' },
      });
    });
    const client = await createAbtoOpenAI({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: { openai: 'sk-openai' },
      fallback: {},
      clientOptions: { maxRetries: 1 },
    }) as {
      maxRetries: number;
      chat: {
        completions: {
          create(input: Record<string, unknown>): Promise<{
            id: string;
            choices: Array<{ message: { content: string | null } }>;
          }>;
        };
      };
    };

    const completion = await client.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: 'hello' }],
    });

    expect(client.maxRetries).toBe(1);
    expect(completion.id).toBe('chatcmpl-direct');
    expect(completion.choices[0]?.message.content).toBe('fallback ok');
    expect(urls).toEqual([
      'https://gateway.abto.app/v1/chat/completions',
      'https://api.openai.com/v1/chat/completions',
      'https://api.openai.com/v1/chat/completions',
    ]);
  });

  it('requires gatewayBaseURL instead of accepting the legacy baseURL alias', async () => {
    await expect(
      createAbtoOpenAI({
        baseURL: 'https://gateway.abto.app/v1',
        abtoApiKey: 'abto-test',
      } as unknown as Parameters<typeof createAbtoOpenAI>[0]),
    ).rejects.toThrow('requires gatewayBaseURL.');
  });
});
