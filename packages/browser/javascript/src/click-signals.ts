/**
 * Detect rage clicks and dead clicks from elements observed by a delegated click listener.
 * A rage click repeats within a short window and narrow radius. A dead click has no
 * subsequent DOM mutation or scroll activity.
 */

import { serializeElementsChain } from './elements-chain.js';
import type { SignalHit } from './autocapture.js';
import type { MaskMode } from './types.js';

const DEFAULTS = {
  rageClicks: 3,
  rageWindowMs: 1000,
  rageRadiusPx: 30,
  deadClickTimeoutMs: 1000,
};

interface ClickMark {
  t: number;
  x: number;
  y: number;
}

export function createClickSignalDetector(
  emit: (hit: SignalHit) => void,
) {
  const recentClicks: ClickMark[] = [];
  const pendingDeadClicks = new Set<ReturnType<typeof setTimeout>>();

  const detectRageclick = (el: Element, mark: ClickMark, mask: MaskMode): void => {
    while (recentClicks.length && mark.t - recentClicks[0]!.t > DEFAULTS.rageWindowMs) recentClicks.shift();
    recentClicks.push(mark);
    const nearby = recentClicks.filter(
      (c) =>
        Math.abs(c.x - mark.x) <= DEFAULTS.rageRadiusPx &&
        Math.abs(c.y - mark.y) <= DEFAULTS.rageRadiusPx,
    );
    if (nearby.length >= DEFAULTS.rageClicks) {
      emit({ kind: 'signal', eventType: 'rageclick', elementsChain: serializeElementsChain(el, mask), clickCount: nearby.length });
      recentClicks.length = 0;
    }
  };

  const detectDeadclick = (el: Element, mask: MaskMode): void => {
    if (typeof MutationObserver === 'undefined') return;
    let activity = false;
    const observer = new MutationObserver(() => {
      activity = true;
    });
    observer.observe(document.documentElement, { childList: true, subtree: true, attributes: true, characterData: true });
    const startScrollY = typeof window !== 'undefined' ? window.scrollY : 0;
    const onScroll = (): void => {
      activity = true;
    };
    window.addEventListener('scroll', onScroll, { passive: true, once: true });

    const timer = setTimeout(() => {
      observer.disconnect();
      window.removeEventListener('scroll', onScroll);
      pendingDeadClicks.delete(timer);
      const scrolled = typeof window !== 'undefined' && window.scrollY !== startScrollY;
      if (!activity && !scrolled) {
        emit({ kind: 'signal', eventType: 'deadclick', elementsChain: serializeElementsChain(el, mask) });
      }
    }, DEFAULTS.deadClickTimeoutMs);
    pendingDeadClicks.add(timer);
  };

  return {
    onClick(el: Element, x: number, y: number, mask: MaskMode = 'all') {
      detectRageclick(el, { t: Date.now(), x, y }, mask);
      detectDeadclick(el, mask);
    },
    dispose() {
      for (const timer of pendingDeadClicks) clearTimeout(timer);
      pendingDeadClicks.clear();
      recentClicks.length = 0;
    },
  };
}
