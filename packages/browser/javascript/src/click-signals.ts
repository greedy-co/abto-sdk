/**
 * Rageclick / deadclick 감지. click 위임 리스너에서 요소를 받아 UX 마찰 신호를 emit한다.
 * rageclick: 짧은 시간·좁은 반경 내 반복 클릭. deadclick: 클릭 후 DOM 변화·스크롤이 없는 클릭.
 */

import { serializeElementsChain } from './elements-chain.js';
import type { SignalHit } from './autocapture.js';
import type { MaskMode } from './types.js';

export interface ClickSignalOptions {
  rageClicks?: number;
  rageWindowMs?: number;
  rageRadiusPx?: number;
  deadClickTimeoutMs?: number;
}

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

export interface ClickSignalDetector {
  onClick(el: Element, x: number, y: number, mask?: MaskMode): void;
  dispose(): void;
}

export function createClickSignalDetector(
  emit: (hit: SignalHit) => void,
  options: ClickSignalOptions = {},
): ClickSignalDetector {
  const rageClicks = options.rageClicks ?? DEFAULTS.rageClicks;
  const rageWindowMs = options.rageWindowMs ?? DEFAULTS.rageWindowMs;
  const rageRadiusPx = options.rageRadiusPx ?? DEFAULTS.rageRadiusPx;
  const deadClickTimeoutMs = options.deadClickTimeoutMs ?? DEFAULTS.deadClickTimeoutMs;

  const recentClicks: ClickMark[] = [];
  const pendingDeadClicks = new Set<ReturnType<typeof setTimeout>>();

  const detectRageclick = (el: Element, mark: ClickMark, mask: MaskMode): void => {
    while (recentClicks.length && mark.t - recentClicks[0]!.t > rageWindowMs) recentClicks.shift();
    recentClicks.push(mark);
    const nearby = recentClicks.filter(
      (c) => Math.abs(c.x - mark.x) <= rageRadiusPx && Math.abs(c.y - mark.y) <= rageRadiusPx,
    );
    if (nearby.length >= rageClicks) {
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
    }, deadClickTimeoutMs);
    pendingDeadClicks.add(timer);
  };

  return {
    onClick(el, x, y, mask = 'all') {
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
