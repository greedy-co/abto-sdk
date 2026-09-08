import { BrowserOutbox } from './outbox.js';
// Client SDK 4종이 공통으로 증명해야 하는 동작을 Browser 관점에서 확인한다.
// 시나리오 목록의 정본은 contracts/client-sdk/conformance.schema.json 이며,
// 이 파일이 그 목록을 되읽어 빠진 것이 없는지 스스로 대조한다.
import { afterEach, describe, expect, it, vi } from 'vitest';

import { initAbto } from './client.js';
import { defineEvents, validateCustomEventName } from './event-registry.js';
import { BrowserIdentityStore } from './identity.js';
import { Transport } from './transport.js';
import {
  ABTO_CONFORMANCE_EXEMPTIONS,
  ABTO_CONFORMANCE_SCENARIOS,
  ABTO_ERR_PROJECT_KEY_REQUIRED,
  ABTO_MAX_BUFFERED_EVENTS,
  ABTO_SCALE_MAX_LENGTH,
} from './delivery-policy.generated.js';
import {
  ABTO_EVENT_NAME_MAX_LENGTH,
  BROWSER_SYSTEM_EVENT_WIRE_NAMES,
} from './system-events.generated.js';
import type { CapturedEvent } from './types.js';

class MemoryStorage {
  readonly values = new Map<string, string>();

  getItem(key: string): string | null {
    return this.values.get(key) ?? null;
  }

  setItem(key: string, value: string): void {
    this.values.set(key, value);
  }
}

const UUID_V7_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;
const covered = new Set<string>();

/** 이 test 가 증명하는 공통 시나리오를 기록한다. */
function covers(scenario: string): void {
  expect(ABTO_CONFORMANCE_SCENARIOS as readonly string[]).toContain(scenario);
  covered.add(scenario);
}

const events = defineEvents({
  user_action: { properties: { name: { type: 'string', required: false } } },
  checkout_completed: {
    properties: {
      value: { type: 'number', required: false },
      scale: { type: 'string', required: false },
    },
  },
});

afterEach(() => {
  localStorage.clear();
  sessionStorage.clear();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

function installFetchStub(): ReturnType<typeof vi.fn> {
  const fetchMock = vi.fn(async () => new Response(null, { status: 202 }));
  vi.stubGlobal('fetch', fetchMock);
  return fetchMock;
}

function postedBatch(fetchMock: ReturnType<typeof vi.fn>): any[] {
  const init = fetchMock.mock.calls[0]?.[1] as RequestInit | undefined;
  return JSON.parse(init!.body as string).batch;
}

function client() {
  return initAbto({
    projectKey: 'public_project_key',
    apiHost: 'https://collector.test',
    events,
  });
}

describe('client conformance', () => {
  it('identity: a device id persists while a session id rotates, both UUIDv7', () => {
    covers('identity.anonymous_persists');
    covers('identity.session_rotates');
    covers('identity.uuidv7');
    let now = 0;
    const storage = new MemoryStorage();
    const store = new BrowserIdentityStore({
      projectKey: 'public_project_key',
      storage,
      windowStorage: new MemoryStorage(),
      now: () => now,
    });
    const first = store.current();
    expect(first.deviceId).toMatch(UUID_V7_RE);
    expect(first.sessionId).toMatch(UUID_V7_RE);

    now += 31 * 60 * 1000;
    const rotated = store.current();
    expect(rotated.deviceId).toBe(first.deviceId);
    expect(rotated.sessionId).not.toBe(first.sessionId);
  });

  it('identity: identify attaches a user id and reset clears it', async () => {
    covers('identity.identify_and_reset');
    const fetchMock = installFetchStub();
    const sdk = client();
    sdk.identify('user-1');
    sdk.capture('user_action', {});
    sdk.reset();
    sdk.capture('user_action', {});
    await sdk.flush();

    const [identified, afterReset] = postedBatch(fetchMock);
    expect(identified.extra_json.$user_id).toBe('user-1');
    expect(afterReset.extra_json.$user_id).toBeUndefined();
    sdk.shutdown();
  });

  it('config: an empty projectKey is rejected', () => {
    covers('config.project_key_required');
    expect(() => initAbto({ projectKey: '' })).toThrowError(ABTO_ERR_PROJECT_KEY_REQUIRED);
  });

  it('config: a malformed apiHost is rejected', () => {
    covers('config.endpoint_must_be_url');
    expect(() => initAbto({ projectKey: 'ek_test', apiHost: 'htp:/broken url' })).toThrowError();
  });

  it('event: a name past the backend limit is rejected', () => {
    covers('event.name_length_limit');
    expect(validateCustomEventName('a'.repeat(ABTO_EVENT_NAME_MAX_LENGTH))).toBeUndefined();
    expect(validateCustomEventName('a'.repeat(ABTO_EVENT_NAME_MAX_LENGTH + 1))).toBeDefined();
  });

  it('event: a reserved system wire name is rejected', () => {
    covers('event.reserved_name_rejected');
    for (const reserved of Object.values(BROWSER_SYSTEM_EVENT_WIRE_NAMES)) {
      expect(validateCustomEventName(reserved), reserved).toBeDefined();
    }
  });

  it('event: a non-finite metric value is omitted', async () => {
    covers('event.metric_non_finite_omitted');
    const fetchMock = installFetchStub();
    const sdk = client();
    sdk.capture('checkout_completed', { value: Number.POSITIVE_INFINITY });
    await sdk.flush();
    expect(postedBatch(fetchMock)[0].value).toBeUndefined();
    sdk.shutdown();
  });

  it('event: an over-precision metric value is omitted', async () => {
    covers('event.metric_precision_enforced');
    const fetchMock = installFetchStub();
    const sdk = client();
    sdk.capture('checkout_completed', { value: 1.1234567890123456 });
    await sdk.flush();
    expect(postedBatch(fetchMock)[0].value).toBeUndefined();
    sdk.shutdown();
  });

  it('event: a metric scale past the backend limit is omitted', async () => {
    covers('event.metric_scale_limit');
    const fetchMock = installFetchStub();
    const sdk = client();
    sdk.capture('checkout_completed', {
      value: 1,
      scale: 'K'.repeat(ABTO_SCALE_MAX_LENGTH + 1),
    });
    await sdk.flush();
    expect(postedBatch(fetchMock)[0].scale).toBeUndefined();
    sdk.shutdown();
  });

  it('privacy: prompt and response text never leave the browser', async () => {
    covers('privacy.prompt_and_response_text_not_sent');
    const fetchMock = installFetchStub();
    const sdk = client();
    const trace = sdk.startLlmTrace({ featureId: 'assistant.reply' });
    await trace.submitPrompt({ prompt: 'prompt-canary' });
    await trace.markResponseRendered({ responseId: 'r1', responseText: 'response-canary' });
    await sdk.flush();

    const encoded = JSON.stringify(postedBatch(fetchMock));
    expect(encoded).not.toContain('prompt-canary');
    expect(encoded).not.toContain('response-canary');
    sdk.shutdown();
  });

  it('transport: a Gateway request id is read case-insensitively', () => {
    covers('transport.request_id_header_case_insensitive');
    const sdk = client();
    const trace = sdk.startLlmTrace({ featureId: 'assistant.reply' });
    trace.attachRequestId(
      new Response(null, { headers: { 'X-ABTO-REQUEST-ID': 'req_upper' } }),
    );
    expect(trace.requestId).toBe('req_upper');
    sdk.shutdown();
  });

  it('transport: only events marked retry or omitted are retried', async () => {
    covers('transport.retry_marked_events_only');
    const transport = new Transport({
      endpoint: 'https://collector.test/v1/collect/events',
      projectKey: 'public_project_key',
    });
    const kept = '019b5b74-11d0-7000-8000-000000000001';
    const dropped = '019b5b74-11d0-7000-8000-000000000002';
    vi.stubGlobal('fetch', vi.fn(async () => new Response(
      JSON.stringify({ results: { [dropped]: { result: 'ok' } } }),
      { status: 202, headers: { 'content-type': 'application/json' } },
    )));
    transport.enqueue(event(kept));
    transport.enqueue(event(dropped));
    await transport.flush();

    const outbox = readOutbox();
    expect(outbox.map((queued) => queued.uuid)).toEqual([kept]);
  });

  it('transport: the buffer keeps at most the declared cap, dropping the oldest', () => {
    covers('transport.buffer_cap');
    const transport = new Transport({
      endpoint: 'https://collector.test/v1/collect/events',
      projectKey: 'public_project_key',
    });
    const overflow = 5;
    for (let index = 0; index < ABTO_MAX_BUFFERED_EVENTS + overflow; index += 1) {
      transport.enqueue(event(`019b5b74-11d0-7000-8000-${String(index).padStart(12, '0')}`));
    }
    const outbox = readOutbox();
    expect(outbox.length).toBeLessThanOrEqual(ABTO_MAX_BUFFERED_EVENTS);
    expect(outbox.some((queued) => queued.uuid.endsWith('000000000000'))).toBe(false);
  });
});

describe('client conformance coverage', () => {
  it('covers every declared scenario that is not exempt', () => {
    const exempt = new Set<string>(ABTO_CONFORMANCE_EXEMPTIONS as readonly string[]);
    const missing = (ABTO_CONFORMANCE_SCENARIOS as readonly string[])
      .filter((scenario) => !covered.has(scenario) && !exempt.has(scenario));
    expect(missing, 'client conformance scenarios not covered by this SDK').toEqual([]);
  });
});

function event(uuid: string): CapturedEvent {
  return {
    uuid,
    event: 'custom_event',
    timestamp: '2026-07-15T00:00:00.000Z',
    distinct_id: 'user_1',
    properties: {},
  };
}

function readOutbox(): CapturedEvent[] {
  return new BrowserOutbox('public_project_key').read();
}
