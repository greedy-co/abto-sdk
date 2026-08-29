import { afterEach, describe, expect, it, vi } from 'vitest';
import {
  AbtoBrowserClient,
  getIdentity,
  initAbto,
  SDK_VERSION,
} from './client.js';
import { defineEvents } from './event-registry.js';

const UUID_V7_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;

const events = defineEvents({
  user_action: {
    properties: { name: { type: 'string', required: true } },
  },
});

afterEach(() => {
  localStorage.clear();
  sessionStorage.clear();
  document.body.innerHTML = '';
  vi.useRealTimers();
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
  expect(init?.body).toEqual(expect.any(String));
  return JSON.parse(init!.body as string).batch.map((event: any) => ({
    uuid: event.event_id,
    event: event.event_name,
    timestamp: event.occurred_at,
    distinct_id: event.device_id,
    properties: event.extra_json,
  }));
}

function client(options: { autocapture?: boolean } = {}) {
  return new AbtoBrowserClient({
    projectKey: 'public_project_key',
    endpoint: 'https://collector.test/v1/collect/events',
    events,
    autocapture: { enabled: options.autocapture ?? false },
  });
}

describe('Browser event envelope and identity', () => {
  it('does not expose the ABTO-owned system capture path', () => {
    const sdk = client();

    expect('captureSystem' in sdk).toBe(false);
    sdk.shutdown();
  });

  it('discards persisted events before beginning a new device lifecycle', async () => {
    const fetchMock = installFetchStub();
    const sdk = client();
    sdk.capture('user_action', { name: 'queued' });
    expect(JSON.parse(localStorage.getItem('abto:outbox:v1:public_project_key') ?? '[]')).toHaveLength(1);

    sdk.forgetDevice();
    await sdk.flush();

    expect(JSON.parse(localStorage.getItem('abto:outbox:v1:public_project_key') ?? '[]')).toEqual([]);
    expect(fetchMock).not.toHaveBeenCalled();
    sdk.shutdown();
  });

  it('puts identity context in properties and switches distinct_id after identify', async () => {
    const fetchMock = installFetchStub();
    const sdk = client();
    sdk.capture('user_action', { name: 'anonymous' });
    sdk.identify('user-1', 'tenant-1');
    sdk.capture('user_action', { name: 'identified' });
    await sdk.flush();

    const [anonymous, identified] = postedBatch(fetchMock);
    expect(anonymous.uuid).toMatch(UUID_V7_RE);
    expect(anonymous.distinct_id).toBe(anonymous.properties.$anonymous_id);
    expect(anonymous.properties.$device_id).toMatch(UUID_V7_RE);
    expect(anonymous.properties.$session_id).toMatch(UUID_V7_RE);
    expect(anonymous.properties.$window_id).toMatch(UUID_V7_RE);
    expect(anonymous.properties.$pageview_id).toMatch(UUID_V7_RE);
    expect(anonymous.properties.$user_id).toBeUndefined();
    expect(identified.distinct_id).toBe(identified.properties.$device_id);
    expect(identified.properties.$user_id).toBe('user-1');
    expect(identified.properties.$tenant_id).toBe('tenant-1');
    expect(identified.properties.$session_id).toBe(anonymous.properties.$session_id);
  });

  it('replaces tenant identity and clears all scoped context on reset', async () => {
    const fetchMock = installFetchStub();
    const sdk = client();
    sdk.identify('user-1', 'tenant-1');
    sdk.identify('user-2');
    sdk.startLlmTrace({
      nodeId: 'chat.private',
      taskType: 'answer',
      surface: 'composer',
      entryPoint: 'home',
      conversationId: 'conversation-1',
      messageId: 'message-1',
      promptTemplateId: 'template-1',
    });
    sdk.reset();
    sdk.capture('user_action', { name: 'after-reset' });
    await sdk.flush();

    const [event] = postedBatch(fetchMock);
    expect(event.properties.$user_id).toBeUndefined();
    expect(event.properties.$tenant_id).toBeUndefined();
    expect(event.properties.$node_key).toBeUndefined();
    expect(event.properties.$trace_id).toBeUndefined();
    expect(event.properties.$task_type).toBeUndefined();
    expect(event.properties.$surface).toBeUndefined();
    expect(event.properties.$entry_point).toBeUndefined();
    expect(event.properties.$conversation_id).toBeUndefined();
    expect(event.properties.$message_id).toBeUndefined();
    expect(event.properties.$prompt_template_id).toBeUndefined();
    sdk.shutdown();
  });

  it('keeps SDK and host app versions in separate system properties', async () => {
    const fetchMock = installFetchStub();
    const sdk = new AbtoBrowserClient({
      projectKey: 'public_project_key',
      endpoint: 'https://collector.test/v1/collect/events',
      appVersion: 'host-1.2.3',
      events,
      autocapture: { enabled: false },
    });
    sdk.capture('user_action', { name: 'versioned' });
    await sdk.flush();

    const [event] = postedBatch(fetchMock);
    expect(event.properties.$lib_version).toBe(SDK_VERSION);
    expect(event.properties.$app_version).toBe('host-1.2.3');
    sdk.shutdown();
  });

  it('keeps the initialized identity available through the singleton API', () => {
    const sdk = initAbto({
      projectKey: 'public_project_key',
      events,
      autocapture: { enabled: false },
    });
    expect(getIdentity()).toEqual(sdk.getIdentity());
  });
});

describe('observable AI events', () => {
  it('emits only prompt submitted, response rendered, and response interacted', async () => {
    const fetchMock = installFetchStub();
    const sdk = client();
    const trace = sdk.startLlmTrace({ nodeId: 'chat.default', surface: 'composer' });
    trace.attachRequestId(new Response(null, { headers: { 'x-abto-request-id': 'req_123' } }));

    await trace.submitPrompt({ prompt: 'secret prompt' });
    await trace.markResponseRendered({
      responseId: 'resp_1',
      responseText: 'secret response',
      timeToRenderMs: 42,
    });
    await trace.captureResponseInteraction('accepted', {
      responseId: 'resp_1',
      source: 'accept_button',
    });
    await sdk.flush();

    const batch = postedBatch(fetchMock);
    expect(batch.map((event) => event.event)).toEqual([
      'llm_prompt_submitted',
      'llm_response_rendered',
      'llm_response_interacted',
    ]);
    expect(batch[0].properties.$prompt_text).toBeUndefined();
    expect(batch[1].properties.$response_text).toBeUndefined();
    expect(batch[1].properties.$output_length_chars).toBe(15);
    expect(batch[1].properties.$request_id).toBe('req_123');
    expect(batch[2].properties.$interaction_type).toBe('accepted');
    expect(batch[2].properties.$request_id).toBe('req_123');
  });

  it('rejects an empty request_id', () => {
    const trace = client().startLlmTrace({ nodeId: 'chat.default' });
    expect(() => trace.setRequestId('   ')).toThrow('[abto] setRequestId');
  });

  it('drops a non-canonical response interaction at runtime', async () => {
    const fetchMock = installFetchStub();
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
    const sdk = client();
    const trace = sdk.startLlmTrace({ nodeId: 'chat.default' });

    await trace.captureResponseInteraction('retried' as never);
    await sdk.flush();

    expect(fetchMock).not.toHaveBeenCalled();
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('response interaction was dropped'));
    sdk.shutdown();
  });

  it('sends annotated $autocapture as interaction_autocaptured with AI dimensions', async () => {
    const fetchMock = installFetchStub();
    document.body.innerHTML = `
      <button
        data-abto-action="accept"
        data-abto-response-id="resp_1"
        data-abto-request-id="req_dom">
        Apply
      </button>
    `;
    const sdk = client({ autocapture: true });
    document.querySelector('button')!.dispatchEvent(new MouseEvent('click', { bubbles: true }));
    await sdk.flush();
    sdk.shutdown();

    const batch = postedBatch(fetchMock);
    const interactions = batch.filter((event) => event.event === 'interaction_autocaptured');
    expect(interactions).toHaveLength(1);
    expect(interactions[0].properties.$ai_action).toBe('accept');
    expect(interactions[0].properties.$response_id).toBe('resp_1');
    expect(interactions[0].properties.$request_id).toBe('req_dom');
    expect(batch.some((event) => event.event === 'llm_response_interacted')).toBe(false);
  });
});

describe('pageview lifecycle', () => {
  it('rotates $pageview_id and records $pageleave dwell time', async () => {
    const fetchMock = installFetchStub();
    const sdk = client({ autocapture: true });
    await new Promise((resolve) => setTimeout(resolve, 0));
    history.pushState({}, '', '/dwell/rotate');
    await sdk.flush();
    sdk.shutdown();

    const batch = postedBatch(fetchMock);
    const pageviews = batch.filter((event) => event.event === 'pageview');
    const leave = batch.find((event) => event.event === 'pageleave');
    expect(pageviews).toHaveLength(2);
    expect(leave.properties.$duration_ms).toBeGreaterThanOrEqual(0);
    expect(leave.properties.$pageview_id).toBe(pageviews[0].properties.$pageview_id);
    expect(pageviews[1].properties.$pageview_id).not.toBe(pageviews[0].properties.$pageview_id);
    expect(batch.some((event) => event.event === '$session_start')).toBe(false);
    expect(batch.some((event) => event.event === '$session_end')).toBe(false);
  });

  it('flushes unload $pageleave as pageleave via keepalive fetch', async () => {
    const fetchMock = installFetchStub();
    const sendBeacon = vi.fn(() => true);
    Object.defineProperty(navigator, 'sendBeacon', { configurable: true, value: sendBeacon });
    const sdk = client({ autocapture: true });
    await sdk.flush();
    window.dispatchEvent(new Event('pagehide'));
    await vi.waitFor(() => expect(fetchMock.mock.calls.length).toBeGreaterThan(1));
    sdk.shutdown();

    expect(sendBeacon).not.toHaveBeenCalled();
    const leave = fetchMock.mock.calls
      .map((call) => JSON.parse((call[1] as RequestInit).body as string))
      .flatMap((body) => body.batch)
      .find((event) => event.event_name === 'pageleave');
    expect(leave).toBeDefined();
    expect(leave.extra_json.$duration_ms).toBeGreaterThanOrEqual(0);
  });
});
