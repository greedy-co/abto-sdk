// @vitest-environment node

import { afterEach, describe, expect, it, vi } from 'vitest';
import { initAbto } from './client.js';
import {
  createTraceId,
  createTraceparent,
  getAbtoHeaders,
  runWithAbtoContext,
} from './context.js';

describe('server context headers', () => {
  const originalEnvironment = {
    ABTO_API_KEY: process.env.ABTO_API_KEY,
    OPENAI_API_KEY: process.env.OPENAI_API_KEY,
    ANTHROPIC_API_KEY: process.env.ANTHROPIC_API_KEY,
    GEMINI_API_KEY: process.env.GEMINI_API_KEY,
    ABTO_DEVICE_ID: process.env.ABTO_DEVICE_ID,
  };

  afterEach(() => {
    vi.unstubAllGlobals();
    for (const [key, value] of Object.entries(originalEnvironment)) {
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
  });

  it('derives W3C trace ids from UUIDv7 bytes', () => {
    const traceId = createTraceId();

    expect(traceId).toMatch(/^[0-9a-f]{32}$/);
    expect(traceId[12]).toBe('7');
  });

  it('does not expose an unsupported Gateway capture policy', () => {
    const abto = initAbto();

    expect(abto.config).not.toHaveProperty('capture');
    expect(() =>
      initAbto({ capture: { prompt: 'off' } } as unknown as Parameters<typeof initAbto>[0]),
    ).toThrow('capture is not supported by the current Gateway contract');
  });

  it('uses the configured device id when a request context has none', () => {
    const abto = initAbto({ deviceId: 'service-device' });

    expect(abto.getContext()).toEqual({ deviceId: 'service-device' });
    expect(abto.getHeaders()).toMatchObject({ 'x-abto-device-id': 'service-device' });
    expect(
      abto.withContext({ featureId: 'chat.default' }, () => abto.getHeaders()),
    ).toMatchObject({
      'x-abto-device-id': 'service-device',
      'x-abto-node-key': 'chat.default',
    });
  });

  it('falls back to ABTO_DEVICE_ID when config omits a device id', () => {
    process.env.ABTO_DEVICE_ID = 'environment-device';

    expect(initAbto().getHeaders()['x-abto-device-id']).toBe('environment-device');
  });

  it('lets the request context override the configured device id', () => {
    const abto = initAbto({ deviceId: 'service-device' });

    const headers = abto.withContext({ deviceId: 'request-device' }, () => abto.getHeaders());

    expect(headers['x-abto-device-id']).toBe('request-device');
  });

  it('keeps resolved ABTO and Provider credentials out of public config', () => {
    process.env.ABTO_API_KEY = 'abto-env';
    process.env.OPENAI_API_KEY = 'openai-env';
    process.env.ANTHROPIC_API_KEY = 'anthropic-env';
    process.env.GEMINI_API_KEY = 'gemini-env';

    const abto = initAbto();

    expect(abto.config).not.toHaveProperty('abtoApiKey');
    expect(abto.config).not.toHaveProperty('providerKeys');
    expect(abto.config).not.toHaveProperty('apiKey');
  });

  it('emits only gateway-owned identity headers from explicit context', () => {
    const headers = getAbtoHeaders({
      deviceId: 'device-1',
      featureId: 'chat.default',
      traceId: '0123456789abcdef0123456789abcdef',
    });

    expect(headers['x-abto-device-id']).toBe('device-1');
    expect(headers['x-abto-node-key']).toBe('chat.default');
    expect(headers.traceparent).toMatch(/^00-0123456789abcdef0123456789abcdef-[0-9a-f]{16}-01$/);
    expect(headers).not.toHaveProperty('x-abto-request-id');
    expect(headers).not.toHaveProperty('x-abto-variant-id');
  });

  it('can suppress traceparent for hosts that forward it separately', () => {
    const headers = getAbtoHeaders(
      { deviceId: 'device-1', featureId: 'chat.default', traceId: '0123456789abcdef0123456789abcdef' },
      { includeTraceparent: false },
    );

    expect(headers).toEqual({
      'x-abto-device-id': 'device-1',
      'x-abto-node-key': 'chat.default',
    });
  });

  it('keeps context across async boundaries and merges nested overrides', async () => {
    const abto = initAbto();

    const observed = await abto.withContext(
      { deviceId: 'device-1', featureId: 'chat.default', traceId: '0123456789abcdef0123456789abcdef' },
      async () => {
        await Promise.resolve();
        return abto.withContext({ featureId: 'chat.rewrite' }, async () => {
          await Promise.resolve();
          return {
            context: abto.getContext(),
            headers: abto.getHeaders(),
          };
        });
      },
    );

    expect(observed.context).toMatchObject({
      deviceId: 'device-1',
      featureId: 'chat.rewrite',
      traceId: '0123456789abcdef0123456789abcdef',
    });
    expect(observed.headers['x-abto-device-id']).toBe('device-1');
    expect(observed.headers['x-abto-node-key']).toBe('chat.rewrite');
    expect(observed.headers.traceparent).toMatch(/^00-0123456789abcdef0123456789abcdef-[0-9a-f]{16}-01$/);
  });

  it('keeps sibling async contexts isolated', async () => {
    const abto = initAbto();

    const [first, second] = await Promise.all([
      abto.withContext({ deviceId: 'device-1', featureId: 'chat.first' }, async () => {
        await Promise.resolve();
        return abto.getContext();
      }),
      abto.withContext({ deviceId: 'device-2', featureId: 'chat.second' }, async () => {
        await Promise.resolve();
        return abto.getContext();
      }),
    ]);

    expect(first).toMatchObject({ deviceId: 'device-1', featureId: 'chat.first' });
    expect(second).toMatchObject({ deviceId: 'device-2', featureId: 'chat.second' });
  });

  it('preserves an outer request device when an inner context only changes the feature', () => {
    const abto = initAbto({ deviceId: 'service-device' });

    const headers = abto.withContext({ deviceId: 'request-device' }, () =>
      abto.withContext({ featureId: 'chat.rewrite' }, () => abto.getHeaders()),
    );

    expect(headers).toMatchObject({
      'x-abto-device-id': 'request-device',
      'x-abto-node-key': 'chat.rewrite',
    });
  });

  it('builds W3C traceparent values without mutating the source trace id', () => {
    const traceId = 'fedcba9876543210fedcba9876543210';
    const traceparent = createTraceparent(traceId);

    expect(traceparent).toMatch(/^00-fedcba9876543210fedcba9876543210-[0-9a-f]{16}-01$/);
    expect(traceId).toBe('fedcba9876543210fedcba9876543210');
  });

  it('allows low-level context helpers for framework adapters', () => {
    const headers = runWithAbtoContext(
      { deviceId: 'device-1', featureId: 'chat.default' },
      () => getAbtoHeaders(),
    );

    expect(headers).toEqual({
      'x-abto-device-id': 'device-1',
      'x-abto-node-key': 'chat.default',
    });
  });

  it('reuses the default OpenAI client so its circuit survives across requests', async () => {
    const abto = initAbto({
      abtoApiKey: 'abto-test',
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      providerKeys: { openai: 'sk-openai' },
    });

    const first = abto.openai();
    const second = abto.openai();

    expect(second).toBe(first);
    await first;
  });

  it('shares the fallback circuit across customized OpenAI clients', async () => {
    const hosts: string[] = [];
    vi.stubGlobal('fetch', async (input: string | URL | Request, init?: RequestInit) => {
      const request = input instanceof Request ? input : new Request(input, init);
      const host = new URL(request.url).host;
      hosts.push(host);
      if (host === 'gateway.abto.app') {
        return new Response('{"error":{"message":"Gateway unavailable"}}', {
          status: 503,
          headers: { 'content-type': 'application/json' },
        });
      }
      return new Response(JSON.stringify({
        id: 'chatcmpl-test',
        object: 'chat.completion',
        created: 0,
        model: 'gpt-4o-mini',
        choices: [],
      }), {
        status: 200,
        headers: { 'content-type': 'application/json' },
      });
    });
    const abto = initAbto({
      abtoApiKey: 'abto-test',
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      providerKeys: { openai: 'sk-openai' },
      fallback: {},
    });
    const first = await abto.openai({
      clientOptions: { timeout: 1_000 },
    }) as {
      chat: {
        completions: {
          create(input: Record<string, unknown>): Promise<unknown>;
        };
      };
    };
    const second = await abto.openai({
      clientOptions: { timeout: 2_000 },
    }) as typeof first;
    const request = {
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: 'hello' }],
    };

    await first.chat.completions.create(request);
    await second.chat.completions.create(request);

    expect(hosts).toEqual([
      'gateway.abto.app',
      'api.openai.com',
      'api.openai.com',
    ]);
  });

  it('honors a per-client direct fallback opt-out', async () => {
    const urls: string[] = [];
    vi.stubGlobal('fetch', async (input: string | URL | Request, init?: RequestInit) => {
      const request = input instanceof Request ? input : new Request(input, init);
      urls.push(request.url);
      return new Response('{"error":{"message":"Gateway unavailable"}}', {
        status: 503,
        headers: {
          'content-type': 'application/json',
          'x-abto-request-id': 'req-admission',
        },
      });
    });
    const abto = initAbto({
      abtoApiKey: 'abto-test',
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      providerKeys: { openai: 'sk-openai' },
      fallback: true,
    });
    const openai = await abto.openai({
      fallback: false,
      clientOptions: { maxRetries: 0 },
    }) as {
      chat: {
        completions: {
          create(input: Record<string, unknown>): Promise<unknown>;
        };
      };
    };

    await expect(openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: 'hello' }],
    })).rejects.toThrow();

    expect(urls).toEqual(['https://gateway.abto.app/v1/chat/completions']);
  });
});
