/** OpenAI client factory wired for the ABTO Gateway. */

import { getAbtoContext, getAbtoHeaders, type AbtoContext } from './context.js';
import {
  resolveProviderHeaders,
  type ProviderKeys,
} from './credentials.js';

export interface OpenAIDirectFallbackOptions {
  /** Defaults to true when an OpenAI provider key source is configured. */
  enabled?: boolean;
  /** How long to wait for a Gateway response. Defaults to 30 seconds. */
  timeoutMs?: number;
  /** Whether to retry the current timed-out request through the direct path. Defaults to false to avoid duplicate execution. */
  onTimeout?: boolean;
}

export type OpenAIDirectFallbackConfig =
  | boolean
  | OpenAIDirectFallbackOptions;

export interface CreateAbtoOpenAIOptions {
  /** ABTO Gateway base URL, e.g. https://gateway.abto.app/v1. */
  gatewayBaseURL?: string;
  /** ABTO API key. Gateway maps this to account and project. */
  abtoApiKey?: string;
  /** Provider credentials forwarded to the Gateway for routed egress. */
  providerKeys?: ProviderKeys;
  /** OpenAI direct fallback settings for Gateway failures that can be identified safely. */
  fallback?: OpenAIDirectFallbackConfig;
  getContext?: () => AbtoContext | undefined;
  /**
   * Official OpenAI client options. ABTO owns baseURL, apiKey, and the outer
   * fetch wrapper; a caller-provided fetch is used as that wrapper's transport.
   */
  clientOptions?: Record<string, unknown>;
}

type FetchInit = RequestInit & Record<string, unknown>;

type FetchLike = (
  input: string | URL | Request,
  init?: FetchInit,
) => Promise<Response>;

export interface CreateGatewayFetchOptions {
  gatewayBaseURL: string;
  abtoApiKey: string;
  providerKeys?: ProviderKeys;
  fallback?: OpenAIDirectFallbackConfig;
  getContext?: () => AbtoContext | undefined;
  fetchImpl?: FetchLike;
}

export interface BuildOpenAIClientOptions {
  gatewayBaseURL: string;
  abtoApiKey: string;
  fetch: FetchLike;
  clientOptions?: Record<string, unknown>;
}

export interface OpenAIFallbackCircuit {
  openedAt?: number;
  halfOpenInFlight: boolean;
}

interface ResolvedFallback {
  enabled: boolean;
  timeoutMs: number;
  onTimeout: boolean;
}

const OPENAI_BASE_URL = new URL('https://api.openai.com/v1/');
const CIRCUIT_OPEN_MS = 30_000;
const DIRECT_HEADER_NAMES = new Set([
  'accept',
  'content-type',
  'idempotency-key',
  'user-agent',
]);
const SAFE_CONNECT_ERROR_CODES = new Set([
  'CERT_HAS_EXPIRED',
  'DEPTH_ZERO_SELF_SIGNED_CERT',
  'EAI_AGAIN',
  'ECONNREFUSED',
  'ENETUNREACH',
  'ENOTFOUND',
  'ERR_SOCKET_CONNECTION_TIMEOUT',
  'ERR_TLS_CERT_ALTNAME_INVALID',
  'HOSTNAME_MISMATCH',
  'SELF_SIGNED_CERT_IN_CHAIN',
  'UNABLE_TO_GET_ISSUER_CERT',
  'UNABLE_TO_GET_ISSUER_CERT_LOCALLY',
  'UNABLE_TO_VERIFY_LEAF_SIGNATURE',
  'UND_ERR_CONNECT_TIMEOUT',
]);
const SAFE_TLS_ERROR_PREFIXES = ['CERT_', 'ERR_SSL_', 'ERR_TLS_'];

export function createOpenAIFallbackCircuit(): OpenAIFallbackCircuit {
  return { halfOpenInFlight: false };
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

function positiveTimeout(value: number | undefined): number {
  const resolved = value ?? 30_000;
  if (!Number.isFinite(resolved) || resolved <= 0) {
    throw new Error('[abto] fallback.timeoutMs must be greater than 0.');
  }
  return resolved;
}

function resolveFallback(
  config: OpenAIDirectFallbackConfig | undefined,
  hasOpenAIKeySource: boolean,
): ResolvedFallback {
  const options = typeof config === 'object' ? config : {};
  return {
    enabled: typeof config === 'boolean'
      ? config
      : options.enabled ?? hasOpenAIKeySource,
    timeoutMs: positiveTimeout(options.timeoutMs),
    onTimeout: options.onTimeout ?? false,
  };
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

function requestBody(request: Request): Promise<ArrayBuffer | undefined> {
  if (request.method === 'GET' || request.method === 'HEAD') {
    return Promise.resolve(undefined);
  }
  return request.clone().arrayBuffer();
}

function requestInitWithBody(
  source: Request,
  body: ArrayBuffer | undefined,
  headers: Headers,
  init?: FetchInit,
  signal: AbortSignal = source.signal,
): FetchInit {
  return {
    cache: source.cache,
    credentials: source.credentials,
    integrity: source.integrity,
    keepalive: source.keepalive,
    mode: source.mode,
    referrer: source.referrer,
    referrerPolicy: source.referrerPolicy,
    ...init,
    method: source.method,
    headers,
    body: body?.slice(0),
    redirect: 'manual',
    signal,
  };
}

function requestInitWithStream(
  source: Request,
  headers: Headers,
  init?: FetchInit,
): FetchInit {
  return {
    cache: source.cache,
    credentials: source.credentials,
    integrity: source.integrity,
    keepalive: source.keepalive,
    mode: source.mode,
    referrer: source.referrer,
    referrerPolicy: source.referrerPolicy,
    ...init,
    method: source.method,
    headers,
    body: source.method === 'GET' || source.method === 'HEAD'
      ? undefined
      : source.body,
    ...(source.body === null ? {} : { duplex: init?.duplex ?? 'half' }),
    redirect: 'manual',
    signal: source.signal,
  };
}

function directOpenAIURL(destination: URL, gatewayBaseURL: URL): URL | undefined {
  const basePath = gatewayBaseURL.pathname.replace(/\/?$/, '/');
  if (!destination.pathname.startsWith(basePath)) return undefined;
  const suffix = destination.pathname.slice(basePath.length);
  if (suffix !== 'chat/completions') return undefined;
  const direct = new URL(suffix, OPENAI_BASE_URL);
  direct.search = destination.search;
  return direct;
}

function causeCode(error: unknown): string | undefined {
  let current = error;
  for (let depth = 0; depth < 4 && current instanceof Error; depth += 1) {
    const code = (current as Error & { code?: unknown }).code;
    if (typeof code === 'string') return code;
    current = (current as Error & { cause?: unknown }).cause;
  }
  return undefined;
}

function isSafeConnectFailure(error: unknown): boolean {
  const code = causeCode(error);
  return code !== undefined
    && (
      SAFE_CONNECT_ERROR_CODES.has(code)
      || SAFE_TLS_ERROR_PREFIXES.some((prefix) => code.startsWith(prefix))
    );
}

function isTimeoutFailure(error: unknown, timedOut: boolean): boolean {
  return timedOut
    || (error instanceof Error && error.name === 'TimeoutError');
}

function isSafeGatewayResponse(response: Response): boolean {
  const requestId = response.headers.get('x-abto-request-id');
  const errorSource = response.headers.get('x-abto-error-source');
  if (
    requestId === null
    && (response.status === 502 || response.status === 503 || response.status === 504)
  ) {
    return true;
  }
  return response.status === 503 && requestId !== null && errorSource === null;
}

function directHeaders(source: Headers, openAIKey: string): Headers {
  const headers = new Headers();
  source.forEach((value, key) => {
    const normalized = key.toLowerCase();
    if (
      DIRECT_HEADER_NAMES.has(normalized)
      || normalized.startsWith('openai-')
      || normalized.startsWith('x-stainless-')
    ) {
      headers.set(key, value);
    }
  });
  headers.set('Authorization', `Bearer ${openAIKey}`);
  return headers;
}

function observeResponseBody(
  response: Response,
  {
    onComplete,
    onError,
    onCancel,
  }: {
    onComplete: () => void;
    onError: () => void;
    onCancel: () => void;
  },
): Response {
  if (response.body === null) {
    onComplete();
    return response;
  }

  const reader = response.body.getReader();
  let settled = false;
  const settle = (callback: () => void): void => {
    if (settled) return;
    settled = true;
    callback();
  };
  const body = new ReadableStream<Uint8Array>({
    async pull(controller) {
      try {
        const chunk = await reader.read();
        if (chunk.done) {
          settle(onComplete);
          controller.close();
        } else {
          controller.enqueue(chunk.value);
        }
      } catch (error) {
        settle(onError);
        controller.error(error);
      }
    },
    async cancel(reason) {
      settle(onCancel);
      await reader.cancel(reason);
    },
  });
  const observed = new Response(body, {
    status: response.status,
    statusText: response.statusText,
    headers: response.headers,
  });
  Object.defineProperties(observed, {
    url: { value: response.url },
    redirected: { value: response.redirected },
    type: { value: response.type },
  });
  return observed;
}

export function createGatewayFetch({
  gatewayBaseURL,
  abtoApiKey,
  providerKeys = {},
  fallback,
  getContext = getAbtoContext,
  fetchImpl = fetch as FetchLike,
}: CreateGatewayFetchOptions, circuit = createOpenAIFallbackCircuit()): FetchLike {
  const gatewayURL = requireGatewayURL(gatewayBaseURL);
  const resolvedFallback = resolveFallback(
    fallback,
    providerKeys.openai !== undefined,
  );

  const openCircuit = (): void => {
    circuit.openedAt = performance.now();
    circuit.halfOpenInFlight = false;
  };
  const closeCircuit = (): void => {
    circuit.openedAt = undefined;
    circuit.halfOpenInFlight = false;
  };
  const releaseHalfOpenProbe = (): void => {
    circuit.halfOpenInFlight = false;
  };

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

    const original = input instanceof Request
      ? new Request(input, init)
      : new Request(destination, init);
    const directURL = directOpenAIURL(destination, gatewayURL);
    const openAIKey = providerHeaders['X-Abto-Key-openai'];
    const eligible = resolvedFallback.enabled
      && directURL !== undefined
      && original.method === 'POST';
    const directAvailable = eligible && openAIKey !== undefined;

    if (!eligible) {
      return fetchImpl(
        destination,
        requestInitWithStream(original, headers, init),
      );
    }

    if (!directAvailable) {
      try {
        const response = await fetchImpl(
          destination,
          requestInitWithStream(original, headers, init),
        );
        if (isSafeGatewayResponse(response)) {
          openCircuit();
          return response;
        }
        closeCircuit();
        return observeResponseBody(response, {
          onComplete: () => undefined,
          onError: releaseHalfOpenProbe,
          onCancel: () => undefined,
        });
      } catch (error) {
        if (original.signal.aborted) {
          releaseHalfOpenProbe();
        } else if (isSafeConnectFailure(error)) {
          openCircuit();
        } else {
          releaseHalfOpenProbe();
        }
        throw error;
      }
    }

    const body = await requestBody(original);
    const requestInit = requestInitWithBody(original, body, headers, init);

    const sendDirect = async (): Promise<Response> => {
      if (directURL === undefined || openAIKey === undefined) {
        throw new Error('[abto] OpenAI direct fallback is unavailable.');
      }
      const headersForDirect = directHeaders(headers, openAIKey);
      return fetchImpl(
        directURL,
        requestInitWithBody(original, body, headersForDirect, init),
      );
    };

    if (circuit.openedAt !== undefined) {
      if (
        performance.now() - circuit.openedAt < CIRCUIT_OPEN_MS
        || circuit.halfOpenInFlight
      ) {
        return sendDirect();
      }
      circuit.halfOpenInFlight = true;
    }

    const controller = new AbortController();
    let timedOut = false;
    const callerSignal = original.signal;
    const abortFromCaller = (): void => controller.abort(callerSignal.reason);
    const cleanupGatewaySignal = (): void => {
      callerSignal.removeEventListener('abort', abortFromCaller);
    };
    if (callerSignal.aborted) abortFromCaller();
    else callerSignal.addEventListener('abort', abortFromCaller, { once: true });
    const timer = setTimeout(() => {
      timedOut = true;
      controller.abort(new DOMException('Gateway request timed out.', 'TimeoutError'));
    }, resolvedFallback.timeoutMs);

    try {
      const response = await fetchImpl(destination, {
        ...requestInit,
        signal: controller.signal,
      });
      clearTimeout(timer);
      if (isSafeGatewayResponse(response)) {
        cleanupGatewaySignal();
        await response.body?.cancel();
        openCircuit();
        return sendDirect();
      }
      closeCircuit();
      return observeResponseBody(response, {
        onComplete: cleanupGatewaySignal,
        onError: () => {
          cleanupGatewaySignal();
          releaseHalfOpenProbe();
        },
        onCancel: () => {
          cleanupGatewaySignal();
          releaseHalfOpenProbe();
        },
      });
    } catch (error) {
      clearTimeout(timer);
      cleanupGatewaySignal();
      if (callerSignal.aborted && !timedOut) {
        releaseHalfOpenProbe();
        throw error;
      }
      if (isSafeConnectFailure(error)) {
        openCircuit();
        return sendDirect();
      }
      if (isTimeoutFailure(error, timedOut)) {
        if (resolvedFallback.onTimeout) {
          openCircuit();
          return sendDirect();
        }
      }
      releaseHalfOpenProbe();
      throw error;
    }
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
    fetch,
  };
}

export async function createAbtoOpenAIWithCircuit<T = unknown>(
  options: CreateAbtoOpenAIOptions = {},
  circuit = createOpenAIFallbackCircuit(),
): Promise<T> {
  const {
    gatewayBaseURL,
    abtoApiKey = getEnv('ABTO_API_KEY'),
    providerKeys = {
      openai: getEnv('OPENAI_API_KEY'),
      anthropic: getEnv('ANTHROPIC_API_KEY'),
      gemini: getEnv('GEMINI_API_KEY'),
    },
    fallback,
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
    default: new (opts: Record<string, unknown>) => unknown;
  };

  const callerFetch = clientOptions.fetch;
  if (callerFetch !== undefined && typeof callerFetch !== 'function') {
    throw new Error('[abto] clientOptions.fetch must be a function.');
  }
  const abtoFetch = createGatewayFetch({
    gatewayBaseURL: resolvedBaseURL,
    abtoApiKey,
    providerKeys,
    fallback,
    getContext,
    fetchImpl: callerFetch as FetchLike | undefined,
  }, circuit);

  return new OpenAI(
    buildOpenAIClientOptions({
      gatewayBaseURL: resolvedBaseURL,
      abtoApiKey,
      fetch: abtoFetch,
      clientOptions,
    }),
  ) as T;
}

export function createAbtoOpenAI<T = unknown>(
  options: CreateAbtoOpenAIOptions = {},
): Promise<T> {
  return createAbtoOpenAIWithCircuit<T>(options);
}
