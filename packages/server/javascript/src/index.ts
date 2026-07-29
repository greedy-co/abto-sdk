/**
 * @abto-app/calling — thin server-side ABTO SDK helper for Node.js.
 *
 * Public surface:
 *   - context propagation (AsyncLocalStorage)
 *   - ABTO header construction
 *   - OpenAI client factory routed through the ABTO Gateway
 */

export {
  ABTO_HEADER,
  type AbtoContext,
  type BuildHeaderOptions,
  runWithAbtoContext,
  getAbtoContext,
  getAbtoHeaders,
  createTraceId,
  createTraceparent,
} from "./context.js";

export {
  initAbto,
  type AbtoConfig,
  type AbtoNodeClient,
} from "./client.js";

export {
  createAbtoOpenAI,
  type CreateAbtoOpenAIOptions,
} from "./openai.js";

export type {
  ProviderKeyName,
  ProviderKeyValue,
  ProviderKeys,
} from './credentials.js';
