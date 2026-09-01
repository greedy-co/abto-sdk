/**
 * Broad, delegation-based interaction autocapture. data-abto-* annotations enrich
 * the raw event; they never replace it with a guessed semantic event.
 * SPA route changes emit pageview/pageleave. Session replay (rrweb) is out of scope.
 */

import { createClickSignalDetector } from './click-signals.js';
import { serializeElementsChain, elementText } from './elements-chain.js';
import { maskText, resolveDomPolicy } from './privacy.js';
import {
  createScrollDepthTracker,
  type ScrollDepthSnapshot,
} from './scroll-depth.js';
import type { AutocaptureEventType, MaskMode } from './types.js';

const ATTR = {
  action: 'data-abto-action',
  surface: 'data-abto-surface',
  featureId: 'data-abto-feature-id',
  requestId: 'data-abto-request-id',
  conversationId: 'data-abto-conversation-id',
  messageId: 'data-abto-message-id',
  responseId: 'data-abto-response-id',
  templateId: 'data-abto-template-id',
} as const;

interface SemanticTarget {
  action: string;
  surface?: string;
  feature_id?: string;
  request_id?: string;
  conversation_id?: string;
  message_id?: string;
  response_id?: string;
  template_id?: string;
}

interface CapturedElement {
  tag: string;
  text?: string;
  value?: string;
  input_type?: string;
  name?: string;
  href?: string;
}

interface InteractionHit {
  kind: 'interaction';
  eventType: AutocaptureEventType;
  target: SemanticTarget;
  elementsChain: string;
  element: CapturedElement;
  selectionLength?: number;
}

interface PageviewHit {
  kind: 'pageview';
  eventType: 'pageview' | 'pageleave';
  path: string;
  referrer?: string;
  /** Wall-clock dwell time for the departing page. Present only on pageleave. */
  durationMs?: number;
  /** Scroll depth for the departing page. Present only on pageleave. */
  scroll?: ScrollDepthSnapshot;
  /** Pageleave emitted by a real pagehide. Receivers should flush it immediately. */
  unload?: boolean;
}

export interface SignalHit {
  kind: 'signal';
  eventType: 'rageclick' | 'deadclick';
  elementsChain: string;
  clickCount?: number;
}

export type AutocaptureHit = InteractionHit | PageviewHit | SignalHit;
type AutocaptureSink = (hit: AutocaptureHit) => void;

const HREF_CAP = 2048;
const NEVER_CAPTURE_INPUT_TYPES = new Set(['password', 'hidden']);
const SENSITIVE_FIELD_NAME =
  /(^|[_-])(cc|card|cardnum|credit|cvc|cvv|password|passwd|pwd|secret|ssn|social[_-]?security)([_-]|$)/i;
const SAFE_SEMANTIC_VALUE = /^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/;
const IDENTIFIER_PATH_SEGMENT =
  /^(?:\d+|[0-9a-f]{8}-[0-9a-f-]{27,}|[A-Za-z0-9._~-]{20,}|[^/@\s]+@[^/@\s]+)$/i;

function safeSemanticValue(value: string | undefined): string | undefined {
  return value !== undefined && SAFE_SEMANTIC_VALUE.test(value) ? value : undefined;
}

function sanitizePath(pathname: string): string {
  const segments = pathname.split('/').map((segment) => {
    if (segment === '') return '';
    let decoded = segment;
    try {
      decoded = decodeURIComponent(segment);
    } catch {
      return ':id';
    }
    return IDENTIFIER_PATH_SEGMENT.test(decoded) ? ':id' : segment;
  });
  return segments.join('/') || '/';
}

function sanitizeUrl(raw: string): string | undefined {
  if (typeof location === 'undefined') return undefined;
  try {
    const base = new URL(location.href);
    const parsed = new URL(raw, base);
    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') return undefined;
    if (parsed.origin !== base.origin) return parsed.origin.slice(0, HREF_CAP);
    return sanitizePath(parsed.pathname).slice(0, HREF_CAP);
  } catch {
    return undefined;
  }
}

function readSemanticTarget(el: Element): SemanticTarget {
  const inherited = (attr: string): string | undefined => {
    for (let node: Element | null = el; node; node = node.parentElement) {
      const value = node.getAttribute(attr);
      if (value !== null) return value;
    }
    return undefined;
  };

  const target: SemanticTarget = { action: safeSemanticValue(inherited(ATTR.action)) ?? '' };
  const surface = safeSemanticValue(inherited(ATTR.surface));
  const featureId = safeSemanticValue(inherited(ATTR.featureId));
  const requestId = safeSemanticValue(inherited(ATTR.requestId));
  const conversationId = safeSemanticValue(inherited(ATTR.conversationId));
  const messageId = safeSemanticValue(inherited(ATTR.messageId));
  const responseId = safeSemanticValue(inherited(ATTR.responseId));
  const templateId = safeSemanticValue(inherited(ATTR.templateId));
  if (surface !== undefined) target.surface = surface;
  if (featureId !== undefined) target.feature_id = featureId;
  if (requestId !== undefined) target.request_id = requestId;
  if (conversationId !== undefined) target.conversation_id = conversationId;
  if (messageId !== undefined) target.message_id = messageId;
  if (responseId !== undefined) target.response_id = responseId;
  if (templateId !== undefined) target.template_id = templateId;
  return target;
}

function readElementMeta(el: Element, eventType: AutocaptureEventType, mask: MaskMode): CapturedElement {
  const meta: CapturedElement = { tag: el.tagName.toLowerCase() };
  const text = elementText(el);
  if (text) meta.text = maskText(text, mask);
  const href = el.getAttribute('href');
  const safeHref = href ? sanitizeUrl(href) : undefined;
  if (safeHref) meta.href = safeHref;

  if (eventType === 'change') {
    const field = el as HTMLInputElement;
    const inputType = (field.type ?? '').toLowerCase();
    const name = el.getAttribute('name') ?? '';
    const isProtectedField =
      NEVER_CAPTURE_INPUT_TYPES.has(inputType) || SENSITIVE_FIELD_NAME.test(name);
    if (inputType) meta.input_type = inputType;
    const safeName = safeSemanticValue(name);
    if (safeName) meta.name = safeName;
    if (!isProtectedField && typeof field.value === 'string' && field.value !== '') {
      meta.value = maskText(field.value, mask);
    }
  }
  return meta;
}

// capture phase: run before the host so a stopped propagation still reaches us.
const USE_CAPTURE = true;

export function installAutocapture(
  sink: AutocaptureSink,
  maskMode: MaskMode = 'all',
): () => void {
  if (typeof document === 'undefined') return () => {};

  const emitInteraction = (el: Element | null, eventType: AutocaptureEventType): void => {
    if (!el) return;
    const policy = resolveDomPolicy(el);
    if (policy === 'no-capture') return;
    const mask: MaskMode = policy === 'include' ? 'off' : policy === 'sensitive' ? 'all' : maskMode;
    const hit: InteractionHit = {
      kind: 'interaction',
      eventType,
      target: readSemanticTarget(el),
      elementsChain: serializeElementsChain(el, mask),
      element: readElementMeta(el, eventType, mask),
    };
    if (eventType === 'copy') {
      hit.selectionLength = document.getSelection()?.toString().length ?? 0;
    }
    sink(hit);
  };

  const clickSignals = createClickSignalDetector(sink);
  const onClick = (e: Event): void => {
    const el = e.target as Element | null;
    emitInteraction(el, 'click');
    if (el && resolveDomPolicy(el) !== 'no-capture' && e instanceof MouseEvent) {
      const policy = resolveDomPolicy(el);
      const mask: MaskMode = policy === 'include' ? 'off' : policy === 'sensitive' ? 'all' : maskMode;
      clickSignals.onClick(el, e.clientX, e.clientY, mask);
    }
  };
  const onChange = (e: Event): void => emitInteraction(e.target as Element | null, 'change');
  const onSubmit = (e: Event): void => emitInteraction(e.target as Element | null, 'submit');
  const onCopy = (e: Event): void =>
    emitInteraction((e.target as Element | null) ?? document.activeElement, 'copy');

  document.addEventListener('click', onClick, USE_CAPTURE);
  document.addEventListener('change', onChange, USE_CAPTURE);
  document.addEventListener('submit', onSubmit, USE_CAPTURE);
  document.addEventListener('copy', onCopy, USE_CAPTURE);

  const routePath = (): string =>
    typeof location !== 'undefined' ? sanitizePath(location.pathname) : '';
  let lastPath = routePath();
  let pageviewStartedAt = Date.now();
  const scrollDepth = createScrollDepthTracker();

  const pageleaveHit = (unload?: boolean): PageviewHit => {
    const hit: PageviewHit = {
      kind: 'pageview',
      eventType: 'pageleave',
      path: lastPath,
      durationMs: Date.now() - pageviewStartedAt,
    };
    const scroll = scrollDepth.snapshot();
    if (scroll) hit.scroll = scroll;
    if (unload) hit.unload = true;
    return hit;
  };

  const emitRouteChange = (): void => {
    const nextPath = routePath();
    if (nextPath === lastPath) return;
    sink(pageleaveHit());
    sink({ kind: 'pageview', eventType: 'pageview', path: nextPath, referrer: lastPath });
    lastPath = nextPath;
    pageviewStartedAt = Date.now();
    scrollDepth.reset();
  };

  const history = typeof window !== 'undefined' ? window.history : undefined;
  const originalPush = history?.pushState;
  const originalReplace = history?.replaceState;
  if (history && originalPush && originalReplace) {
    history.pushState = function (this: History, ...args) {
      const result = originalPush.apply(this, args as Parameters<History['pushState']>);
      emitRouteChange();
      return result;
    };
    history.replaceState = function (this: History, ...args) {
      const result = originalReplace.apply(this, args as Parameters<History['replaceState']>);
      emitRouteChange();
      return result;
    };
  }
  // Pageview state lives only in memory, like PostHog's PageViewManager, so emit
  // the final pageleave before a full unload to preserve dwell time.
  let unloadPageleaveSent = false;
  const onPagehide = (): void => {
    if (unloadPageleaveSent) return;
    unloadPageleaveSent = true;
    sink(pageleaveHit(true));
  };
  // Treat a bfcache restore as a new pageview to keep pageview/pageleave pairs balanced.
  const onPageshow = (e: Event): void => {
    if (!(e as PageTransitionEvent).persisted || !unloadPageleaveSent) return;
    unloadPageleaveSent = false;
    pageviewStartedAt = Date.now();
    scrollDepth.reset();
    sink({ kind: 'pageview', eventType: 'pageview', path: lastPath });
  };
  if (typeof window !== 'undefined') {
    window.addEventListener('popstate', emitRouteChange);
    window.addEventListener('hashchange', emitRouteChange);
    window.addEventListener('pagehide', onPagehide);
    window.addEventListener('pageshow', onPageshow);
  }

  const initialPageview: PageviewHit = { kind: 'pageview', eventType: 'pageview', path: lastPath };
  const referrer = typeof document !== 'undefined' ? document.referrer : '';
  const safeReferrer = referrer ? sanitizeUrl(referrer) : undefined;
  if (safeReferrer) initialPageview.referrer = safeReferrer;
  sink(initialPageview);

  return () => {
    clickSignals.dispose();
    scrollDepth.dispose();
    document.removeEventListener('click', onClick, USE_CAPTURE);
    document.removeEventListener('change', onChange, USE_CAPTURE);
    document.removeEventListener('submit', onSubmit, USE_CAPTURE);
    document.removeEventListener('copy', onCopy, USE_CAPTURE);
    if (history && originalPush && originalReplace) {
      history.pushState = originalPush;
      history.replaceState = originalReplace;
    }
    if (typeof window !== 'undefined') {
      window.removeEventListener('popstate', emitRouteChange);
      window.removeEventListener('hashchange', emitRouteChange);
      window.removeEventListener('pagehide', onPagehide);
      window.removeEventListener('pageshow', onPageshow);
    }
  };
}
