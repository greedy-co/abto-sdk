import { ERR_PROVIDER_KEY_INVALID_CHARACTERS } from './policy.generated.js';
export type { ProviderKeyName } from './policy.generated.js';
import { PROVIDER_IDS, type ProviderKeyName } from './policy.generated.js';

export type ProviderKeyValue =
  | string
  | (() => string | undefined | Promise<string | undefined>);

export type ProviderKeys = Partial<Record<ProviderKeyName, ProviderKeyValue>>;

/**
 * Default provider keys, read from `<PROVIDER>_API_KEY` for every provider the Gateway accepts.
 * Derived from the generated id list so a new provider needs no edit here.
 */
export function providerKeysFromEnv(
  getEnv: (name: string) => string | undefined,
): ProviderKeys {
  const keys: ProviderKeys = {};
  for (const provider of PROVIDER_IDS) {
    keys[provider] = getEnv(`${provider.toUpperCase()}_API_KEY`);
  }
  return keys;
}

export async function resolveProviderHeaders(
  keys: ProviderKeys = {},
): Promise<Record<string, string>> {
  const headers: Record<string, string> = {};

  for (const provider of PROVIDER_IDS) {
    const source = keys[provider];
    const value = typeof source === 'function' ? await source() : source;
    const trimmed = value?.trim();
    if (!trimmed) continue;
    if (/[\r\n]/.test(trimmed)) {
      throw new Error(ERR_PROVIDER_KEY_INVALID_CHARACTERS.replace('{provider}', provider));
    }
    headers[`X-Abto-Key-${provider}`] = trimmed;
  }

  return headers;
}
