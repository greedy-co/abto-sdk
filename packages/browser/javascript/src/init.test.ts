import { describe, it, expect, afterEach } from 'vitest';
import { AbtoBrowserClient } from './client.js';

let client: AbtoBrowserClient | undefined;
afterEach(() => {
  client?.shutdown();
  client = undefined;
  localStorage.clear();
  sessionStorage.clear();
});

describe('init config validation', () => {
  it('accepts a minimal valid config', () => {
    client = new AbtoBrowserClient({ projectKey: 'ek_test' });
    expect(client.config.projectKey).toBe('ek_test');
    expect(client.config.endpoint).toBe('https://api.abto.app/v1/collect/events');
  });

  it('rejects a missing projectKey', () => {
    expect(() => new AbtoBrowserClient({ projectKey: '' })).toThrowError(
      '[abto] projectKey is required. Check your init config.',
    );
  });

  it('rejects a malformed apiHost', () => {
    expect(() => new AbtoBrowserClient({ projectKey: 'ek_test', apiHost: 'not a url' })).toThrowError(
      '[abto] apiHost is not a valid http(s) URL: "not a url"',
    );
  });

  it('rejects a malformed endpoint', () => {
    expect(() => new AbtoBrowserClient({ projectKey: 'ek_test', endpoint: 'nope' })).toThrowError(
      '[abto] endpoint is not a valid http(s) URL: "nope"',
    );
  });

  it('uses privacy-preserving capture defaults', () => {
    client = new AbtoBrowserClient({ projectKey: 'ek_test' });
    expect(client.config.capturePrompt).toBe('metadata_only');
    expect(client.config.captureResponse).toBe('metadata_only');
    expect(client.config.mask).toBe('all');
    expect(client.config.hashSalt).toBe('ek_test');
  });

  it('emits no automatic events when autocapture is omitted', () => {
    client = new AbtoBrowserClient({ projectKey: 'ek_no_automatic_events' });

    expect(client.config.autocapture).toBe(false);
    expect(localStorage.getItem('abto:outbox:v1:ek_no_automatic_events')).toBeNull();
  });
});
