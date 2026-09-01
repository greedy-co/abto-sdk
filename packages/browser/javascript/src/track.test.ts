import { afterEach, describe, expect, it, vi } from 'vitest';
import { initAbto } from './client.js';

afterEach(() => {
  localStorage.clear();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

const events = {
  checkout_completed: {
    description: '결제가 완료됨',
    properties: {
      order_id: { type: 'string', required: true },
      amount: { type: 'number', required: true },
      currency: { type: 'string', enum: ['KRW', 'USD'], required: true },
    },
  },
} as const;

function installFetchStub(): ReturnType<typeof vi.fn> {
  const fetchMock = vi.fn(async () => new Response(null, { status: 202 }));
  vi.stubGlobal('fetch', fetchMock);
  return fetchMock;
}

function postedBatch(fetchMock: ReturnType<typeof vi.fn>): any[] {
  const init = fetchMock.mock.calls[0]?.[1] as RequestInit | undefined;
  return JSON.parse(init!.body as string).batch.map((event: any) => ({
    ...event,
    event: event.event_name,
    properties: event.extra_json,
  }));
}

function client(environment: 'development' | 'production' = 'production') {
  return initAbto({
    projectKey: 'public_project_key',
    apiHost: 'https://collector.test',
    environment,
    events,
    autocapture: { enabled: false },
  } as any);
}

describe('custom event boundary', () => {
  it('sends a registered custom event under its direct name', async () => {
    const fetchMock = installFetchStub();
    const sdk = client();

    sdk.identify('user-9', 'tenant-9');
    sdk.capture('checkout_completed', {
      order_id: 'order-1',
      amount: 49000,
      currency: 'KRW',
    });
    await sdk.flush();

    const [event] = postedBatch(fetchMock);
    expect(event.event_name).toBe('checkout_completed');
    expect(event.event_id).toEqual(expect.any(String));
    expect(event.device_id).toEqual(expect.any(String));
    expect(event.occurred_at).toEqual(expect.any(String));
    expect(event.extra_json).toMatchObject({
      order_id: 'order-1',
      amount: 49000,
      currency: 'KRW',
      $user_id: 'user-9',
      $tenant_id: 'tenant-9',
      $schema_version: '2026-09-02',
    });
  });

  it('never lets public capture claim a $ system event name', async () => {
    const fetchMock = installFetchStub();
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
    const sdk = client('development');

    sdk.capture('$pageview' as never, {} as never);
    await sdk.flush();

    expect(fetchMock).not.toHaveBeenCalled();
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('reserved'));
  });

  it('drops an overlong custom event name before enqueueing', async () => {
    const fetchMock = installFetchStub();
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
    const sdk = client('development');

    sdk.capture('🙂'.repeat(101) as never, {} as never);
    await sdk.flush();

    expect(fetchMock).not.toHaveBeenCalled();
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('200 UTF-16'));
  });

  it('accepts an unregistered custom event in development and warns about drift', async () => {
    const fetchMock = installFetchStub();
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
    const sdk = client('development');

    sdk.capture('discovered_event' as never, { source: 'experiment' } as never);
    await sdk.flush();

    expect(postedBatch(fetchMock)[0].event_name).toBe('discovered_event');
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('Discovered'));
  });

  it('drops an unregistered custom event in production', async () => {
    const fetchMock = installFetchStub();
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
    const sdk = client();

    sdk.capture('unknown_event' as never, {} as never);
    await sdk.flush();

    expect(fetchMock).not.toHaveBeenCalled();
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('not registered'));
  });

  it('drops required, type, and enum drift in production', async () => {
    const fetchMock = installFetchStub();
    vi.spyOn(console, 'warn').mockImplementation(() => undefined);
    const sdk = client();

    sdk.capture('checkout_completed', {
      amount: '49000',
      currency: 'EUR',
    } as never);
    await sdk.flush();

    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('sends registered schema drift in development with a warning', async () => {
    const fetchMock = installFetchStub();
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
    const sdk = client('development');

    sdk.capture('checkout_completed', {
      amount: '49000',
      currency: 'EUR',
    } as never);
    await sdk.flush();

    expect(postedBatch(fetchMock)[0].event).toBe('checkout_completed');
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('schema drift'));
  });

  it('allows undeclared additive properties', async () => {
    const fetchMock = installFetchStub();
    const sdk = client();

    sdk.capture('checkout_completed', {
      order_id: 'order-2',
      amount: 1000,
      currency: 'KRW',
      campaign: 'launch',
    } as never);
    await sdk.flush();

    expect(postedBatch(fetchMock)[0].properties.campaign).toBe('launch');
  });

  it.each(['development', 'production'] as const)(
    'drops reserved custom payload properties in %s',
    async (environment) => {
      const fetchMock = installFetchStub();
      const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
      const sdk = client(environment);

      sdk.capture('checkout_completed', {
        order_id: 'order-3',
        amount: 1000,
        currency: 'KRW',
        $custom: 'spoofed',
      } as never);
      await sdk.flush();

      expect(fetchMock).not.toHaveBeenCalled();
      expect(warn).toHaveBeenCalledWith(expect.stringContaining('$custom is reserved'));
    },
  );

  it('drops reserved payload properties on unregistered development events', async () => {
    const fetchMock = installFetchStub();
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
    const sdk = client('development');

    sdk.capture('discovered_event' as never, { $custom: 'spoofed' } as never);
    await sdk.flush();

    expect(fetchMock).not.toHaveBeenCalled();
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('$custom is reserved'));
  });
});
