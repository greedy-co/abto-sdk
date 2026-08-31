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
 *   - node_key -> header `x-abto-node-key`  (required by the gateway). "feature.node"
 *                 dot notation, e.g. "resume.make"; feature is the read-time prefix.
 *   - trace_id -> W3C `traceparent`. End-user action bundle; gateway-deferred (Round1).
 *
 * request_id (PK, returned as `x-abto-request-id`), tenant_id (from API key), and
 * variant_id (A/B assignment) are gateway-owned and are NOT sent by the SDK.
 */

import { AsyncLocalStorage } from "node:async_hooks";
import { newUuidV7TraceId, randomHex } from './uuid.js';

/** Gateway-facing header names. Only what the gateway reads. */
export const ABTO_HEADER = {
  deviceId: "x-abto-device-id",
  nodeKey: "x-abto-node-key",
  traceparent: "traceparent",
} as const;

export interface AbtoContext {
  /** Device id. Sent as `x-abto-device-id` (optional for the gateway). */
  deviceId?: string;
  /** "feature.node" dot-notation node key (e.g. "resume.make"). Sent as `x-abto-node-key`. */
  nodeKey?: string;
  /** End-user action bundle id. Sent as W3C `traceparent`. Gateway-deferred. */
  traceId?: string;
}

export interface BuildHeaderOptions {
  /** Emit a W3C traceparent derived from traceId. Defaults to true when traceId is set. */
  includeTraceparent?: boolean;
}

const storage = new AsyncLocalStorage<AbtoContext>();

/** 32-hex-char trace id, per W3C trace-context. */
export function createTraceId(): string {
  return newUuidV7TraceId();
}

/** Build a W3C `traceparent` value for the given trace id. */
export function createTraceparent(traceId: string): string {
  return `00-${traceId}-${randomHex(8)}-01`;
}

export function runWithAbtoContext<T>(ctx: AbtoContext, fn: () => T): T {
  const parent = storage.getStore();
  const merged: AbtoContext = { ...parent, ...ctx };
  return storage.run(merged, fn);
}

export function getAbtoContext(): AbtoContext | undefined {
  return storage.getStore();
}

export function getAbtoHeaders(
  ctx?: AbtoContext,
  options: BuildHeaderOptions = {},
): Record<string, string> {
  const c = ctx ?? storage.getStore() ?? {};
  const headers: Record<string, string> = {};
  if (c.deviceId) headers[ABTO_HEADER.deviceId] = c.deviceId;
  if (c.nodeKey) headers[ABTO_HEADER.nodeKey] = c.nodeKey;
  if (c.traceId && (options.includeTraceparent ?? true)) {
    headers[ABTO_HEADER.traceparent] = createTraceparent(c.traceId);
  }
  return headers;
}
