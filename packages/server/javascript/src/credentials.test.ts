// @vitest-environment node

import { describe, expect, it } from 'vitest';
import { resolveProviderHeaders } from './credentials.js';

describe('provider credential headers', () => {
  it('resolves configured strings and async provider key resolvers', async () => {
    const headers = await resolveProviderHeaders({
      openai: 'sk-openai',
      anthropic: async () => 'sk-anthropic',
    });

    expect(headers).toEqual({
      'X-Abto-Key-openai': 'sk-openai',
      'X-Abto-Key-anthropic': 'sk-anthropic',
    });
  });

  it('omits missing and blank provider keys', async () => {
    const headers = await resolveProviderHeaders({
      openai: () => undefined,
      anthropic: '   ',
    });

    expect(headers).toEqual({});
  });

  it('rejects provider keys containing line breaks', async () => {
    await expect(
      resolveProviderHeaders({ openai: 'sk-safe\r\nX-Leaked: value' }),
    ).rejects.toThrow('Provider key for openai contains invalid characters.');
  });
});
