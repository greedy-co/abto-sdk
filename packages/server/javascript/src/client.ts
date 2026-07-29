import {
  createTraceId,
  getAbtoContext,
  getAbtoHeaders,
  runWithAbtoContext,
  type AbtoContext,
} from './context.js';
import type { ProviderKeys } from './credentials.js';
import {
  createAbtoOpenAIWithCircuit,
  createOpenAIFallbackCircuit,
  type CreateAbtoOpenAIOptions,
  type OpenAIDirectFallbackConfig,
} from './openai.js';

export interface AbtoConfig {
  abtoApiKey?: string;
  providerKeys?: ProviderKeys;
  gatewayBaseURL?: string;
  /** 안전하게 판별 가능한 Gateway 장애에서 사용하는 OpenAI direct fallback 설정입니다. */
  fallback?: OpenAIDirectFallbackConfig;
  /** Default device key when a request context does not provide one. */
  deviceId?: string;
  environment?: 'development' | 'staging' | 'production';
  serviceName?: string;
  export?: {
    flushIntervalMs?: number;
    maxBatchSize?: number;
    disabled?: boolean;
  };
}

type AbtoOpenAIOptions = Omit<
  CreateAbtoOpenAIOptions,
  'abtoApiKey' | 'providerKeys' | 'gatewayBaseURL'
>;

export interface AbtoNodeClient {
  readonly config: Omit<
    Required<Pick<AbtoConfig, 'environment'>> & AbtoConfig,
    'abtoApiKey' | 'providerKeys'
  >;
  withContext<T>(ctx: AbtoContext, fn: () => T): T;
  getContext(): AbtoContext | undefined;
  getHeaders(ctx?: AbtoContext): Record<string, string>;
  createTraceId(): string;
  openai<T = unknown>(options?: AbtoOpenAIOptions): Promise<T>;
  flush(): Promise<void>;
  shutdown(): Promise<void>;
}

function getEnv(name: string): string | undefined {
  return typeof process === 'undefined' ? undefined : process.env[name];
}

function nonEmpty(value: string | undefined): string | undefined {
  const trimmed = value?.trim();
  return trimmed === '' ? undefined : trimmed;
}

export function initAbto(config: AbtoConfig = {}): AbtoNodeClient {
  const runtimeConfig = config as AbtoConfig & { capture?: unknown };
  if (runtimeConfig.capture !== undefined) {
    throw new Error('[abto] capture is not supported by the current Gateway contract.');
  }
  const abtoApiKey = config.abtoApiKey ?? getEnv('ABTO_API_KEY');
  const providerKeys = config.providerKeys ?? {
    openai: getEnv('OPENAI_API_KEY'),
    anthropic: getEnv('ANTHROPIC_API_KEY'),
    gemini: getEnv('GEMINI_API_KEY'),
  };
  const {
    abtoApiKey: _abtoApiKey,
    providerKeys: _providerKeys,
    capture: _unsupportedCapture,
    ...publicInput
  } = runtimeConfig;
  const fallbackDeviceId = nonEmpty(config.deviceId) ?? nonEmpty(getEnv('ABTO_DEVICE_ID'));
  const fallbackContext: AbtoContext =
    fallbackDeviceId === undefined ? {} : { deviceId: fallbackDeviceId };
  const resolveContext = (ctx?: AbtoContext): AbtoContext => {
    const active = ctx ?? getAbtoContext();
    const { deviceId: activeDeviceId, ...activeWithoutDevice } = active ?? {};
    const deviceId = nonEmpty(activeDeviceId) ?? fallbackDeviceId;
    return {
      ...fallbackContext,
      ...activeWithoutDevice,
      ...(deviceId === undefined ? {} : { deviceId }),
    };
  };
  const resolved = {
    ...publicInput,
    environment: config.environment ?? 'production',
    export: {
      flushIntervalMs: config.export?.flushIntervalMs ?? 5000,
      maxBatchSize: config.export?.maxBatchSize ?? 50,
      disabled: config.export?.disabled ?? false,
    },
    gatewayBaseURL: config.gatewayBaseURL ?? getEnv('ABTO_GATEWAY_BASE_URL'),
    deviceId: fallbackDeviceId,
  };
  let defaultOpenAIClient: Promise<unknown> | undefined;
  const openAIFallbackCircuit = createOpenAIFallbackCircuit();

  return {
    config: resolved,
    withContext<T>(ctx: AbtoContext, fn: () => T): T {
      return runWithAbtoContext(ctx, fn);
    },
    getContext(): AbtoContext | undefined {
      const context = resolveContext();
      return Object.keys(context).length === 0 ? undefined : context;
    },
    getHeaders(ctx?: AbtoContext): Record<string, string> {
      return getAbtoHeaders(resolveContext(ctx));
    },
    createTraceId,
    openai<T = unknown>(options: AbtoOpenAIOptions = {}): Promise<T> {
      const suppliedGetContext = options.getContext;
      const createClient = (): Promise<T> => createAbtoOpenAIWithCircuit<T>(
        {
          ...options,
          abtoApiKey,
          providerKeys,
          gatewayBaseURL: resolved.gatewayBaseURL,
          fallback: options.fallback ?? config.fallback,
          getContext: () => resolveContext(suppliedGetContext?.()),
        },
        openAIFallbackCircuit,
      );
      if (Object.keys(options).length !== 0) {
        return createClient();
      }
      defaultOpenAIClient ??= createClient();
      return defaultOpenAIClient as Promise<T>;
    },
    async flush(): Promise<void> {
      // Server SDK currently does not emit telemetry directly.
    },
    async shutdown(): Promise<void> {
      // Reserved for future queue drain / lifecycle cleanup.
    },
  };
}
