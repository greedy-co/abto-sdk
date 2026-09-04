import type {
  AIInteractionType,
  AIPromptSubmittedProps,
  AIResponseInteractedProps,
  AIResponseRenderedProps,
  AutocaptureEventType,
  AutocaptureProps,
  CaptureMode,
  DeadClickProps,
  Environment,
  PageleaveProps,
  PageviewProps,
  RageclickProps,
  ResponseCaptureMode,
  ScrollDepthProps,
  SensitiveCategory as ContractSensitiveCategory,
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
  Environment,
  ScrollDepthProps,
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
export type MaskMode = 'off' | 'sensitive' | 'all';

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

export interface CapturedEvent {
  uuid: string;
  event: string;
  timestamp: string;
  distinct_id: string;
  properties: CustomEventProperties;
}

export interface AbtoBrowserConfig<R extends EventRegistry = EventRegistry> {
  projectKey: string;
  apiHost?: string;
  environment?: Environment;
  appVersion?: string;
  events?: R;
  capture?: {
    prompt?: CaptureMode;
    response?: ResponseCaptureMode;
    /** Raw DOM text/value is masked by default. Use data-abto-include for explicit opt-in. */
    mask?: MaskMode;
  };
  autocapture?: {
    /** Broad page and DOM collection is opt-in and disabled by default. */
    enabled?: boolean;
  };
}

export interface ResolvedConfig<R extends EventRegistry = EventRegistry> {
  endpoint: string;
  projectKey: string;
  environment: Environment;
  appVersion: string | undefined;
  events: R;
  capturePrompt: CaptureMode;
  captureResponse: ResponseCaptureMode;
  mask: MaskMode;
  autocapture: boolean;
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
  feature_id?: string;
  trace_id?: string;
  request_id?: string;
  response_id?: string;
  surface?: string;
  conversation_id?: string;
  message_id?: string;
  prompt_template_id?: string;
}

export interface TraceHeaders {
  'x-abto-device-id': string;
  /**
   * Raw trace id for the browser-to-backend hop.
   * Optional: the Gateway does not read it yet, so `getHeaders()` omits it.
   */
  'x-abto-trace-id'?: string;
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
  responseCaptureMode?: ResponseCaptureMode;
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
  readonly requestId?: string;
  getHeaders(): TraceHeaders;
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
