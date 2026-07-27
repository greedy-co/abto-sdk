/**
 * Scroll depth tracking (PostHog ScrollManager 모델).
 * scroll 은 사용자가 내린 스크롤 깊이, content 는 화면에 보인 콘텐츠의 하한이다
 * (예: 문서 1000px·뷰포트 500px 에서 스크롤 0 이면 scroll 0, content 500).
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

export interface ScrollDepthTracker {
  /** pageleave 에 실을 현재 페이지의 스크롤 깊이. 아직 측정 전이면 undefined. */
  snapshot(): ScrollDepthSnapshot | undefined;
  /** 새 pageview 에서 호출. 새 페이지 DOM 이 그려진 다음 tick 에 초기값을 심는다. */
  reset(): void;
  dispose(): void;
}

const clamp01 = (value: number): number => Math.min(1, Math.max(0, value));

// 스크롤 가능 높이가 0 에 가까우면(내릴 것이 없으면) 전부 본 것으로 친다.
const percentage = (y: number, height: number): number => (height <= 1 ? 1 : clamp01(y / height));

// window 밖 스크롤러(내부 스크롤 영역)의 scroll 이벤트도 받으려면 capture 가 필요하다.
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
    // SPA 라우팅 직후에는 새 페이지 DOM 이 아직 없을 수 있어 다음 tick 에 측정한다.
    setTimeout(update, 0);
  };

  window.addEventListener('scroll', update, USE_CAPTURE);
  window.addEventListener('scrollend', update, USE_CAPTURE);
  window.addEventListener('resize', update);
  reset();

  return {
    snapshot: () => {
      if (!context) return undefined;
      // 999.5px/1000px 스크롤도 100% 로 치도록 px 는 ceil 후 비율을 구한다.
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
