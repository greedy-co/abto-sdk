/**
 * Browser identifier context.
 *
 * Gateway-aligned identifier model:
 * - node_key: "feature.node" dot-notation dimension (e.g. "resume.make"); feature is the prefix.
 * - trace_id: one user action/task execution. Carried as W3C `traceparent`.
 * - request_id: gateway-issued call PK (returned as `x-abto-request-id`); the call-instance join key.
 *   The browser does not mint call ids; per-call correlation uses the gateway `request_id`.
 */

import type { CommonProperties, StartLlmTraceOptions } from './types.js';
import { BrowserIdentityStore, type BrowserIdentity } from './identity.js';
import { newUuidV7, newUuidV7TraceId, randomHex } from './uuid.js';

export interface TraceHeaders extends Record<string, string | undefined> {
  'x-abto-device-id'?: string;
  'x-abto-user-id'?: string;
  'x-abto-node-key'?: string;
  /** Raw trace id for the browser→backend hop. The backend re-emits it as traceparent to the gateway. */
  'x-abto-trace-id'?: string;
  traceparent?: string;
}

interface ContextState {
  userId: string | undefined;
  tenantId: string | undefined;
  pageviewId: string;
  nodeId: string | undefined;
  traceId: string | undefined;
  taskType: string | undefined;
  surface: string | undefined;
  entryPoint: string | undefined;
  conversationId: string | undefined;
  messageId: string | undefined;
  promptTemplateId: string | undefined;
}

export interface ContextStoreOptions {
  projectKey: string;
  sessionIdleMs?: number;
  sessionMaxAgeMs?: number;
}

/** 32-hex-character W3C-compatible trace id. */
export function newTraceId(): string {
  return newUuidV7TraceId();
}

export function newSpanId(): string {
  return randomHex(8);
}

/** Build a W3C `traceparent` value for the given trace id. */
export function toTraceparent(traceId: string, spanId = newSpanId()): string {
  return `00-${traceId}-${spanId}-01`;
}

/** Client-side id for an emitted event (dedup / ordering only — not a join key). */
export function newEventId(): string {
  return newUuidV7();
}

export class ContextStore {
  private readonly identity: BrowserIdentityStore;
  private state: ContextState;

  constructor(options: ContextStoreOptions) {
    this.identity = new BrowserIdentityStore(options);
    this.state = {
      userId: undefined,
      tenantId: undefined,
      pageviewId: newUuidV7(),
      nodeId: undefined,
      traceId: undefined,
      taskType: undefined,
      surface: undefined,
      entryPoint: undefined,
      conversationId: undefined,
      messageId: undefined,
      promptTemplateId: undefined,
    };
  }

  identify(userId: string, tenantId?: string): void {
    this.state.userId = userId;
    this.state.tenantId = tenantId;
  }

  reset(): void {
    this.clearScopedContext();
    this.identity.resetSession();
    this.state.pageviewId = newUuidV7();
  }

  forgetDevice(): void {
    this.clearScopedContext();
    this.identity.forgetDevice();
    this.state.pageviewId = newUuidV7();
  }

  private clearScopedContext(): void {
    this.state.userId = undefined;
    this.state.tenantId = undefined;
    this.state.nodeId = undefined;
    this.state.traceId = undefined;
    this.state.taskType = undefined;
    this.state.surface = undefined;
    this.state.entryPoint = undefined;
    this.state.conversationId = undefined;
    this.state.messageId = undefined;
    this.state.promptTemplateId = undefined;
  }

  newPageview(): string {
    this.state.pageviewId = newUuidV7();
    return this.state.pageviewId;
  }

  /** Set the "feature.node" node id (e.g. "resume.make"). */
  setNode(nodeId: string): void {
    this.state.nodeId = nodeId;
  }

  newTrace(): string {
    this.state.traceId = newTraceId();
    return this.state.traceId;
  }

  startLlmTrace(options: StartLlmTraceOptions): StartLlmTraceOptions & { traceId: string } {
    this.state.nodeId = options.nodeId;
    this.state.traceId = options.traceId ?? newTraceId();
    this.state.taskType = options.taskType;
    this.state.surface = options.surface;
    this.state.entryPoint = options.entryPoint;
    this.state.conversationId = options.conversationId;
    this.state.messageId = options.messageId;
    this.state.promptTemplateId = options.promptTemplateId;
    return { ...options, traceId: this.state.traceId };
  }

  get traceId(): string | undefined {
    return this.state.traceId;
  }

  getIdentity(): BrowserIdentity {
    return this.identity.current();
  }

  getTraceHeaders(overrides: Partial<CommonProperties> = {}): TraceHeaders {
    const nodeId = overrides.node_key ?? this.state.nodeId;
    const traceId = overrides.trace_id ?? this.state.traceId;

    const headers: TraceHeaders = {};
    headers['x-abto-device-id'] = this.identity.current().deviceId;
    if (this.state.userId) headers['x-abto-user-id'] = this.state.userId;
    if (nodeId) headers['x-abto-node-key'] = nodeId;
    if (traceId) {
      headers['x-abto-trace-id'] = traceId;
      headers.traceparent = toTraceparent(traceId);
    }
    return headers;
  }

  toCommonProperties(): CommonProperties {
    const identity = this.identity.current();
    const common: CommonProperties = {
      device_id: identity.deviceId,
      anonymous_id: identity.anonymousId,
      session_id: identity.sessionId,
      window_id: identity.windowId,
      pageview_id: this.state.pageviewId,
    };
    if (this.state.userId) common.user_id = this.state.userId;
    if (this.state.tenantId) common.tenant_id = this.state.tenantId;
    if (this.state.nodeId) common.node_key = this.state.nodeId;
    if (this.state.traceId) common.trace_id = this.state.traceId;
    if (this.state.taskType) common.task_type = this.state.taskType;
    if (this.state.surface) common.surface = this.state.surface;
    if (this.state.entryPoint) common.entry_point = this.state.entryPoint;
    if (this.state.conversationId) common.conversation_id = this.state.conversationId;
    if (this.state.messageId) common.message_id = this.state.messageId;
    if (this.state.promptTemplateId) common.prompt_template_id = this.state.promptTemplateId;
    return common;
  }
}
