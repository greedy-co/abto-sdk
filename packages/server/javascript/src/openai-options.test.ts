import OpenAI from 'openai';
import { describe, expect, it } from 'vitest';
import { initAbto } from './client.js';

const gateway = 'https://gateway.abto.app/v1';
const direct = 'https://api.openai.com/v1';
const completion = {
  id: 'chatcmpl-test', object: 'chat.completion', created: 1, model: 'gpt-4o-mini',
  choices: [{ index: 0, message: { role: 'assistant', content: 'ok' }, finish_reason: 'stop' }],
  usage: { prompt_tokens: 1, completion_tokens: 2, total_tokens: 3 },
};
const reply = () => new Response(JSON.stringify(completion), {
  headers: { 'content-type': 'application/json', 'x-abto-request-id': 'request-test' },
});
const config = {
  gatewayBaseURL: gateway, abtoApiKey: 'calling-test',
  providerKeys: { openai: 'provider-test' },
};

describe('OpenAI configuration for framework-owned clients', () => {
  it.each([undefined, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'])(
    'preserves customer trace headers alongside ABTO context with traceId=%s',
    async traceId => {
      const customer = {
        traceparent: '00-11111111111111111111111111111111-2222222222222222-00',
        tracestate: 'customer=opaque,other=value',
      };
      const abto = initAbto(config);
      const options = abto.openaiOptions({
        fetch: async (input: string | URL | Request, init?: RequestInit) => {
          const headers = new Request(input, init).headers;
          expect(headers.get('traceparent')).toBe(customer.traceparent);
          expect(headers.get('tracestate')).toBe(customer.tracestate);
          expect(headers.get('x-abto-device-id')).toBe('device-traced');
          expect(headers.get('x-abto-feature-id')).toBe('support.reply');
          expect(headers.get('authorization')).toBe('Bearer calling-test');
          return reply();
        },
      });
      const original = new Request(`${gateway}/chat/completions`, {
        method: 'POST', body: '{}', headers: { Traceparent: customer.traceparent, Tracestate: customer.tracestate },
      });
      await abto.withContext({ deviceId: 'device-traced', featureId: 'support.reply', traceId },
        () => options.fetch(original));
      expect(original.headers.get('traceparent')).toBe(customer.traceparent);
      expect(original.headers.has('x-abto-device-id')).toBe(false);
    },
  );

  it('only derives traceparent from ABTO context when the customer has none', async () => {
    const abto = initAbto(config);
    const headersSeen: Headers[] = [];
    const options = abto.openaiOptions({ fetch: async (input: string | URL | Request, init?: RequestInit) => {
      headersSeen.push(new Request(input, init).headers);
      return reply();
    } });
    await options.fetch(`${gateway}/chat/completions`, { method: 'POST', body: '{}' });
    await abto.withContext({ traceId: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' }, () =>
      options.fetch(`${gateway}/chat/completions`, {
        method: 'POST', body: '{}', headers: { tracestate: 'orphan=old-trace' },
      }));
    expect(headersSeen[0].has('traceparent')).toBe(false);
    expect(headersSeen[1].get('traceparent')).toMatch(/^00-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-[0-9a-f]{16}-01$/);
    expect(headersSeen[1].has('tracestate')).toBe(false);
  });

  it('preserves customer tracing through direct fallback and open-circuit calls', async () => {
    const seen: Request[] = [];
    const abto = initAbto({ ...config, fallback: { baseURL: direct } });
    const options = abto.openaiOptions({ fetch: async (input: string | URL | Request, init?: RequestInit) => {
      const request = new Request(input, init);
      seen.push(request);
      if (request.url.startsWith(gateway)) {
        throw new TypeError('fetch failed', { cause: Object.assign(new Error('refused'), { code: 'ECONNREFUSED' }) });
      }
      expect(request.headers.get('authorization')).toBe('Bearer provider-test');
      expect([...request.headers.keys()].some(key => key.startsWith('x-abto-'))).toBe(false);
      expect(request.headers.has('cookie')).toBe(false);
      return reply();
    } });
    for (const digit of ['1', '2']) {
      const traceparent = `00-${digit.repeat(32)}-${digit.repeat(16)}-00`;
      const tracestate = `customer=request-${digit}`;
      const before = seen.length;
      await abto.withContext({ deviceId: `device-${digit}`, featureId: 'support.reply', traceId: 'a'.repeat(32) },
        () => options.fetch(`${gateway}/chat/completions`, {
          method: 'POST', body: '{}', headers: { traceparent, tracestate, cookie: 'gateway-only' },
        }));
      for (const request of seen.slice(before)) {
        expect(request.headers.get('traceparent')).toBe(traceparent);
        expect(request.headers.get('tracestate')).toBe(tracestate);
      }
    }
    expect(seen.map(request => request.url)).toEqual([
      `${gateway}/chat/completions`, `${direct}/chat/completions`, `${direct}/chat/completions`,
    ]);
  });

  it('returns synchronous options without sending a request or mutating caller settings', () => {
    const fetch = async () => { throw new Error('Must not send during configuration'); };
    const original = Object.freeze({
      baseURL: direct, apiKey: 'old-key', fetch, maxRetries: 3, timeout: 1234,
      defaultHeaders: { 'x-product': 'example' }, organization: 'example-org',
    });
    const options = initAbto(config).openaiOptions(original);
    expect(options).not.toBeInstanceOf(Promise);
    expect(options).toMatchObject({
      baseURL: gateway, apiKey: 'abto-transport-placeholder', maxRetries: 3, timeout: 1234,
      defaultHeaders: original.defaultHeaders, organization: 'example-org',
    });
    expect(options.fetch).not.toBe(fetch);
    expect(original.baseURL).toBe(direct);
    expect(original.fetch).toBe(fetch);
    for (const secret of ['calling-test', 'provider-test', 'old-key']) {
      expect(JSON.stringify(options)).not.toContain(secret);
    }
  });

  it('validates configuration before a framework constructs its client', () => {
    expect(() => initAbto({ ...config, gatewayBaseURL: '' }).openaiOptions()).toThrow();
    expect(() => initAbto({ ...config, abtoApiKey: '' }).openaiOptions()).toThrow();
    expect(() => initAbto(config).openaiOptions({ fetch: 'invalid' })).toThrow('clientOptions.fetch');
  });

  it('resolves credentials and concurrent nested context at dispatch time', async () => {
    let key = 'first-key';
    const requests: Request[] = [];
    const abto = initAbto({ ...config, providerKeys: { openai: () => key } });
    const options = abto.openaiOptions({
      fetch: async (input: string | URL | Request, init?: RequestInit) => {
        await Promise.resolve();
        requests.push(new Request(input, init));
        return reply();
      },
    });
    const send = () => options.fetch(`${options.baseURL}/chat/completions`, {
      method: 'POST', body: '{}',
      headers: { 'x-abto-device-id': 'spoof', 'x-product': 'preserved' },
    });
    await Promise.all(['one', 'two'].map(deviceId => abto.withContext({ deviceId }, async () => {
      await Promise.resolve();
      await abto.withContext({ featureId: 'support.reply' }, send);
      expect(abto.getContext()).toEqual({ deviceId });
    })));
    key = 'rotated-key';
    await abto.withContext({ deviceId: 'three', featureId: 'support.reply' }, send);
    expect(requests.map(r => r.headers.get('x-abto-device-id'))).toEqual(['one', 'two', 'three']);
    expect(requests.map(r => r.headers.get('x-abto-key-openai'))).toEqual(['first-key', 'first-key', 'rotated-key']);
    for (const request of requests) {
      expect(request.headers.get('x-abto-feature-id')).toBe('support.reply');
      expect(request.headers.get('authorization')).toBe('Bearer calling-test');
      expect(request.headers.get('x-product')).toBe('preserved');
    }
    expect(abto.getContext()).toBeUndefined();
  });

  it('shares the fallback circuit with factory clients and newly created options', async () => {
    const urls: string[] = [];
    const transport = async (input: string | URL | Request, init?: RequestInit) => {
      const request = new Request(input, init);
      urls.push(request.url);
      if (request.url.startsWith(gateway)) {
        throw new TypeError('fetch failed', { cause: Object.assign(new Error('refused'), { code: 'ECONNREFUSED' }) });
      }
      expect(request.headers.get('authorization')).toBe('Bearer provider-test');
      expect(request.headers.has('x-abto-device-id')).toBe(false);
      return reply();
    };
    const abto = initAbto({ ...config, fallback: { baseURL: direct } });
    const body = { model: 'gpt-4o-mini', messages: [{ role: 'user' as const, content: 'hello' }] };
    const client = new OpenAI(abto.openaiOptions({ fetch: transport, maxRetries: 0 }));
    const result = await abto.withContext({ featureId: 'support.reply' }, () => client.chat.completions.create(body));
    expect(result.choices[0]?.message.content).toBe('ok');
    const factory = await abto.openai<OpenAI>({ clientOptions: { fetch: transport, maxRetries: 0 } });
    await factory.chat.completions.create(body);
    const next = new OpenAI(abto.openaiOptions({ fetch: transport, maxRetries: 0 }));
    await next.chat.completions.create(body);
    expect(urls).toEqual([`${gateway}/chat/completions`, ...Array(3).fill(`${direct}/chat/completions`)]);
  });

  it('preserves native client retries without adding transport retries', async () => {
    let calls = 0;
    const options = initAbto(config).openaiOptions({
      maxRetries: 1,
      fetch: async () => {
        calls++;
        return calls === 1 ? new Response('{"error":{"message":"retry"}}', {
          status: 500, headers: { 'content-type': 'application/json', 'retry-after-ms': '1', 'x-abto-error-source': 'provider' },
        }) : reply();
      },
    });
    const client = new OpenAI(options);
    await client.chat.completions.create({ model: 'gpt-4o-mini', messages: [] });
    expect(client.maxRetries).toBe(1);
    expect(calls).toBe(2);
  });
});
