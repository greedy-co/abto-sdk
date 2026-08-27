import { describe, it, expect, afterEach } from 'vitest';
import { createScrollDepthTracker, type ScrollDepthTracker } from './scroll-depth.js';

let tracker: ScrollDepthTracker | undefined;

afterEach(() => {
  tracker?.dispose();
  tracker = undefined;
});

const nextTick = (): Promise<void> => new Promise((resolve) => setTimeout(resolve, 0));

// jsdom has no layout, so define scroll metrics directly.
function defineScrollMetrics(metrics: {
  scrollY: number;
  scrollHeight: number;
  clientHeight: number;
}): void {
  Object.defineProperty(window, 'scrollY', { value: metrics.scrollY, configurable: true });
  Object.defineProperty(document.documentElement, 'scrollHeight', {
    value: metrics.scrollHeight,
    configurable: true,
  });
  Object.defineProperty(document.documentElement, 'clientHeight', {
    value: metrics.clientHeight,
    configurable: true,
  });
}

describe('scroll depth tracker', () => {
  it('measures the initial viewport before any scroll', async () => {
    defineScrollMetrics({ scrollY: 0, scrollHeight: 2000, clientHeight: 500 });
    tracker = createScrollDepthTracker();
    await nextTick();

    const snapshot = tracker.snapshot()!;
    expect(snapshot.max_scroll_y).toBe(0);
    expect(snapshot.max_scroll_percentage).toBe(0);
    expect(snapshot.last_content_y).toBe(500);
    expect(snapshot.max_content_percentage).toBe(0.25);
  });

  it('tracks last and max separately as the user scrolls down and back up', async () => {
    defineScrollMetrics({ scrollY: 0, scrollHeight: 2000, clientHeight: 500 });
    tracker = createScrollDepthTracker();
    await nextTick();

    defineScrollMetrics({ scrollY: 750, scrollHeight: 2000, clientHeight: 500 });
    window.dispatchEvent(new Event('scroll'));
    defineScrollMetrics({ scrollY: 100, scrollHeight: 2000, clientHeight: 500 });
    window.dispatchEvent(new Event('scroll'));

    const snapshot = tracker.snapshot()!;
    expect(snapshot.last_scroll_y).toBe(100);
    expect(snapshot.max_scroll_y).toBe(750);
    expect(snapshot.max_scroll_percentage).toBe(0.5); // 750 / (2000 - 500)
    expect(snapshot.max_content_y).toBe(1250);
    expect(snapshot.max_content_percentage).toBe(0.625); // 1250 / 2000
  });

  it('treats an unscrollable page as fully seen', async () => {
    defineScrollMetrics({ scrollY: 0, scrollHeight: 500, clientHeight: 500 });
    tracker = createScrollDepthTracker();
    await nextTick();

    const snapshot = tracker.snapshot()!;
    expect(snapshot.max_scroll_percentage).toBe(1);
    expect(snapshot.last_scroll_percentage).toBe(1);
  });

  it('clears maxima on reset for the next pageview', async () => {
    defineScrollMetrics({ scrollY: 750, scrollHeight: 2000, clientHeight: 500 });
    tracker = createScrollDepthTracker();
    await nextTick();
    expect(tracker.snapshot()!.max_scroll_y).toBe(750);

    defineScrollMetrics({ scrollY: 0, scrollHeight: 2000, clientHeight: 500 });
    tracker.reset();
    expect(tracker.snapshot()).toBeUndefined(); // Not measured until the next tick.
    await nextTick();
    expect(tracker.snapshot()!.max_scroll_y).toBe(0);
  });
});
