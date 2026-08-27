/**
 * @abto-app/event — public entry point.
 *
 * Browser SDK for LLM semantic event capture.
 * Manual capture by default; hosts explicitly opt into masked autocapture when needed.
 */

// Primary API.
export {
  AbtoBrowserClient,
  initAbto,
  startLlmTrace,
  identify,
  reset,
  forgetDevice,
  getIdentity,
  setNode,
  getTraceHeaders,
  flush,
} from './client.js';

export {
  defineEvents,
  validateEventProperties,
  type CustomEventDefinition,
  type CustomEventPayloadMap,
  type CustomPropertyDefinition,
  type EventRegistry,
  type InferCustomEventProperties,
} from './event-registry.js';

// Context helpers (trace id generation, header building).
export {
  ContextStore,
  newTraceId,
  newSpanId,
  newEventId,
  toTraceparent,
  type TraceHeaders,
} from './context.js';

export { type BrowserIdentity } from './identity.js';

// Privacy primitives (so hosts can derive metadata themselves before capture).
export {
  deriveTextMeta,
  saltedHash,
  tokenBucket,
  estimateTokens,
  resolveDomPolicy,
  NO_CAPTURE_ATTR,
  SENSITIVE_ATTR,
  INCLUDE_ATTR,
  type DeriveOptions,
  type DomCapturePolicy,
} from './privacy.js';

// Autocapture (for advanced hosts wiring their own sink).
export {
  installAutocapture,
  actionToInteraction,
  ATTR,
  type AutocaptureHit,
  type AutocaptureSink,
  type InteractionHit,
  type PageviewHit,
  type CapturedElement,
  type SemanticTarget,
} from './autocapture.js';

// elements_chain serialization (backbone for broad autocapture).
export { serializeElementsChain, elementText } from './elements-chain.js';

// Transport (exported mainly for typing / advanced use).
export { Transport } from './transport.js';

// Types.
export * from './types.js';
