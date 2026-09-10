import type { CapturedEvent } from './types.js';
import type { BrowserDiagnostics } from './diagnostics.js';
import { ABTO_MAX_BUFFERED_EVENTS } from './delivery-policy.generated.js';

function isCapturedEvent(value: unknown): value is CapturedEvent {
  if (value === null || typeof value !== 'object') return false;
  const event = value as Partial<CapturedEvent>;
  return typeof event.uuid === 'string' && event.uuid !== '' && typeof event.event === 'string'
    && typeof event.timestamp === 'string' && typeof event.device_id === 'string'
    && event.properties !== null && typeof event.properties === 'object' && !Array.isArray(event.properties);
}

function parseEvents(raw: string | null): CapturedEvent[] {
  try {
    const parsed: unknown = JSON.parse(raw ?? 'null');
    return Array.isArray(parsed) ? parsed.filter(isCapturedEvent) : isCapturedEvent(parsed) ? [parsed] : [];
  } catch { return []; }
}

interface OutboxEntry {
  sequence: number;
  event: CapturedEvent;
}

function parseEntry(raw: string | null): OutboxEntry | undefined {
  try {
    const value: unknown = JSON.parse(raw ?? 'null');
    if (isCapturedEvent(value)) return { sequence: 0, event: value };
    if (value && typeof value === 'object' && 'sequence' in value && 'event' in value &&
        typeof value.sequence === 'number' && Number.isSafeInteger(value.sequence) && isCapturedEvent(value.event)) {
      return { sequence: value.sequence, event: value.event };
    }
  } catch { /* Invalid stored entries are not restored. */ }
  return undefined;
}

/** Each event has its own atomic storage entry; one tab never rewrites another tab's queue. */
export class BrowserOutbox {
  private readonly storage: Storage | undefined;
  private readonly prefix: string;
  private readonly legacyKey: string;
  private lastSequence = 0;
  private readonly pendingSequences = new WeakMap<CapturedEvent, number>();

  constructor(projectKey: string, private readonly diagnostics?: BrowserDiagnostics) {
    this.prefix = `abto:outbox:v2:${encodeURIComponent(projectKey)}:`;
    this.legacyKey = `abto:outbox:v1:${encodeURIComponent(projectKey)}`;
    try {
      this.storage = globalThis.localStorage;
      if (this.storage === undefined) diagnostics?.record('storage_unavailable');
    } catch { diagnostics?.record('storage_unavailable'); }
  }

  read(): CapturedEvent[] {
    if (!this.storage) return [];
    try {
      const legacy = parseEvents(this.storage.getItem(this.legacyKey)).slice(-ABTO_MAX_BUFFERED_EVENTS);
      const entries = new Map(this.entries().map((entry) => [entry.event.uuid, entry]));
      const migration = legacy.flatMap((event, index) => entries.has(event.uuid) ? [] : [{ sequence: index - legacy.length, event }]);
      for (const entry of migration) entries.set(entry.event.uuid, entry);
      if (legacy.length > 0) {
        try {
          for (const entry of migration) {
            this.storage.setItem(this.key(entry.event.uuid), JSON.stringify(entry));
          }
          this.storage.removeItem(this.legacyKey);
        } catch { this.diagnostics?.record('outbox_write_failed'); }
      }
      return this.ordered([...entries.values()]).slice(-ABTO_MAX_BUFFERED_EVENTS).map((entry) => entry.event);
    } catch {
      this.diagnostics?.record('storage_unavailable');
      return [];
    }
  }

  put(event: CapturedEvent): boolean {
    if (!this.storage) return false;
    let entries: OutboxEntry[];
    try {
      entries = this.entries();
      // Sequence is explicit: UUIDv7 random bits and Storage.key() iteration order are not capture order.
      const sequence = entries.find((entry) => entry.event.uuid === event.uuid)?.sequence
        ?? this.pendingSequences.get(event) ?? this.lastSequence + 1;
      this.lastSequence = Math.max(this.lastSequence, sequence);
      this.pendingSequences.set(event, sequence);
      const entry = { sequence, event };
      this.storage.setItem(this.key(event.uuid), JSON.stringify(entry));
      entries = [...entries.filter((stored) => stored.event.uuid !== event.uuid), entry];
    } catch {
      this.diagnostics?.record('outbox_write_failed');
      return false;
    }
    try {
      if (entries.length > ABTO_MAX_BUFFERED_EVENTS) {
        for (const entry of this.ordered(entries).slice(0, -ABTO_MAX_BUFFERED_EVENTS)) {
          this.storage.removeItem(this.key(entry.event.uuid));
        }
      }
    } catch { this.diagnostics?.record('outbox_write_failed'); }
    return true;
  }

  remove(uuids: readonly string[]): void {
    if (!this.storage) return;
    try {
      for (const uuid of uuids) this.storage.removeItem(this.key(uuid));
      // If migration writes failed, acknowledgements still retire the legacy copy.
      const raw = this.storage.getItem(this.legacyKey);
      if (raw !== null) {
        const removed = new Set(uuids);
        const remaining = parseEvents(raw).filter((event) => !removed.has(event.uuid));
        if (remaining.length === 0) this.storage.removeItem(this.legacyKey);
        else this.storage.setItem(this.legacyKey, JSON.stringify(remaining));
      }
    } catch { this.diagnostics?.record('outbox_write_failed'); }
  }

  clear(): void {
    if (!this.storage) return;
    try {
      for (const key of this.keys()) this.storage.removeItem(key);
      this.storage.removeItem(this.legacyKey);
    } catch { this.diagnostics?.record('outbox_write_failed'); }
  }

  private key(uuid: string): string { return `${this.prefix}${encodeURIComponent(uuid)}`; }

  private keys(): string[] {
    const keys: string[] = [];
    for (let index = 0; index < (this.storage?.length ?? 0); index += 1) {
      const key = this.storage!.key(index);
      if (key?.startsWith(this.prefix)) keys.push(key);
    }
    return keys;
  }

  private entries(): OutboxEntry[] {
    const entries: OutboxEntry[] = [];
    for (const key of this.keys()) {
      const entry = parseEntry(this.storage!.getItem(key));
      if (entry && this.key(entry.event.uuid) === key) {
        entries.push(entry);
        this.lastSequence = Math.max(this.lastSequence, entry.sequence);
      }
    }
    return entries;
  }

  private ordered(entries: OutboxEntry[]): OutboxEntry[] {
    return entries.sort((left, right) => left.sequence - right.sequence
      || left.event.timestamp.localeCompare(right.event.timestamp) || left.event.uuid.localeCompare(right.event.uuid));
  }
}
