/**
 * Scroll depth tracking modeled after PostHog's ScrollManager.
 * `scroll` is how far the user has scrolled, while `content` is the lower edge
 * of visible content. For a 1000 px document and 500 px viewport at scroll 0,
 * scroll is 0 and content is 500.
 */

export interface ScrollDepthSnapshot {
  last_scroll_y?: number;
  last_scroll_percentage?: number;
  max_scroll_y?: number;
  max_scroll_percentage?: number;
  last_content_y?: number;
  last_content_percentage?: number;
  max_content_y?: number;
  max_content_percentage?: number;
}

interface ScrollContext {
  lastScrollY: number;
  maxScrollY: number;
  maxScrollHeight: number;
  lastContentY: number;
  maxContentY: number;
  maxContentHeight: number;
}

interface ScrollDepthTracker {
  /** Current page scroll depth for pageleave, or undefined before the first measurement. */
  snapshot(): ScrollDepthSnapshot | undefined;
  /** Reset for a new pageview and measure after its DOM can render on the next tick. */
  reset(): void;
  dispose(): void;
}

const clamp01 = (value: number): number => Math.min(1, Math.max(0, value));

// Treat a page with no meaningful scrollable height as fully viewed.
const percentage = (y: number, height: number): number => (height <= 1 ? 1 : clamp01(y / height));

// Capture phase also receives scroll events from nested scrolling containers.
const USE_CAPTURE = true;

export function createScrollDepthTracker(): ScrollDepthTracker {
  if (typeof window === 'undefined' || typeof document === 'undefined') {
    return { snapshot: () => undefined, reset: () => {}, dispose: () => {} };
  }

  let context: ScrollContext | undefined;
  let disposed = false;

  const update = (): void => {
    if (disposed) return;
    const root = document.documentElement;
    const scrollY = window.scrollY || window.pageYOffset || root.scrollTop || 0;
    const scrollHeight = Math.max(0, root.scrollHeight - root.clientHeight);
    const contentY = scrollY + root.clientHeight;
    const contentHeight = root.scrollHeight;
    context = {
      lastScrollY: scrollY,
      maxScrollY: Math.max(scrollY, context?.maxScrollY ?? 0),
      maxScrollHeight: Math.max(scrollHeight, context?.maxScrollHeight ?? 0),
      lastContentY: contentY,
      maxContentY: Math.max(contentY, context?.maxContentY ?? 0),
      maxContentHeight: Math.max(contentHeight, context?.maxContentHeight ?? 0),
    };
  };

  const reset = (): void => {
    context = undefined;
    // The next route's DOM may not exist immediately after SPA navigation.
    setTimeout(update, 0);
  };

  window.addEventListener('scroll', update, USE_CAPTURE);
  window.addEventListener('scrollend', update, USE_CAPTURE);
  window.addEventListener('resize', update);
  reset();

  return {
    snapshot: () => {
      if (!context) return undefined;
      // Round pixels up before division so 999.5 px of 1000 px counts as 100%.
      const lastScrollY = Math.ceil(context.lastScrollY);
      const maxScrollY = Math.ceil(context.maxScrollY);
      const maxScrollHeight = Math.ceil(context.maxScrollHeight);
      const lastContentY = Math.ceil(context.lastContentY);
      const maxContentY = Math.ceil(context.maxContentY);
      const maxContentHeight = Math.ceil(context.maxContentHeight);
      return {
        last_scroll_y: lastScrollY,
        last_scroll_percentage: percentage(lastScrollY, maxScrollHeight),
        max_scroll_y: maxScrollY,
        max_scroll_percentage: percentage(maxScrollY, maxScrollHeight),
        last_content_y: lastContentY,
        last_content_percentage: percentage(lastContentY, maxContentHeight),
        max_content_y: maxContentY,
        max_content_percentage: percentage(maxContentY, maxContentHeight),
      };
    },
    reset,
    dispose: () => {
      disposed = true;
      window.removeEventListener('scroll', update, USE_CAPTURE);
      window.removeEventListener('scrollend', update, USE_CAPTURE);
      window.removeEventListener('resize', update);
    },
  };
}
