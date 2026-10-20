// @vitest-environment node

import { covers } from './conformance.js';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { initAbto } from './client.js';
import {
  createTraceId,
  createTraceparent,
  getAbtoHeaders,
  runWithAbtoContext,
} from './context.js';
import { HEADER_DEVICE_ID, HEADER_FEATURE_ID, HEADER_NODE_ID, HEADER_REQUEST_ID, HEADER_TRACE_ID } from './policy.generated.js';

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
    expect(abto.getHeaders()).toMatchObject({ [HEADER_DEVICE_ID]: 'service-device' });
    expect(
      abto.withContext({ featureId: 'chat.default' }, () => abto.getHeaders()),
    ).toMatchObject({
      [HEADER_DEVICE_ID]: 'service-device',
      [HEADER_FEATURE_ID]: 'chat.default',
    });
  });

  it('falls back to ABTO_DEVICE_ID when config omits a device id', () => {
    process.env.ABTO_DEVICE_ID = 'environment-device';

    expect(initAbto().getHeaders()[HEADER_DEVICE_ID]).toBe('environment-device');
  });

  it('lets the request context override the configured device id', () => {
    const abto = initAbto({ deviceId: 'service-device' });

    const headers = abto.withContext({ deviceId: 'request-device' }, () => abto.getHeaders());

    expect(headers[HEADER_DEVICE_ID]).toBe('request-device');
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
    covers('context.emits_only_configured_identifiers');
    const headers = getAbtoHeaders({
      deviceId: 'device-1',
      featureId: 'chat.default',
      nodeId: 'chat.draft',
      traceId: '0123456789abcdef0123456789abcdef',
    });

    expect(headers[HEADER_DEVICE_ID]).toBe('device-1');
    expect(headers[HEADER_FEATURE_ID]).toBe('chat.default');
    expect(headers[HEADER_NODE_ID]).toBe('chat.draft');
    expect(headers[HEADER_TRACE_ID]).toBe('0123456789abcdef0123456789abcdef');
    expect(headers).not.toHaveProperty('traceparent');
    expect(headers).not.toHaveProperty(HEADER_REQUEST_ID);
    expect(headers).not.toHaveProperty('x-abto-variant-id');
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
    expect(observed.headers[HEADER_DEVICE_ID]).toBe('device-1');
    expect(observed.headers[HEADER_FEATURE_ID]).toBe('chat.rewrite');
    expect(observed.headers[HEADER_TRACE_ID]).toBe('0123456789abcdef0123456789abcdef');
  });

  it('keeps sibling async contexts isolated', async () => {
    covers('context.propagates_and_isolates');
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
      [HEADER_DEVICE_ID]: 'request-device',
      [HEADER_FEATURE_ID]: 'chat.rewrite',
    });
  });

  it('drops the outer node when an inner context switches to another feature', () => {
    const abto = initAbto();

    const headers = abto.withContext({ featureId: 'chat.default', nodeId: 'chat.draft' }, () => ({
      sameFeature: abto.withContext({ featureId: 'chat.default', deviceId: 'device-1' }, () => abto.getHeaders()),
      nodeOnly: abto.withContext({ nodeId: 'chat.review' }, () => abto.getHeaders()),
      otherFeature: abto.withContext({ featureId: 'chat.rewrite' }, () => abto.getHeaders()),
      otherFeatureWithNode: abto.withContext({ featureId: 'chat.rewrite', nodeId: 'chat.polish' }, () => abto.getHeaders()),
    }));

    expect(headers.sameFeature[HEADER_NODE_ID]).toBe('chat.draft');
    expect(headers.nodeOnly).toMatchObject({ [HEADER_FEATURE_ID]: 'chat.default', [HEADER_NODE_ID]: 'chat.review' });
    expect(headers.otherFeature[HEADER_FEATURE_ID]).toBe('chat.rewrite');
    expect(headers.otherFeature).not.toHaveProperty(HEADER_NODE_ID);
    expect(headers.otherFeatureWithNode[HEADER_NODE_ID]).toBe('chat.polish');
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
      [HEADER_DEVICE_ID]: 'device-1',
      [HEADER_FEATURE_ID]: 'chat.default',
      [HEADER_TRACE_ID]: expect.stringMatching(/^[0-9a-f]{32}$/),
    });
  });

  it('opens one trace in the outermost scope and shares it with nested scopes', () => {
    covers('context.opens_trace_when_absent');
    const abto = initAbto();

    const run = abto.withContext({ featureId: 'agent.plan' }, () => ({
      outer: abto.getHeaders()[HEADER_TRACE_ID],
      inner: abto.withContext({ nodeId: 'agent.write' }, () => abto.getHeaders()[HEADER_TRACE_ID]),
    }));
    const next = abto.withContext({ featureId: 'agent.plan' }, () => abto.getHeaders()[HEADER_TRACE_ID]);

    expect(run.outer).toMatch(/^[0-9a-f]{32}$/);
    expect(run.inner).toBe(run.outer);
    expect(abto.withContext({ featureId: 'agent.plan' }, () =>
      abto.withContext({ traceId: undefined }, () => abto.getHeaders()[HEADER_TRACE_ID])
        === abto.getHeaders()[HEADER_TRACE_ID])).toBe(true);
    expect(next).not.toBe(run.outer);
    expect(getAbtoHeaders({ featureId: 'agent.plan' })[HEADER_TRACE_ID]).toMatch(/^[0-9a-f]{32}$/);
    expect(getAbtoHeaders()[HEADER_TRACE_ID]).not.toBe(getAbtoHeaders()[HEADER_TRACE_ID]);
  });

  it('keeps the scope trace when a node switches through an explicit context', () => {
    covers('context.node_change_keeps_trace');
    const abto = initAbto();

    const run = abto.withContext({ featureId: 'agent.plan' }, () => ({
      scope: getAbtoHeaders()[HEADER_TRACE_ID],
      explicit: getAbtoHeaders({ featureId: 'agent.plan', nodeId: 'agent.write' })[HEADER_TRACE_ID],
      client: abto.getHeaders({ featureId: 'agent.plan', nodeId: 'agent.write' })[HEADER_TRACE_ID],
    }));

    expect(run.explicit).toBe(run.scope);
    expect(run.client).toBe(run.scope);
  });

  it('keeps a trace id the caller continues', () => {
    const abto = initAbto();

    const headers = abto.withContext({ traceId: 'run-from-upstream' }, () => abto.getHeaders());

    expect(headers[HEADER_TRACE_ID]).toBe('run-from-upstream');
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
    covers('circuit.shared_across_clients');
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
      fallback: { baseURL: 'https://api.openai.com/v1' },
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
          [HEADER_REQUEST_ID]: 'req-admission',
        },
      });
    });
    const abto = initAbto({
      abtoApiKey: 'abto-test',
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      providerKeys: { openai: 'sk-openai' },
      fallback: { baseURL: 'https://api.openai.com/v1' },
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
