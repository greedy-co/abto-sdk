import type { BrowserDiagnosticsEnvelope } from './events.generated.js';
import {
  ABTO_BROWSER_DIAGNOSTIC_KINDS,
  ABTO_BROWSER_DIAGNOSTIC_MAX_COUNT,
  ABTO_BROWSER_DIAGNOSTIC_SDK_NAME,
} from './system-events.generated.js';

type BrowserDiagnosticSnapshot = BrowserDiagnosticsEnvelope;
type BrowserDiagnosticKind = (typeof ABTO_BROWSER_DIAGNOSTIC_KINDS)[number];

export class BrowserDiagnostics {
  private storageUnavailableRecorded = false;
  private readonly counts: Record<BrowserDiagnosticKind, number> = {
    send_failed: 0,
    outbox_write_failed: 0,
    identity_persist_failed: 0,
    storage_unavailable: 0,
  };

  record(kind: BrowserDiagnosticKind): void {
    // One unavailable browser storage capability can be observed by identity,
    // window, and outbox initialization. Count that condition once per client.
    if (kind === 'storage_unavailable') {
      if (this.storageUnavailableRecorded) return;
      this.storageUnavailableRecorded = true;
    }
    this.counts[kind] = Math.min(this.counts[kind] + 1, ABTO_BROWSER_DIAGNOSTIC_MAX_COUNT);
  }

  snapshot(): BrowserDiagnosticSnapshot | undefined {
    const counters: Partial<Record<BrowserDiagnosticKind, number>> = {};
    for (const kind of ABTO_BROWSER_DIAGNOSTIC_KINDS) {
      if (this.counts[kind] > 0) counters[kind] = this.counts[kind];
    }
    return Object.keys(counters).length > 0
      ? { sdk_name: ABTO_BROWSER_DIAGNOSTIC_SDK_NAME, counters }
      : undefined;
  }

  acknowledge(snapshot: BrowserDiagnosticSnapshot): void {
    for (const kind of ABTO_BROWSER_DIAGNOSTIC_KINDS) {
      this.counts[kind] = Math.max(0, this.counts[kind] - (snapshot.counters[kind] ?? 0));
    }
  }
}
