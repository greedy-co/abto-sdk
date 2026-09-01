/** Browser identity and pageview context shared by emitted events. */

import type { CommonProperties } from './types.js';
import type { BrowserDiagnostics } from './diagnostics.js';
import { BrowserIdentityStore, type BrowserIdentity } from './identity.js';
import { newUuidV7 } from './uuid.js';

interface ContextState {
  userId: string | undefined;
  tenantId: string | undefined;
  pageviewId: string;
}

export class ContextStore {
  private readonly identity: BrowserIdentityStore;
  private state: ContextState;

  constructor(projectKey: string, diagnostics: BrowserDiagnostics) {
    this.identity = new BrowserIdentityStore({ projectKey, diagnostics });
    this.state = {
      userId: undefined,
      tenantId: undefined,
      pageviewId: newUuidV7(),
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
  }

  newPageview(): string {
    this.state.pageviewId = newUuidV7();
    return this.state.pageviewId;
  }

  getIdentity(): BrowserIdentity {
    return this.identity.current();
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
    return common;
  }
}
