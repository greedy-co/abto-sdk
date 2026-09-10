import { BrowserOutbox } from './outbox.js';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { BrowserDiagnostics } from './diagnostics.js';
import { Transport } from './transport.js';
import type { CapturedEvent } from './types.js';
import { ABTO_MAX_BUFFERED_EVENTS } from './delivery-policy.generated.js';

const config = {
  endpoint: 'https://collector.test/v1/collect/events',
  projectKey: 'public_project_key',
};

function event(
  uuid = '019b5b74-11d0-7000-8000-000000000001',
  properties: CapturedEvent['properties'] = {},
): CapturedEvent {
  return {
    uuid,
    event: 'custom_event',
    timestamp: '2026-07-15T00:00:00.000Z',
    device_id: 'device_1',
    properties,
  };
}

function outbox(): CapturedEvent[] {
  return new BrowserOutbox('public_project_key').read();
}

afterEach(() => {
  localStorage.clear();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
  vi.useRealTimers();
});

describe('Transport durable outbox', () => {
  it('retains the newest captured events at the cap even when UUID order is reversed', async () => {
    vi.useFakeTimers();
    vi.stubGlobal('fetch', vi.fn(async () => { throw new TypeError('offline'); }));
    const transport = new Transport(config);
    const captured = Array.from({ length: ABTO_MAX_BUFFERED_EVENTS + 3 }, (_, index) =>
      event(`019b5b74-11d0-7000-8000-${String(ABTO_MAX_BUFFERED_EVENTS + 3 - index).padStart(12, '0')}`));
    try {
      for (const item of captured) transport.enqueue(item);
      await transport.flush();
      expect(outbox().map((queued) => queued.uuid)).toEqual(captured.slice(3).map((queued) => queued.uuid));
    } finally { transport.shutdown(); }
    const fetchMock = vi.fn(async () => new Response(null, { status: 202 }));
    vi.stubGlobal('fetch', fetchMock);
    const reloaded = new Transport(config);
    try {
      await reloaded.flush();
      const batch = JSON.parse((fetchMock.mock.calls[0]?.[1] as RequestInit).body as string).batch;
      expect(batch.map((queued: { event_id: string }) => queued.event_id)).toEqual(captured.slice(3, 23).map((queued) => queued.uuid));
    } finally { reloaded.shutdown(); }
  });

  it('recovers events from two instances initialized before either enqueues', async () => {
    const first = new Transport(config);
    const second = new Transport(config);
    first.enqueue(event('first-tab'));
    second.enqueue(event('second-tab'));
    first.shutdown();
    second.shutdown();

    const fetchMock = vi.fn(async () => new Response(null, { status: 202 }));
    vi.stubGlobal('fetch', fetchMock);
    const reloaded = new Transport(config);
    await reloaded.flush();
    const body = JSON.parse((fetchMock.mock.calls[0]?.[1] as RequestInit).body as string);
    expect(body.batch.map((entry: { event_id: string }) => entry.event_id).sort()).toEqual(['first-tab', 'second-tab']);
    expect(outbox()).toEqual([]);
    reloaded.shutdown();
  });

  it('acknowledges only its batch while another instance appends during the request', async () => {
    let complete!: (response: Response) => void;
    vi.stubGlobal('fetch', vi.fn(() => new Promise<Response>((resolve) => { complete = resolve; })));
    const first = new Transport(config);
    const second = new Transport(config);
    first.enqueue(event('first-tab'));
    const pending = first.flush();
    second.enqueue(event('second-tab'));
    complete(new Response(null, { status: 202 }));
    await pending;
    expect(outbox().map((queued) => queued.uuid)).toEqual(['second-tab']);
    first.enqueue(event('first-new'));
    expect(outbox().map((queued) => queued.uuid).sort()).toEqual(['first-new', 'second-tab']);
    first.shutdown();
    second.shutdown();
  });

  it('does not repersist a stale restored event when that instance enqueues a new event', async () => {
    const first = new Transport(config);
    first.enqueue(event('old'));
    const stale = new Transport(config);
    vi.stubGlobal('fetch', vi.fn(async () => new Response(null, { status: 202 })));
    await first.flush();
    stale.enqueue(event('new'));
    expect(outbox().map((queued) => queued.uuid)).toEqual(['new']);
    first.shutdown();
    stale.shutdown();
  });

  it('migrates a legacy outbox and preserves another project when discarded', () => {
    localStorage.setItem('abto:outbox:v1:public_project_key', JSON.stringify([event('legacy')]));
    const first = new Transport(config);
    const second = new Transport({ ...config, projectKey: 'other-project' });
    second.enqueue(event('other'));
    expect(outbox().map((queued) => queued.uuid)).toEqual(['legacy']);
    expect(localStorage.getItem('abto:outbox:v1:public_project_key')).toBeNull();
    first.discard();
    expect(outbox()).toEqual([]);
    expect(new BrowserOutbox('other-project').read().map((queued) => queued.uuid)).toEqual(['other']);
    first.shutdown();
    second.shutdown();
  });

  it('persists a volatile event after storage recovers even when the network still fails', async () => {
    const originalSet = Storage.prototype.setItem;
    let failWrites = true;
    vi.spyOn(Storage.prototype, 'setItem').mockImplementation(function (this: Storage, key, value) {
      if (failWrites) throw new DOMException('quota exceeded', 'QuotaExceededError');
      originalSet.call(this, key, value);
    });
    vi.stubGlobal('fetch', vi.fn(async () => { throw new TypeError('offline'); }));
    const transport = new Transport(config);
    transport.enqueue(event('volatile'));
    failWrites = false;
    await transport.flush();
    expect(outbox().map((queued) => queued.uuid)).toEqual(['volatile']);
    transport.shutdown();
  });

  it('reports a send failure with the next retry and clears it only after success', async () => {
    const diagnostics = new BrowserDiagnostics();
    const fetchMock = vi
      .fn()
      .mockRejectedValueOnce(new TypeError('network unavailable'))
      .mockResolvedValueOnce(new Response(null, { status: 202 }))
      .mockResolvedValueOnce(new Response(null, { status: 202 }));
    vi.stubGlobal('fetch', fetchMock);
    const transport = new Transport(config, diagnostics);
    transport.enqueue({
      ...event(),
    });

    await transport.flush();
    const failedBody = JSON.parse((fetchMock.mock.calls[0]?.[1] as RequestInit).body as string);
    expect(failedBody).not.toHaveProperty('diagnostics');

    await transport.flush();
    const retryBody = JSON.parse((fetchMock.mock.calls[1]?.[1] as RequestInit).body as string);
    expect(retryBody.diagnostics).toEqual({
      sdk_name: 'browser-javascript',
      counters: { send_failed: 1 },
    });
    expect(JSON.stringify(retryBody.diagnostics)).not.toContain('private@example.com');

    transport.enqueue(event('019b5b74-11d0-7000-8000-000000000002'));
    await transport.flush();
    const nextBody = JSON.parse((fetchMock.mock.calls[2]?.[1] as RequestInit).body as string);
    expect(nextBody).not.toHaveProperty('diagnostics');
    expect(fetchMock).toHaveBeenCalledTimes(3);
    transport.shutdown();
  });

  it('reports outbox persistence failure without blocking the event batch', async () => {
    const diagnostics = new BrowserDiagnostics();
    vi.stubGlobal('localStorage', {
      getItem: () => null,
      setItem: () => {
        throw new DOMException('quota exceeded', 'QuotaExceededError');
      },
      clear: () => undefined,
      removeItem: () => undefined,
    });
    const fetchMock = vi.fn(async () => new Response(null, { status: 202 }));
    vi.stubGlobal('fetch', fetchMock);
    const transport = new Transport(config, diagnostics);

    transport.enqueue(event());
    await transport.flush();

    const body = JSON.parse((fetchMock.mock.calls[0]?.[1] as RequestInit).body as string);
    expect(body.diagnostics.counters).toEqual({ outbox_write_failed: 2 });
    expect(fetchMock).toHaveBeenCalledTimes(1);
    transport.shutdown();
  });

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
    // Pin jitter to zero so the exponential floor can be asserted exactly.
    vi.spyOn(Math, 'random').mockReturnValue(0);
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

  it('adds jitter above the exponential floor so simultaneous failures do not align', async () => {
    vi.useFakeTimers();
    // Highest jitter draw: the delay becomes exponential * (1 + ABTO_RETRY_JITTER_RATIO).
    vi.spyOn(Math, 'random').mockReturnValue(0.999999);
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

    // The exponential floor alone must not fire it any more.
    await vi.advanceTimersByTimeAsync(1000);
    expect(fetchMock).toHaveBeenCalledTimes(1);

    await vi.advanceTimersByTimeAsync(500);
    expect(fetchMock).toHaveBeenCalledTimes(2);
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
        device_id: 'device_1',
        event_name: 'custom_event',
        occurred_at: '2026-07-15T00:00:00.000Z',
        extra_json: {},
      },
    ]);
    transport.shutdown();
  });

  it('carries the metric through to the Analytics metric fields', async () => {
    const fetchMock = vi.fn(async () => new Response(null, { status: 202 }));
    vi.stubGlobal('fetch', fetchMock);
    const transport = new Transport(config);
    transport.enqueue({
      ...event(),
      value: 3000,
      scale: 'KRW',
    });

    await transport.flush();

    const body = JSON.parse((fetchMock.mock.calls[0]?.[1] as RequestInit).body as string);
    expect(body.batch[0]).toMatchObject({ value: 3000, scale: 'KRW', extra_json: {} });
    transport.shutdown();
  });

  it('does not use keepalive for a payload larger than 60 KiB', async () => {
    const fetchMock = vi.fn(async () => new Response(null, { status: 202 }));
    vi.stubGlobal('fetch', fetchMock);
    const transport = new Transport(config);
    transport.enqueue(event('large', { $lib: 'x'.repeat(70 * 1024) }));

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

  it('defers diagnostics that would disable keepalive until the next batch', async () => {
    const diagnostics = new BrowserDiagnostics();
    diagnostics.record('send_failed');
    diagnostics.record('outbox_write_failed');
    diagnostics.record('identity_persist_failed');
    diagnostics.record('storage_unavailable');
    const fetchMock = vi.fn(async () => new Response(null, { status: 202 }));
    vi.stubGlobal('fetch', fetchMock);
    const transport = new Transport(config, diagnostics);
    transport.enqueue(event('near-limit', { $lib: 'x'.repeat(60 * 1024 - 300) }));

    await transport.flush(true);

    const unloadRequest = fetchMock.mock.calls[0]?.[1] as RequestInit;
    expect(unloadRequest.keepalive).toBe(true);
    expect(JSON.parse(unloadRequest.body as string)).not.toHaveProperty('diagnostics');
    expect(diagnostics.snapshot()).toBeDefined();

    transport.enqueue(event('019b5b74-11d0-7000-8000-000000000002'));
    await transport.flush();

    const nextBody = JSON.parse((fetchMock.mock.calls[1]?.[1] as RequestInit).body as string);
    expect(nextBody.diagnostics.counters).toEqual({
      send_failed: 1,
      outbox_write_failed: 1,
      identity_persist_failed: 1,
      storage_unavailable: 1,
    });
    expect(diagnostics.snapshot()).toBeUndefined();
    transport.shutdown();
  });

  it('fetches without keepalive when unload payload is oversized', async () => {
    const sendBeacon = vi.fn(() => true);
    Object.defineProperty(navigator, 'sendBeacon', { configurable: true, value: sendBeacon });
    const fetchMock = vi.fn(async () => new Response(null, { status: 202 }));
    vi.stubGlobal('fetch', fetchMock);
    const transport = new Transport(config);
    transport.enqueue(event('large', { $lib: 'x'.repeat(70 * 1024) }));

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
