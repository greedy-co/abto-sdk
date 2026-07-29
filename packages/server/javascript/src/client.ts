import {
  createTraceId,
  getAbtoContext,
  getAbtoHeaders,
  runWithAbtoContext,
  type AbtoContext,
} from './context.js';
import type { ProviderKeys } from './credentials.js';
import { createAbtoOpenAI, type CreateAbtoOpenAIOptions } from './openai.js';

export interface AbtoConfig {
  abtoApiKey?: string;
  providerKeys?: ProviderKeys;
  gatewayBaseURL?: string;
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

export interface AbtoNodeClient {
  readonly config: Omit<
    Required<Pick<AbtoConfig, 'environment'>> & AbtoConfig,
    'abtoApiKey' | 'providerKeys'
  >;
  withContext<T>(ctx: AbtoContext, fn: () => T): T;
  getContext(): AbtoContext | undefined;
  getHeaders(ctx?: AbtoContext): Record<string, string>;
  createTraceId(): string;
  openai(options?: Omit<
    CreateAbtoOpenAIOptions,
    'abtoApiKey' | 'providerKeys' | 'gatewayBaseURL'
  >): Promise<unknown>;
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
    openai(options = {}): Promise<unknown> {
      const suppliedGetContext = options.getContext;
      return createAbtoOpenAI({
        ...options,
        abtoApiKey,
        providerKeys,
        gatewayBaseURL: resolved.gatewayBaseURL,
        getContext: () => resolveContext(suppliedGetContext?.()),
      });
    },
    async flush(): Promise<void> {
      // Server SDK currently does not emit telemetry directly.
    },
    async shutdown(): Promise<void> {
      // Reserved for future queue drain / lifecycle cleanup.
    },
  };
}
