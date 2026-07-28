import { afterEach, describe, expect, it, vi } from 'vitest';
import { Transport } from './transport.js';
import type { CapturedEvent, ResolvedConfig } from './types.js';

const config: ResolvedConfig = {
  endpoint: 'https://collector.test/v1/collect/events',
  apiKey: 'public_project_key',
  projectKey: 'public_project_key',
  apiHost: 'https://collector.test',
  environment: 'production',
  appVersion: 'test',
  events: {},
  debug: false,
  capturePrompt: 'metadata_only',
  captureResponse: 'metadata_only',
  mask: 'all',
  hashSalt: 'test-salt',
  autocapture: false,
  batchSize: 20,
  flushIntervalMs: 5000,
  sessionIdleMs: 30 * 60 * 1000,
  sessionMaxAgeMs: 24 * 60 * 60 * 1000,
  disabled: false,
};

function event(uuid = '019b5b74-11d0-7000-8000-000000000001', value = 'ok'): CapturedEvent {
  return {
    uuid,
    event: 'custom_event',
    timestamp: '2026-07-15T00:00:00.000Z',
    distinct_id: 'user_1',
    properties: { value },
  };
}

function outbox(): CapturedEvent[] {
  return JSON.parse(localStorage.getItem('abto:outbox:v1:public_project_key') ?? '[]');
}

afterEach(() => {
  localStorage.clear();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
  vi.useRealTimers();
});

describe('Transport durable outbox', () => {
  it('retains transient 5xx and removes the event after success', async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(new Response(null, { status: 503 }))
      .mockResolvedValueOnce(new Response(null, { status: 202 }));
    vi.stubGlobal('fetch', fetchMock);
    const transport = new Transport(config);
    transport.enqueue(event());

    await transport.flush();
    expect(outbox()).toEqual([event()]);

    await transport.flush();
    expect(outbox()).toEqual([]);
    transport.shutdown();
  });

  it.each([408, 429])('retains transient HTTP %s responses', async (status) => {
    vi.stubGlobal('fetch', vi.fn(async () => new Response(null, { status })));
    const transport = new Transport(config);
    transport.enqueue(event());

    await transport.flush();

    expect(outbox()).toEqual([event()]);
    transport.shutdown();
  });

  it('drops a permanent 400 response instead of retrying forever', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => new Response(null, { status: 400 })));
    const transport = new Transport(config);
    transport.enqueue(event());

    await transport.flush();

    expect(outbox()).toEqual([]);
    transport.shutdown();
  });

  it('applies UUID-level ok, warning, drop, and retry results independently', async () => {
    const batch = [event('ok'), event('warning'), event('drop'), event('retry')];
    vi.stubGlobal(
      'fetch',
      vi.fn(async () =>
        Response.json(
          {
            results: {
              ok: { result: 'ok' },
              warning: { result: 'warning', code: 'schema_drift' },
              drop: { result: 'drop', code: 'schema_type_mismatch' },
              retry: { result: 'retry', code: 'storage_unavailable' },
            },
          },
          { status: 202 },
        ),
      ),
    );
    const transport = new Transport(config);
    batch.forEach((item) => transport.enqueue(item));

    await transport.flush();

    expect(outbox()).toEqual([event('retry')]);
    transport.shutdown();
  });

  it('backs off exponentially when Analytics repeatedly marks one event for retry', async () => {
    vi.useFakeTimers();
    const retried = event();
    const fetchMock = vi.fn(async () =>
      Response.json(
        {
          results: {
            [retried.uuid]: { result: 'retry', code: 'storage_unavailable' },
          },
        },
        { status: 202 },
      ),
    );
    vi.stubGlobal('fetch', fetchMock);
    const transport = new Transport(config);
    transport.enqueue(retried);

    await transport.flush();
    expect(fetchMock).toHaveBeenCalledTimes(1);

    await vi.advanceTimersByTimeAsync(1000);
    expect(fetchMock).toHaveBeenCalledTimes(2);

    await vi.advanceTimersByTimeAsync(1999);
    expect(fetchMock).toHaveBeenCalledTimes(2);
    await vi.advanceTimersByTimeAsync(1);
    expect(fetchMock).toHaveBeenCalledTimes(3);
    transport.shutdown();
  });

  it.each([
    ['$pageview', 'pageview'],
    ['$pageleave', 'pageleave'],
    ['$autocapture', 'interaction_autocaptured'],
    ['$rageclick', 'interaction_rageclick'],
    ['$dead_click', 'interaction_deadclick'],
    ['$ai_prompt_submitted', 'llm_prompt_submitted'],
    ['$ai_response_rendered', 'llm_response_rendered'],
    ['$ai_response_interacted', 'llm_response_interacted'],
  ])('maps the internal %s event to the fixed %s wire name', async (internalName, wireName) => {
    const fetchMock = vi.fn(async () => new Response(null, { status: 202 }));
    vi.stubGlobal('fetch', fetchMock);
    const transport = new Transport(config);
    transport.enqueue({
      ...event('system'),
      event: internalName,
      properties: { $lib: 'web', $session_id: 'session_1' },
    });

    await transport.flush();

    const body = JSON.parse((fetchMock.mock.calls[0]?.[1] as RequestInit).body as string);
    expect(body.batch[0]).toMatchObject({
      event_name: wireName,
      extra_json: { $lib: 'web', $session_id: 'session_1' },
    });
    expect(outbox()).toEqual([]);
    transport.shutdown();
  });

  it('drops unknown reserved names instead of retrying them forever', async () => {
    const unknownReservedEvent = {
      ...event('unknown-system'),
      event: '$unknown_system_event',
    };
    vi.stubGlobal(
      'fetch',
      vi.fn(async () =>
        Response.json(
          {
            results: {
              'unknown-system': { result: 'drop', code: 'reserved_name' },
            },
          },
          { status: 202 },
        ),
      ),
    );
    const transport = new Transport(config);
    transport.enqueue(unknownReservedEvent);

    await transport.flush();

    expect(outbox()).toEqual([]);
    transport.shutdown();
  });

  it('maps the internal Browser event to the existing Analytics ingest contract', async () => {
    const fetchMock = vi.fn(async () => new Response(null, { status: 202 }));
    vi.stubGlobal('fetch', fetchMock);
    const transport = new Transport(config);
    transport.enqueue(event());

    await transport.flush();

    const body = JSON.parse((fetchMock.mock.calls[0]?.[1] as RequestInit).body as string);
    expect(body.sent_at).toBeUndefined();
    expect(body.batch).toEqual([
      {
        event_id: '019b5b74-11d0-7000-8000-000000000001',
        device_id: 'user_1',
        event_name: 'custom_event',
        occurred_at: '2026-07-15T00:00:00.000Z',
        extra_json: { value: 'ok' },
      },
    ]);
    transport.shutdown();
  });

  it('promotes numeric value and scale properties to Analytics metric fields', async () => {
    const fetchMock = vi.fn(async () => new Response(null, { status: 202 }));
    vi.stubGlobal('fetch', fetchMock);
    const transport = new Transport(config);
    transport.enqueue({
      ...event(),
      properties: { value: 3000, scale: 'KRW', product: 'pro' },
    });

    await transport.flush();

    const body = JSON.parse((fetchMock.mock.calls[0]?.[1] as RequestInit).body as string);
    expect(body.batch[0]).toMatchObject({
      value: 3000,
      scale: 'KRW',
      extra_json: { value: 3000, scale: 'KRW', product: 'pro' },
    });
    transport.shutdown();
  });

  it('omits metric values outside the collector decimal precision', async () => {
    const fetchMock = vi.fn(async () => new Response(null, { status: 202 }));
    vi.stubGlobal('fetch', fetchMock);
    const transport = new Transport(config);
    transport.enqueue({
      ...event(),
      properties: { value: 1 / 3, product: 'pro' },
    });

    await transport.flush();

    const body = JSON.parse((fetchMock.mock.calls[0]?.[1] as RequestInit).body as string);
    expect(body.batch[0]).not.toHaveProperty('value');
    expect(body.batch[0].extra_json).toEqual({ value: 1 / 3, product: 'pro' });
    transport.shutdown();
  });

  it('omits an oversized scale while retaining the event and original properties', async () => {
    const fetchMock = vi.fn(async () => new Response(null, { status: 202 }));
    vi.stubGlobal('fetch', fetchMock);
    const transport = new Transport(config);
    const oversizedScale = 'x'.repeat(17);
    transport.enqueue({
      ...event(),
      properties: { scale: oversizedScale, product: 'pro' },
    });

    await transport.flush();

    const body = JSON.parse((fetchMock.mock.calls[0]?.[1] as RequestInit).body as string);
    expect(body.batch[0]).not.toHaveProperty('scale');
    expect(body.batch[0].extra_json).toEqual({ scale: oversizedScale, product: 'pro' });
    transport.shutdown();
  });

  it('does not use keepalive for a payload larger than 60 KiB', async () => {
    const fetchMock = vi.fn(async () => new Response(null, { status: 202 }));
    vi.stubGlobal('fetch', fetchMock);
    const transport = new Transport(config);
    transport.enqueue(event('large', 'x'.repeat(70 * 1024)));

    await transport.flush();

    expect((fetchMock.mock.calls[0]?.[1] as RequestInit).keepalive).toBe(false);
    transport.shutdown();
  });

  it('uses response-capable keepalive fetch for a safe unload payload', async () => {
    const sendBeacon = vi.fn(() => true);
    Object.defineProperty(navigator, 'sendBeacon', { configurable: true, value: sendBeacon });
    const fetchMock = vi.fn(async () => new Response(null, { status: 202 }));
    vi.stubGlobal('fetch', fetchMock);
    const transport = new Transport(config);
    transport.enqueue(event());

    await transport.flush(true);

    expect(sendBeacon).not.toHaveBeenCalled();
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect((fetchMock.mock.calls[0]?.[1] as RequestInit).keepalive).toBe(true);
    expect(outbox()).toEqual([]);
    transport.shutdown();
  });

  it('fetches without keepalive when unload payload is oversized', async () => {
    const sendBeacon = vi.fn(() => true);
    Object.defineProperty(navigator, 'sendBeacon', { configurable: true, value: sendBeacon });
    const fetchMock = vi.fn(async () => new Response(null, { status: 202 }));
    vi.stubGlobal('fetch', fetchMock);
    const transport = new Transport(config);
    transport.enqueue(event('large', 'x'.repeat(70 * 1024)));

    await transport.flush(true);

    expect(sendBeacon).not.toHaveBeenCalled();
    expect((fetchMock.mock.calls[0]?.[1] as RequestInit).keepalive).toBe(false);
    transport.shutdown();
  });

  it('replays an outbox retained by a previous SDK instance', async () => {
    const first = new Transport(config);
    first.enqueue(event());
    first.shutdown();

    const fetchMock = vi.fn(async () => new Response(null, { status: 202 }));
    vi.stubGlobal('fetch', fetchMock);
    const reloaded = new Transport(config);
    await reloaded.flush();

    expect(outbox()).toEqual([]);
    reloaded.shutdown();
  });
});
