/** OpenAI client factory wired for the ABTO Gateway. */

import { getAbtoContext, getAbtoHeaders, type AbtoContext } from './context.js';
import {
  resolveProviderHeaders,
  type ProviderKeys,
} from './credentials.js';

export interface CreateAbtoOpenAIOptions {
  /** ABTO Gateway base URL, e.g. https://gateway.abto.app/v1. */
  gatewayBaseURL?: string;
  /** ABTO API key. Gateway maps this to account and project. */
  abtoApiKey?: string;
  /** Provider credentials forwarded to the Gateway for routed egress. */
  providerKeys?: ProviderKeys;
  getContext?: () => AbtoContext | undefined;
  clientOptions?: Record<string, unknown>;
}

type OpenAILike = unknown;

type FetchLike = (
  input: string | URL | Request,
  init?: RequestInit,
) => Promise<Response>;

export interface CreateGatewayFetchOptions {
  gatewayBaseURL: string;
  abtoApiKey: string;
  providerKeys?: ProviderKeys;
  getContext?: () => AbtoContext | undefined;
  fetchImpl?: FetchLike;
}

export interface BuildOpenAIClientOptions {
  gatewayBaseURL: string;
  abtoApiKey: string;
  fetch: FetchLike;
  clientOptions?: Record<string, unknown>;
}

function getEnv(name: string): string | undefined {
  return typeof process === 'undefined' ? undefined : process.env[name];
}

function requireGatewayURL(value: string): URL {
  let parsed: URL;
  try {
    parsed = new URL(value);
  } catch {
    throw new Error('[abto] gatewayBaseURL must be a valid http(s) URL.');
  }
  if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:') {
    throw new Error('[abto] gatewayBaseURL must be a valid http(s) URL.');
  }
  return parsed;
}

function requestURL(input: string | URL | Request, baseURL: URL): URL {
  const value = input instanceof Request ? input.url : input.toString();
  try {
    return new URL(value, baseURL);
  } catch {
    throw new Error('[abto] Gateway request URL is invalid.');
  }
}

function trustedBaseHeaders(input: string | URL | Request, init?: RequestInit): Headers {
  const headers = new Headers(input instanceof Request ? input.headers : undefined);
  new Headers(init?.headers).forEach((value, key) => headers.set(key, value));
  for (const key of Array.from(headers.keys())) {
    const normalized = key.toLowerCase();
    if (
      normalized === 'authorization'
      || normalized === 'x-abto-device-id'
      || normalized === 'x-abto-node-key'
      || normalized === 'traceparent'
      || normalized.startsWith('x-abto-key-')
    ) {
      headers.delete(key);
    }
  }
  return headers;
}

export function createGatewayFetch({
  gatewayBaseURL,
  abtoApiKey,
  providerKeys = {},
  getContext = getAbtoContext,
  fetchImpl = fetch as FetchLike,
}: CreateGatewayFetchOptions): FetchLike {
  const gatewayURL = requireGatewayURL(gatewayBaseURL);
  return async (input, init) => {
    const destination = requestURL(input, gatewayURL);
    if (destination.origin !== gatewayURL.origin) {
      throw new Error('[abto] Refusing to send credentials outside the configured Gateway origin.');
    }
    const trimmedAbtoApiKey = abtoApiKey.trim();
    if (!trimmedAbtoApiKey) {
      throw new Error('ABTO API key is required.');
    }
    if (/[\r\n]/.test(trimmedAbtoApiKey)) {
      throw new Error('ABTO API key contains invalid characters.');
    }
    const headers = trustedBaseHeaders(input, init);
    const providerHeaders = await resolveProviderHeaders(providerKeys);
    for (const [key, value] of Object.entries(providerHeaders)) {
      headers.set(key, value);
    }
    for (const [key, value] of Object.entries(getAbtoHeaders(getContext()))) {
      headers.set(key, value);
    }
    headers.set('Authorization', `Bearer ${trimmedAbtoApiKey}`);
    return fetchImpl(input, { ...init, headers, redirect: 'manual' });
  };
}

export function buildOpenAIClientOptions({
  gatewayBaseURL,
  abtoApiKey,
  fetch,
  clientOptions = {},
}: BuildOpenAIClientOptions): Record<string, unknown> {
  return {
    ...clientOptions,
    baseURL: gatewayBaseURL,
    apiKey: abtoApiKey,
    maxRetries: 0,
    fetch,
  };
}

export async function createAbtoOpenAI(
  options: CreateAbtoOpenAIOptions = {},
): Promise<OpenAILike> {
  const {
    gatewayBaseURL,
    abtoApiKey = getEnv('ABTO_API_KEY'),
    providerKeys = {
      openai: getEnv('OPENAI_API_KEY'),
      anthropic: getEnv('ANTHROPIC_API_KEY'),
      gemini: getEnv('GEMINI_API_KEY'),
    },
    getContext = getAbtoContext,
    clientOptions = {},
  } = options;
  const resolvedBaseURL = gatewayBaseURL ?? getEnv('ABTO_GATEWAY_BASE_URL');
  if (!resolvedBaseURL) {
    throw new Error('[abto] createAbtoOpenAI requires gatewayBaseURL.');
  }
  if (!abtoApiKey) {
    throw new Error('[abto] createAbtoOpenAI requires abtoApiKey.');
  }
  requireGatewayURL(resolvedBaseURL);

  const specifier: string = 'openai';
  const { default: OpenAI } = (await import(specifier)) as {
    default: new (opts: Record<string, unknown>) => OpenAILike;
  };

  const abtoFetch = createGatewayFetch({
    gatewayBaseURL: resolvedBaseURL,
    abtoApiKey,
    providerKeys,
    getContext,
  });

  return new OpenAI(
    buildOpenAIClientOptions({
      gatewayBaseURL: resolvedBaseURL,
      abtoApiKey,
      fetch: abtoFetch,
      clientOptions,
    }),
  );
}
