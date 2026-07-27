// @vitest-environment node

import { describe, expect, it } from 'vitest';
import {
  buildOpenAIClientOptions,
  createAbtoOpenAI,
  createGatewayFetch,
} from './openai.js';

describe('ABTO OpenAI Gateway client', () => {
  it('adds candidate provider keys and request context to each Gateway call', async () => {
    let capturedHeaders: Headers | undefined;
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: {
        openai: 'sk-openai',
        anthropic: async () => 'sk-anthropic',
      },
      getContext: () => ({
        deviceId: 'device-1',
        nodeKey: 'chat.default',
      }),
      fetchImpl: async (_input, init) => {
        capturedHeaders = new Headers(init?.headers);
        expect(init?.redirect).toBe('manual');
        return new Response('{}', { status: 200 });
      },
    });

    await gatewayFetch('https://gateway.abto.app/v1/chat/completions', {
      method: 'POST',
      headers: { Authorization: 'Bearer caller-override' },
    });

    expect(capturedHeaders?.get('authorization')).toBe('Bearer abto-test');
    expect(capturedHeaders?.get('x-abto-key-openai')).toBe('sk-openai');
    expect(capturedHeaders?.get('x-abto-key-anthropic')).toBe('sk-anthropic');
    expect(capturedHeaders?.get('x-abto-device-id')).toBe('device-1');
    expect(capturedHeaders?.get('x-abto-node-key')).toBe('chat.default');
  });

  it('resolves Provider credentials again for every request', async () => {
    let currentKey = 'sk-first';
    const capturedKeys: string[] = [];
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: { openai: () => currentKey },
      fetchImpl: async (_input, init) => {
        capturedKeys.push(new Headers(init?.headers).get('x-abto-key-openai') ?? '');
        return new Response('{}', { status: 200 });
      },
    });

    await gatewayFetch('https://gateway.abto.app/v1/chat/completions');
    currentKey = 'sk-rotated';
    await gatewayFetch('https://gateway.abto.app/v1/chat/completions');

    expect(capturedKeys).toEqual(['sk-first', 'sk-rotated']);
  });

  it('rejects invalid ABTO credentials before issuing a request', async () => {
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-safe\nX-Leaked: value',
      fetchImpl: async () => new Response('{}'),
    });

    await expect(
      gatewayFetch('https://gateway.abto.app/v1/chat/completions'),
    ).rejects.toThrow('ABTO API key contains invalid characters.');
  });

  it('rejects a blank ABTO credential before issuing a request', async () => {
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: '   ',
      fetchImpl: async () => new Response('{}'),
    });

    await expect(
      gatewayFetch('https://gateway.abto.app/v1/chat/completions'),
    ).rejects.toThrow('ABTO API key is required.');
  });

  it('keeps Gateway security options authoritative over caller client options', () => {
    const protectedFetch = async () => new Response('{}');
    const options = buildOpenAIClientOptions({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      fetch: protectedFetch,
      clientOptions: {
        baseURL: 'https://example.com/steal',
        apiKey: 'wrong-key',
        fetch: async () => new Response('stolen'),
        maxRetries: 9,
        timeout: 12_345,
      },
    });

    expect(options.baseURL).toBe('https://gateway.abto.app/v1');
    expect(options.apiKey).toBe('abto-test');
    expect(options.fetch).toBe(protectedFetch);
    expect(options.maxRetries).toBe(0);
    expect(options.timeout).toBe(12_345);
  });

  it('rejects absolute requests outside the configured Gateway origin before resolving keys', async () => {
    let providerKeyResolved = false;
    let requestIssued = false;
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: {
        openai: () => {
          providerKeyResolved = true;
          return 'sk-openai';
        },
      },
      fetchImpl: async () => {
        requestIssued = true;
        return new Response('{}');
      },
    });

    await expect(gatewayFetch('https://attacker.example/steal')).rejects.toThrow(
      'outside the configured Gateway origin',
    );
    expect(providerKeyResolved).toBe(false);
    expect(requestIssued).toBe(false);
  });

  it('preserves ordinary Request headers but replaces reserved credential headers', async () => {
    let capturedHeaders: Headers | undefined;
    const gatewayFetch = createGatewayFetch({
      gatewayBaseURL: 'https://gateway.abto.app/v1',
      abtoApiKey: 'abto-test',
      providerKeys: { openai: 'sk-trusted' },
      getContext: () => ({ deviceId: 'trusted-device' }),
      fetchImpl: async (_input, init) => {
        capturedHeaders = new Headers(init?.headers);
        return new Response('{}');
      },
    });
    const request = new Request('https://gateway.abto.app/v1/chat/completions', {
      headers: {
        'x-client-header': 'preserved',
        Authorization: 'Bearer attacker',
        'x-abto-key-openai': 'sk-attacker',
        'x-abto-device-id': 'attacker-device',
      },
    });

    await gatewayFetch(request);

    expect(capturedHeaders?.get('x-client-header')).toBe('preserved');
    expect(capturedHeaders?.get('authorization')).toBe('Bearer abto-test');
    expect(capturedHeaders?.get('x-abto-key-openai')).toBe('sk-trusted');
    expect(capturedHeaders?.get('x-abto-device-id')).toBe('trusted-device');
  });

  it('requires gatewayBaseURL instead of accepting the legacy baseURL alias', async () => {
    await expect(
      createAbtoOpenAI({
        baseURL: 'https://gateway.abto.app/v1',
        abtoApiKey: 'abto-test',
      } as unknown as Parameters<typeof createAbtoOpenAI>[0]),
    ).rejects.toThrow('requires gatewayBaseURL.');
  });
});
