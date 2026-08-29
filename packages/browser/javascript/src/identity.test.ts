import { describe, expect, it } from 'vitest';
import { BrowserDiagnostics } from './diagnostics.js';
import { BrowserIdentityStore, type StorageLike } from './identity.js';

class MemoryStorage implements StorageLike {
  readonly values = new Map<string, string>();
  writes = 0;

  getItem(key: string): string | null {
    return this.values.get(key) ?? null;
  }

  setItem(key: string, value: string): void {
    this.writes += 1;
    this.values.set(key, value);
  }
}

class FailingWriteStorage extends MemoryStorage {
  override setItem(): void {
    throw new DOMException('quota exceeded', 'QuotaExceededError');
  }
}

class FailingReadStorage extends MemoryStorage {
  override getItem(): string | null {
    throw new DOMException('storage disabled', 'SecurityError');
  }
}

describe('BrowserIdentityStore lifecycle', () => {
  it('reports identity persistence failure and keeps an in-memory identity', () => {
    const diagnostics = new BrowserDiagnostics();
    const store = new BrowserIdentityStore({
      projectKey: 'project',
      storage: new FailingWriteStorage(),
      windowStorage: new MemoryStorage(),
      diagnostics,
    });

    expect(store.current().deviceId).not.toBe('');
    expect(diagnostics.snapshot()?.counters.identity_persist_failed).toBeGreaterThan(0);
  });

  it('reports unavailable storage once and falls back to memory', () => {
    const diagnostics = new BrowserDiagnostics();
    const store = new BrowserIdentityStore({
      projectKey: 'project',
      storage: new FailingReadStorage(),
      windowStorage: new MemoryStorage(),
      diagnostics,
    });

    expect(store.current().deviceId).not.toBe('');
    const firstReport = diagnostics.snapshot();
    expect(firstReport?.counters).toEqual({ storage_unavailable: 1 });

    diagnostics.acknowledge(firstReport!);
    store.current();

    expect(diagnostics.snapshot()).toBeUndefined();
  });

  it('rotates a session after idle timeout', () => {
    let now = 0;
    const storage = new MemoryStorage();
    const store = new BrowserIdentityStore({
      projectKey: 'project',
      storage,
      windowStorage: new MemoryStorage(),
      now: () => now,
      sessionIdleMs: 30 * 60 * 1000,
    });
    const first = store.current();

    now += 31 * 60 * 1000;
    const rotated = store.current();

    expect(rotated.deviceId).toBe(first.deviceId);
    expect(rotated.sessionId).not.toBe(first.sessionId);
  });

  it('rotates an active session at the 24 hour maximum age', () => {
    let now = 0;
    const storage = new MemoryStorage();
    const store = new BrowserIdentityStore({
      projectKey: 'project',
      storage,
      windowStorage: new MemoryStorage(),
      now: () => now,
      sessionIdleMs: 30 * 60 * 1000,
      sessionMaxAgeMs: 24 * 60 * 60 * 1000,
    });
    const first = store.current();

    for (let interval = 1; interval <= 72; interval += 1) {
      now = interval * 20 * 60 * 1000;
      store.current();
    }
    const rotated = store.current();

    expect(rotated.deviceId).toBe(first.deviceId);
    expect(rotated.sessionId).not.toBe(first.sessionId);
  });

  it('keeps one window id across same-tab reload and separates another tab', () => {
    const identityStorage = new MemoryStorage();
    const firstTabStorage = new MemoryStorage();
    const secondTabStorage = new MemoryStorage();
    const first = new BrowserIdentityStore({
      projectKey: 'project',
      storage: identityStorage,
      windowStorage: firstTabStorage,
    }).current();
    const refreshed = new BrowserIdentityStore({
      projectKey: 'project',
      storage: identityStorage,
      windowStorage: firstTabStorage,
    }).current();
    const secondTab = new BrowserIdentityStore({
      projectKey: 'project',
      storage: identityStorage,
      windowStorage: secondTabStorage,
    }).current();

    expect(refreshed.windowId).toBe(first.windowId);
    expect(secondTab.sessionId).toBe(first.sessionId);
    expect(secondTab.windowId).not.toBe(first.windowId);
  });

  it('throttles repeated persistence writes while still returning current identity', () => {
    let now = 0;
    const storage = new MemoryStorage();
    const store = new BrowserIdentityStore({
      projectKey: 'project',
      storage,
      windowStorage: new MemoryStorage(),
      now: () => now,
      writeThrottleMs: 1000,
    });
    const writesAfterCreate = storage.writes;

    store.current();
    now += 100;
    store.current();
    now += 100;
    store.current();

    expect(storage.writes).toBe(writesAfterCreate);

    now += 1000;
    store.current();
    expect(storage.writes).toBe(writesAfterCreate + 1);
  });
});
