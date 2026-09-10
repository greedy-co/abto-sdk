/**
 * @abto-app/event — public entry point.
 *
 * Browser SDK for LLM semantic event capture.
 * Manual capture by default; hosts explicitly opt into masked autocapture when needed.
 */

// Primary API.
export { initAbto } from './client.js';

export {
  defineEvents,
  type CustomEventDefinition,
  type EventRegistry,
} from './event-registry.js';

export { type BrowserIdentity } from './identity.js';

export type {
  AIInteractionType,
  CaptureMode,
  CaptureOptions,
  Environment,
  MaskMode,
  SensitiveCategory,
  JsonScalar,
  JsonValue,
  CustomEventProperties,
  AbtoBrowserConfig,
  TraceHeaders,
  PromptMetadata,
  ResponseRenderedMetadata,
  ResponseInteractionMetadata,
  RequestIdHeaders,
  RequestIdSource,
  LlmTrace,
  EventNameFor,
} from './types.js';
