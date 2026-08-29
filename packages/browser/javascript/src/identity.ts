import { newUuidV7 } from './uuid.js';
import type { BrowserDiagnostics } from './diagnostics.js';

const IDENTITY_STORAGE_VERSION = 2;
const WINDOW_STORAGE_VERSION = 1;
const DEFAULT_SESSION_IDLE_MS = 30 * 60 * 1000;
const DEFAULT_SESSION_MAX_AGE_MS = 24 * 60 * 60 * 1000;
const DEFAULT_WRITE_THROTTLE_MS = 1000;

export interface BrowserIdentity {
  deviceId: string;
  anonymousId: string;
  sessionId: string;
  windowId: string;
}

export interface IdentityStoreOptions {
  projectKey: string;
  sessionIdleMs?: number;
  sessionMaxAgeMs?: number;
  writeThrottleMs?: number;
  storage?: StorageLike;
  windowStorage?: StorageLike;
  now?: () => number;
  diagnostics?: BrowserDiagnostics;
}

export interface StorageLike {
  getItem(key: string): string | null;
  setItem(key: string, value: string): void;
}

interface PersistedIdentity {
  version: number;
  deviceId: string;
  sessionId: string;
  sessionStartedAt: number;
  lastSeenAt: number;
}

function resolveLocalStorage(diagnostics: BrowserDiagnostics | undefined): StorageLike | undefined {
  try {
    const storage = globalThis.localStorage;
    if (storage === undefined) diagnostics?.record('storage_unavailable');
    return storage;
  } catch {
    diagnostics?.record('storage_unavailable');
    return undefined;
  }
}

function resolveWindowStorage(diagnostics: BrowserDiagnostics | undefined): StorageLike | undefined {
  try {
    const storage = globalThis.sessionStorage;
    if (storage === undefined) diagnostics?.record('storage_unavailable');
    return storage;
  } catch {
    diagnostics?.record('storage_unavailable');
    return undefined;
  }
}

function isPersistedIdentity(value: unknown): value is PersistedIdentity {
  if (value === null || typeof value !== 'object') return false;
  const candidate = value as Partial<PersistedIdentity>;
  return (
    candidate.version === IDENTITY_STORAGE_VERSION &&
    typeof candidate.deviceId === 'string' &&
    candidate.deviceId !== '' &&
    typeof candidate.sessionId === 'string' &&
    candidate.sessionId !== '' &&
    typeof candidate.sessionStartedAt === 'number' &&
    Number.isFinite(candidate.sessionStartedAt) &&
    typeof candidate.lastSeenAt === 'number' &&
    Number.isFinite(candidate.lastSeenAt)
  );
}

export class BrowserIdentityStore {
  private readonly storage: StorageLike | undefined;
  private readonly windowStorage: StorageLike | undefined;
  private readonly storageKey: string;
  private readonly windowStorageKey: string;
  private readonly sessionIdleMs: number;
  private readonly sessionMaxAgeMs: number;
  private readonly writeThrottleMs: number;
  private readonly now: () => number;
  private readonly diagnostics: BrowserDiagnostics | undefined;
  private state: PersistedIdentity;
  private windowId: string;
  private lastPersistedAt = Number.NEGATIVE_INFINITY;

  constructor(options: IdentityStoreOptions) {
    this.diagnostics = options.diagnostics;
    this.storage = options.storage ?? resolveLocalStorage(this.diagnostics);
    this.windowStorage = options.windowStorage ?? resolveWindowStorage(this.diagnostics);
    this.storageKey = `abto:identity:v${IDENTITY_STORAGE_VERSION}:${encodeURIComponent(options.projectKey)}`;
    this.windowStorageKey = `abto:window:v${WINDOW_STORAGE_VERSION}:${encodeURIComponent(options.projectKey)}`;
    this.sessionIdleMs = positiveOr(options.sessionIdleMs, DEFAULT_SESSION_IDLE_MS);
    this.sessionMaxAgeMs = positiveOr(options.sessionMaxAgeMs, DEFAULT_SESSION_MAX_AGE_MS);
    this.writeThrottleMs = positiveOr(options.writeThrottleMs, DEFAULT_WRITE_THROTTLE_MS);
    this.now = options.now ?? Date.now;
    this.state = this.read() ?? this.create();
    this.windowId = this.readWindowId() ?? this.createWindowId();
    this.touch(true);
  }

  current(): BrowserIdentity {
    this.touch();
    return {
      deviceId: this.state.deviceId,
      anonymousId: this.state.deviceId,
      sessionId: this.state.sessionId,
      windowId: this.windowId,
    };
  }

  resetSession(): BrowserIdentity {
    this.rotateSession(this.now());
    this.persist(true);
    return this.current();
  }

  forgetDevice(): BrowserIdentity {
    this.state = this.create();
    this.windowId = this.createWindowId();
    this.persist(true);
    return this.current();
  }

  private touch(force = false): void {
    const now = this.now();
    const persisted = this.read();
    if (persisted !== undefined) this.state = persisted;

    const idleExpired = now - this.state.lastSeenAt > this.sessionIdleMs;
    const maxAgeExpired = now - this.state.sessionStartedAt >= this.sessionMaxAgeMs;
    if (idleExpired || maxAgeExpired) this.rotateSession(now);
    this.state.lastSeenAt = now;
    this.persist(force || idleExpired || maxAgeExpired);
  }

  private rotateSession(now: number): void {
    this.state.sessionId = newUuidV7(now);
    this.state.sessionStartedAt = now;
    this.state.lastSeenAt = now;
  }

  private create(): PersistedIdentity {
    const now = this.now();
    return {
      version: IDENTITY_STORAGE_VERSION,
      deviceId: newUuidV7(now),
      sessionId: newUuidV7(now),
      sessionStartedAt: now,
      lastSeenAt: now,
    };
  }

  private createWindowId(): string {
    const windowId = newUuidV7(this.now());
    try {
      this.windowStorage?.setItem(this.windowStorageKey, windowId);
    } catch {
      this.diagnostics?.record('storage_unavailable');
    }
    return windowId;
  }

  private read(): PersistedIdentity | undefined {
    if (this.storage === undefined) return undefined;
    let raw: string | null;
    try {
      raw = this.storage.getItem(this.storageKey);
    } catch {
      this.diagnostics?.record('storage_unavailable');
      return undefined;
    }
    if (raw === null) return undefined;
    try {
      const value: unknown = JSON.parse(raw);
      return isPersistedIdentity(value) ? value : undefined;
    } catch {
      return undefined;
    }
  }

  private readWindowId(): string | undefined {
    try {
      const value = this.windowStorage?.getItem(this.windowStorageKey);
      return value === undefined || value === null || value === '' ? undefined : value;
    } catch {
      this.diagnostics?.record('storage_unavailable');
      return undefined;
    }
  }

  private persist(force = false): void {
    const now = this.now();
    if (!force && now - this.lastPersistedAt < this.writeThrottleMs) return;
    if (this.storage === undefined) return;
    try {
      this.storage.setItem(this.storageKey, JSON.stringify(this.state));
      this.lastPersistedAt = now;
    } catch {
      this.diagnostics?.record('identity_persist_failed');
    }
  }
}

function positiveOr(value: number | undefined, fallback: number): number {
  return typeof value === 'number' && value > 0 ? value : fallback;
}
