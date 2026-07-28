import type { CapturedEvent, ResolvedConfig } from './types.js';
import type {
  BrowserEventBatchResponse,
  BrowserEventResult,
  BrowserIngestEvent,
} from './events.generated.js';
import { toBrowserSystemEventWireName } from './system-events.generated.js';

const MAX_BUFFER = 1000;
const MAX_BATCH_SIZE = 100;
const MAX_KEEPALIVE_BYTES = 60 * 1024;
const RETRY_BASE_MS = 1000;
const RETRY_MAX_MS = 60_000;
const METRIC_ABSOLUTE_LIMIT = 1e38;
const METRIC_MAX_FRACTION_DIGITS = 12;
const MAX_SCALE_LENGTH = 16;

interface StorageLike {
  getItem(key: string): string | null;
  setItem(key: string, value: string): void;
}

type BatchResponse = Partial<BrowserEventBatchResponse>;

function optionalString(value: unknown): string | undefined {
  return typeof value === 'string' && value !== '' ? value : undefined;
}

function optionalScale(value: unknown): string | undefined {
  const scale = optionalString(value);
  return scale !== undefined && scale.length <= MAX_SCALE_LENGTH ? scale : undefined;
}

function isCollectorMetricValue(value: unknown): value is number {
  if (typeof value !== 'number' || !Number.isFinite(value) || Math.abs(value) >= METRIC_ABSOLUTE_LIMIT) {
    return false;
  }
  const [coefficient, exponentText] = Math.abs(value).toString().toLowerCase().split('e');
  const fractionDigits = (coefficient?.split('.')[1] ?? '').replace(/0+$/, '').length;
  const exponent = exponentText === undefined ? 0 : Number(exponentText);
  return Math.max(0, fractionDigits - exponent) <= METRIC_MAX_FRACTION_DIGITS;
}

function toBackendEvent(event: CapturedEvent): BrowserIngestEvent {
  const deviceId = optionalString(event.properties.$device_id) ?? event.distinct_id;
  const sessionId = optionalString(event.properties.$session_id);
  const traceId = optionalString(event.properties.$trace_id);
  const value = isCollectorMetricValue(event.properties.value)
    ? event.properties.value
    : undefined;
  const scale = optionalScale(event.properties.scale);
  return {
    event_id: event.uuid,
    device_id: deviceId,
    ...(sessionId === undefined ? {} : { session_id: sessionId }),
    ...(traceId === undefined ? {} : { trace_id: traceId }),
    event_name: toBrowserSystemEventWireName(event.event),
    ...(value === undefined ? {} : { value }),
    ...(scale === undefined ? {} : { scale }),
    occurred_at: event.timestamp,
    extra_json: event.properties,
  };
}

function resolveStorage(): StorageLike | undefined {
  try {
    return globalThis.localStorage;
  } catch {
    return undefined;
  }
}

function isCapturedEvent(value: unknown): value is CapturedEvent {
  if (value === null || typeof value !== 'object') return false;
  const event = value as Partial<CapturedEvent>;
  return (
    typeof event.uuid === 'string' &&
    typeof event.event === 'string' &&
    typeof event.timestamp === 'string' &&
    typeof event.distinct_id === 'string' &&
    event.properties !== null &&
    typeof event.properties === 'object'
  );
}

function byteLength(value: string): number {
  return new TextEncoder().encode(value).byteLength;
}

function isTransientStatus(status: number): boolean {
  return status === 408 || status === 429 || status >= 500;
}

export class Transport {
  private queue: CapturedEvent[];
  private timer: ReturnType<typeof setTimeout> | null = null;
  private flushPromise: Promise<void> | null = null;
  private retryAttempt = 0;
  private disposed = false;
  private detachLifecycle: (() => void) | undefined;
  private readonly cfg: ResolvedConfig;
  private readonly storage: StorageLike | undefined;
  private readonly outboxKey: string;

  constructor(cfg: ResolvedConfig) {
    this.cfg = cfg;
    this.storage = resolveStorage();
    this.outboxKey = `abto:outbox:v1:${encodeURIComponent(cfg.projectKey)}`;
    this.queue = this.readOutbox();
    this.installLifecycleHooks();
    if (this.queue.length > 0 && !this.cfg.disabled) this.armTimer();
  }

  enqueue(event: CapturedEvent): void {
    if (this.cfg.disabled || this.disposed) return;
    this.queue.push(event);
    this.trimQueue();
    this.persist();
    if (this.queue.length >= this.cfg.batchSize) void this.flush();
    else this.armTimer();
  }

  async flush(useKeepalive = false): Promise<void> {
    if (this.flushPromise !== null) return this.flushPromise;
    if (this.timer !== null) {
      clearTimeout(this.timer);
      this.timer = null;
    }
    if (this.queue.length === 0 || this.cfg.disabled) return;

    this.flushPromise = this.flushBatch(useKeepalive).finally(() => {
      this.flushPromise = null;
    });
    return this.flushPromise;
  }

  shutdown(): void {
    this.disposed = true;
    if (this.timer !== null) clearTimeout(this.timer);
    this.timer = null;
    this.detachLifecycle?.();
    this.detachLifecycle = undefined;
  }

  discard(): void {
    this.queue = [];
    this.retryAttempt = 0;
    if (this.timer !== null) clearTimeout(this.timer);
    this.timer = null;
    this.persist();
  }

  private armTimer(delay = this.cfg.flushIntervalMs): void {
    if (this.disposed || this.timer !== null) return;
    this.timer = setTimeout(() => {
      this.timer = null;
      void this.flush();
    }, delay);
  }

  private async flushBatch(useKeepalive: boolean): Promise<void> {
    const batch = this.selectBatch();
    const body = JSON.stringify({ batch: batch.map(toBackendEvent) });
    const safeForKeepalive = byteLength(body) <= MAX_KEEPALIVE_BYTES;

    try {
      const response = await fetch(this.cfg.endpoint, {
        method: 'POST',
        // sendBeacon cannot expose Analytics' per-event 202 result. Keep the
        // durable outbox until a response-capable unload request acknowledges it.
        keepalive: useKeepalive && safeForKeepalive,
        headers: {
          'content-type': 'application/json',
          authorization: `Bearer ${this.cfg.apiKey}`,
        },
        body,
      });

      if (!response.ok) {
        if (isTransientStatus(response.status)) this.scheduleRetry();
        else this.acknowledge(batch.map((event) => event.uuid));
        return;
      }

      const result = await readBatchResponse(response);
      if (result.results === undefined) {
        this.acknowledge(batch.map((event) => event.uuid));
        return;
      }

      const acknowledged: string[] = [];
      let retry = false;
      for (const event of batch) {
        const eventResult = result.results[event.uuid];
        if (shouldRetry(eventResult)) retry = true;
        else acknowledged.push(event.uuid);
      }
      this.acknowledge(acknowledged, false);
      if (retry) this.scheduleRetry();
      else if (this.queue.length > 0) this.armTimer(0);
    } catch {
      this.scheduleRetry();
    }
  }

  private selectBatch(): CapturedEvent[] {
    const maxCount = Math.max(1, Math.min(this.cfg.batchSize, MAX_BATCH_SIZE));
    const selected: CapturedEvent[] = [];
    for (const event of this.queue.slice(0, maxCount)) {
      const candidate = [...selected, event];
      const body = JSON.stringify({ batch: candidate.map(toBackendEvent) });
      if (selected.length > 0 && byteLength(body) > MAX_KEEPALIVE_BYTES) break;
      selected.push(event);
    }
    return selected;
  }

  private acknowledge(uuids: readonly string[], scheduleNext = true): void {
    const acknowledged = new Set(uuids);
    this.queue = this.queue.filter((event) => !acknowledged.has(event.uuid));
    // Per-event retry만 받은 batch는 진전이 없으므로 backoff 단계를 유지한다.
    if (acknowledged.size > 0) this.retryAttempt = 0;
    this.persist();
    if (scheduleNext && this.queue.length > 0) this.armTimer(0);
  }

  private scheduleRetry(): void {
    const delay = Math.min(RETRY_BASE_MS * 2 ** this.retryAttempt, RETRY_MAX_MS);
    this.retryAttempt += 1;
    this.armTimer(delay);
  }

  private trimQueue(): void {
    if (this.queue.length > MAX_BUFFER) this.queue = this.queue.slice(-MAX_BUFFER);
  }

  private readOutbox(): CapturedEvent[] {
    if (this.storage === undefined) return [];
    try {
      const raw = this.storage.getItem(this.outboxKey);
      if (raw === null) return [];
      const parsed: unknown = JSON.parse(raw);
      return Array.isArray(parsed) ? parsed.filter(isCapturedEvent).slice(-MAX_BUFFER) : [];
    } catch {
      return [];
    }
  }

  private persist(): void {
    try {
      this.storage?.setItem(this.outboxKey, JSON.stringify(this.queue));
    } catch {
      // Quota/security failures degrade to the in-memory queue.
    }
  }

  private installLifecycleHooks(): void {
    if (typeof document === 'undefined') return;
    const onHide = (): void => {
      if (document.visibilityState === 'hidden') void this.flush(true);
    };
    const onPageHide = (): void => void this.flush(true);
    document.addEventListener('visibilitychange', onHide);
    window.addEventListener('pagehide', onPageHide);
    this.detachLifecycle = () => {
      document.removeEventListener('visibilitychange', onHide);
      window.removeEventListener('pagehide', onPageHide);
    };
  }
}

async function readBatchResponse(response: Response): Promise<BatchResponse> {
  try {
    const parsed: unknown = await response.json();
    if (parsed !== null && typeof parsed === 'object') return parsed as BatchResponse;
  } catch {
    // Empty 2xx responses acknowledge the whole batch.
  }
  return {};
}

function shouldRetry(result: BrowserEventResult | undefined): boolean {
  return result === undefined || result.result === 'retry';
}
