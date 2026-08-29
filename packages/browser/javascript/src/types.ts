import type {
  AIInteractionType,
  AIPromptSubmittedProps,
  AIResponseInteractedProps,
  AIResponseRenderedProps,
  AutocaptureEventType,
  AutocaptureProps,
  CaptureMode,
  DeadClickProps,
  DerivedTextMeta,
  Environment,
  MaskMode,
  PageleaveProps,
  PageviewProps,
  RageclickProps,
  ScrollDepthProps,
  SensitiveCategory as ContractSensitiveCategory,
  TokenBucket,
} from './events.generated.js';
import type {
  CustomEventPayloadMap,
  EventRegistry,
  InferCustomEventProperties,
} from './event-registry.js';
import {
  ABTO_AI_INTERACTION_TYPES,
  ABTO_SCHEMA_VERSION,
  BROWSER_SYSTEM_EVENTS,
  BROWSER_SYSTEM_EVENT_WIRE_NAMES,
  isAIInteractionType,
  type BrowserSystemEventName,
  type BrowserSystemEventWireName,
} from './system-events.generated.js';

export type {
  AIInteractionType,
  AutocaptureEventType,
  CaptureMode,
  DerivedTextMeta,
  Environment,
  MaskMode,
  ScrollDepthProps,
  TokenBucket,
  EventRegistry,
  InferCustomEventProperties,
};
export {
  ABTO_AI_INTERACTION_TYPES,
  ABTO_SCHEMA_VERSION,
  BROWSER_SYSTEM_EVENTS,
  BROWSER_SYSTEM_EVENT_WIRE_NAMES,
  isAIInteractionType,
  type BrowserSystemEventName,
  type BrowserSystemEventWireName,
};
export type SensitiveCategory = ContractSensitiveCategory | null;

export interface BrowserSystemEventPropsMap {
  $pageview: PageviewProps;
  $pageleave: PageleaveProps;
  $autocapture: AutocaptureProps;
  $rageclick: RageclickProps;
  $dead_click: DeadClickProps;
  $ai_prompt_submitted: AIPromptSubmittedProps;
  $ai_response_rendered: AIResponseRenderedProps;
  $ai_response_interacted: AIResponseInteractedProps;
}

export type JsonScalar = string | number | boolean | null;
export type JsonValue = JsonScalar | JsonScalar[] | Record<string, JsonScalar>;
export type CustomEventProperties = Record<string, JsonValue>;

export interface CapturedEvent<E extends string = string> {
  uuid: string;
  event: E;
  timestamp: string;
  distinct_id: string;
  properties: CustomEventProperties;
  set?: CustomEventProperties;
  set_once?: CustomEventProperties;
}

export interface AbtoBrowserConfig<R extends EventRegistry = EventRegistry> {
  projectKey: string;
  apiHost?: string;
  endpoint?: string;
  environment?: Environment;
  appVersion?: string;
  events?: R;
  debug?: boolean;
  capture?: {
    prompt?: CaptureMode;
    response?: CaptureMode;
    /** Raw DOM text/value is masked by default. Use data-abto-include for explicit opt-in. */
    mask?: MaskMode;
  };
  autocapture?: {
    /** Broad page and DOM collection is opt-in and disabled by default. */
    enabled?: boolean;
  };
  export?: {
    flushIntervalMs?: number;
    maxBatchSize?: number;
    disabled?: boolean;
  };
  identity?: {
    sessionIdleMs?: number;
    sessionMaxAgeMs?: number;
  };
  hashSalt?: string;
}

export interface ResolvedConfig<R extends EventRegistry = EventRegistry> {
  endpoint: string;
  apiKey: string;
  projectKey: string;
  apiHost: string;
  environment: Environment;
  appVersion: string;
  events: R;
  debug: boolean;
  capturePrompt: CaptureMode;
  captureResponse: CaptureMode;
  mask: MaskMode;
  autocapture: boolean;
  batchSize: number;
  flushIntervalMs: number;
  sessionIdleMs: number;
  sessionMaxAgeMs: number;
  disabled: boolean;
  hashSalt: string;
}

/** Internal context keys are converted to `$` wire properties by the client. */
export interface CommonProperties {
  tenant_id?: string;
  user_id?: string;
  device_id?: string;
  anonymous_id?: string;
  session_id?: string;
  window_id?: string;
  pageview_id?: string;
  node_key?: string;
  trace_id?: string;
  request_id?: string;
  response_id?: string;
  surface?: string;
  task_type?: string;
  entry_point?: string;
  conversation_id?: string;
  message_id?: string;
  prompt_template_id?: string;
}

export interface StartLlmTraceOptions {
  nodeId: string;
  taskType?: string;
  surface?: string;
  entryPoint?: string;
  traceId?: string;
  conversationId?: string;
  messageId?: string;
  promptTemplateId?: string;
}

export interface PromptMetadata {
  promptCaptureMode?: CaptureMode;
  prompt?: string;
  promptHash?: string;
  promptLengthChars?: number;
  promptTokensEstimated?: number;
  language?: string;
  containsAttachment?: boolean;
  containsCode?: boolean;
  piiDetected?: boolean;
  sensitiveCategory?: SensitiveCategory | SensitiveCategory[];
}

export interface ResponseRenderedMetadata {
  responseId: string;
  requestId?: string;
  responseCaptureMode?: CaptureMode;
  responseText?: string;
  timeToRenderMs?: number;
  outputLengthChars?: number;
  visibleOutputRatio?: number;
}

export interface ResponseInteractionMetadata {
  responseId?: string;
  requestId?: string;
  source?: string;
  destination?: string;
  timeSinceResponseMs?: number;
  visibleOutputRatio?: number;
}

export type RequestIdHeaders =
  | Headers
  | { get(name: string): string | null | undefined }
  | Record<string, string | null | undefined>;

export type RequestIdSource =
  | string
  | null
  | undefined
  | RequestIdHeaders
  | { headers: RequestIdHeaders };

export interface LlmTrace {
  readonly traceId: string;
  readonly nodeId: string;
  readonly taskType?: string;
  readonly requestId?: string;
  getHeaders(): Record<string, string | undefined>;
  setRequestId(requestId: string): this;
  attachRequestId(source: RequestIdSource): string | undefined;
  submitPrompt(metadata?: PromptMetadata): Promise<void>;
  markResponseRendered(metadata: ResponseRenderedMetadata): Promise<void>;
  captureResponseInteraction(
    type: AIInteractionType,
    metadata?: ResponseInteractionMetadata,
  ): Promise<void>;
}

export type EventNameFor<R extends EventRegistry> = Extract<keyof R, string>;
export type EventPropertiesFor<
  R extends EventRegistry,
  N extends EventNameFor<R>,
> = CustomEventPayloadMap<R>[N];
