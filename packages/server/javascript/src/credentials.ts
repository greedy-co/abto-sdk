export type { ProviderKeyName } from './policy.generated.js';
import { PROVIDER_IDS, type ProviderKeyName } from './policy.generated.js';

export type ProviderKeyValue =
  | string
  | (() => string | undefined | Promise<string | undefined>);

export type ProviderKeys = Partial<Record<ProviderKeyName, ProviderKeyValue>>;

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
      throw new Error(`Provider key for ${provider} contains invalid characters.`);
    }
    headers[`X-Abto-Key-${provider}`] = trimmed;
  }

  return headers;
}
