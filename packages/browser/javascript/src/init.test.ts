import { describe, it, expect, afterEach } from 'vitest';
import { initAbto } from './client.js';
import * as publicApi from './index.js';

let client: ReturnType<typeof initAbto> | undefined;
afterEach(() => {
  client?.shutdown();
  client = undefined;
  localStorage.clear();
  sessionStorage.clear();
});

describe('init config validation', () => {
  it('exposes only the factory and event registry at runtime', () => {
    expect(Object.keys(publicApi).sort()).toEqual(['defineEvents', 'initAbto']);
  });

  it('accepts a minimal valid config', () => {
    client = initAbto({ projectKey: 'ek_test' });
    expect(client.getIdentity().deviceId).toEqual(expect.any(String));
  });

  it('rejects a missing projectKey', () => {
    expect(() => initAbto({ projectKey: '' })).toThrowError(
      '[abto] projectKey is required. Check your init config.',
    );
  });

  it('rejects a malformed apiHost', () => {
    expect(() => initAbto({ projectKey: 'ek_test', apiHost: 'not a url' })).toThrowError(
      '[abto] apiHost is not a valid http(s) URL: "not a url"',
    );
  });

  it('emits no automatic events when autocapture is omitted', () => {
    client = initAbto({ projectKey: 'ek_no_automatic_events' });

    expect(localStorage.getItem('abto:outbox:v1:ek_no_automatic_events')).toBeNull();
  });
});
