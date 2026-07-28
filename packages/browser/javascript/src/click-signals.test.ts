import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { createClickSignalDetector } from './click-signals.js';
import type { SignalHit } from './autocapture.js';

describe('click signals', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    document.body.innerHTML = '<button>x</button>';
  });
  afterEach(() => vi.useRealTimers());

  it('emits rageclick after repeated clicks in a tight radius', () => {
    const hits: SignalHit[] = [];
    const detector = createClickSignalDetector((h) => hits.push(h));
    const el = document.querySelector('button')!;
    detector.onClick(el, 10, 10);
    detector.onClick(el, 11, 11);
    detector.onClick(el, 12, 12);
    const rage = hits.find((h) => h.eventType === 'rageclick');
    expect(rage).toBeTruthy();
    expect(rage?.clickCount).toBeGreaterThanOrEqual(3);
    detector.dispose();
  });

  it('emits deadclick when a click causes no DOM change or scroll', async () => {
    const hits: SignalHit[] = [];
    const detector = createClickSignalDetector((h) => hits.push(h));
    detector.onClick(document.querySelector('button')!, 5, 5);
    await vi.advanceTimersByTimeAsync(1100);
    expect(hits.some((h) => h.eventType === 'deadclick')).toBe(true);
    detector.dispose();
  });

  it('suppresses deadclick when the DOM mutates after the click', async () => {
    const hits: SignalHit[] = [];
    const detector = createClickSignalDetector((h) => hits.push(h));
    detector.onClick(document.querySelector('button')!, 5, 5);
    document.body.appendChild(document.createElement('div'));
    await Promise.resolve();
    await vi.advanceTimersByTimeAsync(1100);
    expect(hits.some((h) => h.eventType === 'deadclick')).toBe(false);
    detector.dispose();
  });
});
