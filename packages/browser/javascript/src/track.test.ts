import { afterEach, describe, expect, it, vi } from 'vitest';
import { initAbto } from './client.js';
import {
  ABTO_ERR_EVENT_NAME_DOLLAR_PREFIX,
  ABTO_ERR_EVENT_NAME_TOO_LONG,
} from './delivery-policy.generated.js';

afterEach(() => {
  localStorage.clear();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

const events = {
  checkout_completed: { description: 'Checkout completed' },
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
    sdk.capture('checkout_completed', { value: 49000, scale: 'KRW', tier: 'pro', nullable: null, tags: ['a'], detail: { enabled: true } });
    await sdk.flush();

    const [event] = postedBatch(fetchMock);
    expect(event.event_name).toBe('checkout_completed');
    expect(event.event_id).toEqual(expect.any(String));
    expect(event.device_id).toEqual(expect.any(String));
    expect(event.occurred_at).toEqual(expect.any(String));
    expect(event.value).toBe(49000);
    expect(event.scale).toBe('KRW');
    expect(event.extra_json).not.toHaveProperty('value');
    expect(event.extra_json).not.toHaveProperty('scale');
    expect(event.extra_json).not.toHaveProperty('properties');
    expect(event.extra_json).toMatchObject({
      tier: 'pro', nullable: null, tags: ['a'], detail: { enabled: true },
      $user_id: 'user-9',
      $tenant_id: 'tenant-9',
      $schema_version: '2026-09-02',
    });
  });

  it('sends an explicit count metric as a conversion signal', async () => {
    const fetchMock = installFetchStub();
    const sdk = client();
    sdk.capture('checkout_completed', { value: 1, scale: 'count' });
    await sdk.flush();
    expect(postedBatch(fetchMock)[0]).toMatchObject({ value: 1, scale: 'count' });
  });

  it.each([undefined, ''])('preserves optional scale %j without mutating input', async (scale) => {
    const fetchMock = installFetchStub();
    const sdk = client();
    const input = Object.freeze({ value: 0, ...(scale === undefined ? {} : { scale }), tier: 'pro' });
    sdk.capture('checkout_completed', input);
    await sdk.flush();
    const event = postedBatch(fetchMock)[0];
    expect(event.value).toBe(0);
    if (scale === undefined) expect(event).not.toHaveProperty('scale');
    else expect(event.scale).toBe('');
    expect(event.extra_json).toMatchObject({ tier: 'pro' });
    expect(event.extra_json).not.toHaveProperty('scale');
    expect(input.tier).toBe('pro');
  });

  it.each([
    null, [], 1, { value: null }, { scale: null },
    { value: 1 / 3, scale: 'KRW' }, { value: Infinity, scale: 'KRW' },
    { value: 1, scale: 'x'.repeat(17) },
    { value: 1, scale: '\0' },
    ...[{ $user_id: 'spoof' }, { tier: undefined },
      { deep: { nested: {} } }, { bad: NaN }, { bad: new Date() }, { bad: '\0' }]
      .map((properties) => ({ value: 1, scale: 'count', ...properties })),
  ])('drops invalid custom capture input: %j', async (options) => {
    const fetchMock = installFetchStub();
    const sdk = client();
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
    sdk.capture('checkout_completed', options as never);
    await sdk.flush();
    expect(fetchMock).not.toHaveBeenCalled();
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('custom event was dropped'));
  });

  it('never lets public capture claim a $ system event name', async () => {
    const fetchMock = installFetchStub();
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
    const sdk = client('development');

    sdk.capture('$pageview' as never, { value: 1, scale: 'count' });
    await sdk.flush();

    expect(fetchMock).not.toHaveBeenCalled();
    expect(warn).toHaveBeenCalledWith(expect.stringContaining(ABTO_ERR_EVENT_NAME_DOLLAR_PREFIX));
  });

  it('drops an overlong custom event name before enqueueing', async () => {
    const fetchMock = installFetchStub();
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
    const sdk = client('development');

    sdk.capture('🙂'.repeat(101) as never, { value: 1, scale: 'count' });
    await sdk.flush();

    expect(fetchMock).not.toHaveBeenCalled();
    expect(warn).toHaveBeenCalledWith(expect.stringContaining(ABTO_ERR_EVENT_NAME_TOO_LONG));
  });

  it('accepts an unregistered custom event in development and warns about the discovery', async () => {
    const fetchMock = installFetchStub();
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
    const sdk = client('development');

    sdk.capture('discovered_event' as never, { value: 1, scale: 'count' });
    await sdk.flush();

    expect(postedBatch(fetchMock)[0].event_name).toBe('discovered_event');
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('Discovered'));
  });

  it('drops an unregistered custom event in production', async () => {
    const fetchMock = installFetchStub();
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
    const sdk = client();

    sdk.capture('unknown_event' as never, { value: 1, scale: 'count' });
    await sdk.flush();

    expect(fetchMock).not.toHaveBeenCalled();
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('not registered'));
  });
});
