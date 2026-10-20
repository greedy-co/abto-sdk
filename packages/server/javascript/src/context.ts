import { HEADER_DEVICE_ID, HEADER_FEATURE_ID, HEADER_NODE_ID, HEADER_TRACE_ID } from './policy.generated.js';

/**
 * ABTO request context propagation for Node.js.
 *
 * Server SDK scope: thin helper only. It routes provider SDK calls through the
 * ABTO Gateway and carries the gateway identifier headers. The ABTO transport owns
 * only direct fallback for safely classified Gateway availability failures. It
 * does not classify or retry OpenAI or model-provider errors; the official OpenAI
 * SDK remains the retry authority. The Gateway remains the source of truth for
 * token, cost, latency, request_id, and variant assignment.
 *
 * Gateway identifier contract:
 *   - device_id -> header `x-abto-device-id` (optional; without it the call still
 *                 succeeds but drops out of user-level analytics and sticky assignment)
 *   - feature_id -> header `x-abto-feature-id` (required by the gateway). Feature ID,
 *                  e.g. "resume.make".
 *   - node_id -> header `x-abto-node-id` (optional). Call site inside the feature;
 *               without it the gateway uses the feature ID as the node key.
 *   - trace_id -> header `x-abto-trace-id`. One agent or workflow run; groups the calls
 *                 that run made. Headers use the explicit value, then the active scope's;
 *                 outside any scope each call opens its own run.
 *                 The gateway never reads it from W3C `traceparent`.
 *
 * request_id (PK, returned as `x-abto-request-id`), tenant_id (from API key), and
 * variant_id (A/B assignment) are gateway-owned and are NOT sent by the SDK.
 */

import { AsyncLocalStorage } from "node:async_hooks";
import { newUuidV7TraceId, randomHex } from './uuid.js';

/** Gateway-facing header names. Only what the gateway reads. */
export const ABTO_HEADER = {
  deviceId: HEADER_DEVICE_ID,
  featureId: HEADER_FEATURE_ID,
  nodeId: HEADER_NODE_ID,
  traceId: HEADER_TRACE_ID,
  traceparent: "traceparent",
} as const;

export interface AbtoContext {
  /** Device id. Sent as `x-abto-device-id` (optional for the gateway). */
  deviceId?: string;
  /** Feature ID (e.g. "resume.make"). Sent as `x-abto-feature-id`. */
  featureId?: string;
  /** Call site inside the feature (e.g. "review.draft"). Sent as `x-abto-node-id`. */
  nodeId?: string;
  /** One agent or workflow run. Sent as `x-abto-trace-id`; when absent, headers use the active scope's run or open a new one. */
  traceId?: string;
}

export interface BuildHeaderOptions {
  /** @deprecated No effect. `traceId` is sent as `x-abto-trace-id`, never as a derived `traceparent`. */
  includeTraceparent?: boolean;
}

const storage = new AsyncLocalStorage<AbtoContext>();

/** New trace id: a UUIDv7 as 32 lowercase hex characters, the same form every ABTO SDK generates. */
export function createTraceId(): string {
  return newUuidV7TraceId();
}

/**
 * Build a W3C `traceparent` value for the given trace id.
 * @deprecated The SDK no longer sends a derived `traceparent`; pass the trace id as `traceId`.
 */
export function createTraceparent(traceId: string): string {
  return `00-${traceId}-${randomHex(8)}-01`;
}

export function runWithAbtoContext<T>(ctx: AbtoContext, fn: () => T): T {
  const parent = storage.getStore();
  const merged: AbtoContext = { ...parent, ...ctx };
  // A node only has meaning inside its feature, so switching to another feature without a node drops the inherited one.
  if (ctx.featureId !== undefined && ctx.featureId !== parent?.featureId && ctx.nodeId === undefined) {
    delete merged.nodeId;
  }
  // The outermost scope opens one run; inner scopes inherit it, even when they pass an empty trace id.
  merged.traceId = ctx.traceId || parent?.traceId || createTraceId();
  return storage.run(merged, fn);
}

export function getAbtoContext(): AbtoContext | undefined {
  return storage.getStore();
}

export function getAbtoHeaders(
  ctx?: AbtoContext,
  _options: BuildHeaderOptions = {},
): Record<string, string> {
  const scope = storage.getStore();
  const c = ctx ?? scope ?? {};
  const headers: Record<string, string> = {};
  if (c.deviceId) headers[ABTO_HEADER.deviceId] = c.deviceId;
  if (c.featureId) headers[ABTO_HEADER.featureId] = c.featureId;
  if (c.nodeId) headers[ABTO_HEADER.nodeId] = c.nodeId;
  // Explicit value first, then the active scope's run; outside any scope this call is its own run.
  // Outside a scope, OpenAI SDK retries rebuild the headers, so each attempt gets its own run. Wrap the run in withContext to keep one.
  headers[ABTO_HEADER.traceId] = c.traceId || scope?.traceId || createTraceId();
  return headers;
}
