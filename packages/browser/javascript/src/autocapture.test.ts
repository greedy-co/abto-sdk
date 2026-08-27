import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { installAutocapture, type AutocaptureHit } from './autocapture.js';

let hits: AutocaptureHit[];
let teardown: () => void;

beforeEach(() => {
  hits = [];
  document.body.innerHTML = '';
  teardown = installAutocapture((h) => hits.push(h));
});

afterEach(() => teardown());

function click(el: Element): void {
  el.dispatchEvent(new MouseEvent('click', { bubbles: true }));
}

describe('broad autocapture', () => {
  it('captures unannotated clicks without raw class metadata by default', () => {
    document.body.innerHTML = '<button class="share">공유</button>';
    click(document.querySelector('button')!);
    const hit = hits.find((h) => h.kind === 'interaction');
    expect(hit && hit.kind === 'interaction').toBeTruthy();
    if (hit && hit.kind === 'interaction') {
      expect(hit.eventType).toBe('click');
      expect(hit.target.action).toBe('');
      expect(hit.elementsChain).toContain('button:');
      expect(hit.elementsChain).not.toContain('.share');
    }
  });

  it('reads data-abto-* annotation as raw-event dimensions', () => {
    document.body.innerHTML =
      '<button data-abto-action="accept" data-abto-node-key="resume.make">ok</button>';
    click(document.querySelector('button')!);
    const hit = hits.find((h) => h.kind === 'interaction');
    if (hit && hit.kind === 'interaction') {
      expect(hit.target.action).toBe('accept');
      expect(hit.target.node_key).toBe('resume.make');
    }
  });

  it('masks input change values by default and excludes password values', () => {
    document.body.innerHTML =
      '<input type="text" name="nick" /><input type="password" name="pw" />';
    const inputs = Array.from(document.querySelectorAll('input')) as HTMLInputElement[];
    inputs[0]!.value = 'alice';
    inputs[0]!.dispatchEvent(new Event('change', { bubbles: true }));
    inputs[1]!.value = 'secret';
    inputs[1]!.dispatchEvent(new Event('change', { bubbles: true }));

    const textHit = hits.find((h) => h.kind === 'interaction' && h.element.name === 'nick');
    const pwHit = hits.find((h) => h.kind === 'interaction' && h.element.name === 'pw');
    expect(textHit && textHit.kind === 'interaction' ? textHit.element.value : null).toBe(
      '«masked:5»',
    );
    expect(pwHit && pwHit.kind === 'interaction' ? pwHit.element.value : 'X').toBeUndefined();
  });

  it('respects data-abto-no-capture', () => {
    document.body.innerHTML = '<div data-abto-no-capture><button>x</button></div>';
    click(document.querySelector('button')!);
    expect(hits.filter((h) => h.kind === 'interaction').length).toBe(0);
  });

  it('emits an initial pageview on install', () => {
    // Installation in beforeEach emits the initial-load pageview.
    expect(hits.some((h) => h.kind === 'pageview' && h.eventType === 'pageview')).toBe(true);
  });

  it('emits pageview and pageleave on pushState', () => {
    hits.length = 0; // Exclude the initial-load pageview.
    history.pushState({}, '', '/step/broad-autocapture');
    const pv = hits.find(
      (h) => h.kind === 'pageview' && h.eventType === 'pageview',
    );
    const pl = hits.find((h) => h.kind === 'pageview' && h.eventType === 'pageleave');
    expect(pv && pv.kind === 'pageview').toBeTruthy();
    expect(pl && pl.kind === 'pageview').toBeTruthy();
    if (pv && pv.kind === 'pageview') expect(pv.path).toContain('/step/broad-autocapture');
  });

  it('drops query, fragment, and identifier-like path segments from URLs', () => {
    document.body.innerHTML =
      '<a href="/users/550e8400-e29b-41d4-a716-446655440000?token=secret#private">open</a>';
    const link = document.querySelector('a')!;
    link.addEventListener('click', (event) => event.preventDefault());
    click(link);
    const interaction = hits.find((h) => h.kind === 'interaction');
    if (interaction && interaction.kind === 'interaction') {
      expect(interaction.element.href).toBe('/users/:id');
      expect(interaction.elementsChain).not.toContain('token=secret');
      expect(interaction.elementsChain).not.toContain('private');
    }

    hits.length = 0;
    history.pushState({}, '', '/account/12345?token=secret#private');
    const pageview = hits.find((h) => h.kind === 'pageview' && h.eventType === 'pageview');
    expect(pageview && pageview.kind === 'pageview' ? pageview.path : '').toBe('/account/:id');
  });

  it('omits unsafe semantic annotation values', () => {
    document.body.innerHTML =
      '<button data-abto-action="accept user@example.com" data-abto-node-key="safe.node">ok</button>';
    click(document.querySelector('button')!);
    const hit = hits.find((h) => h.kind === 'interaction');
    if (hit && hit.kind === 'interaction') {
      expect(hit.target.action).toBe('');
      expect(hit.target.node_key).toBe('safe.node');
    }
  });
});

describe('pageview dwell time', () => {
  afterEach(() => vi.useRealTimers());

  it('stamps durationMs on SPA pageleave', () => {
    vi.useFakeTimers();
    hits.length = 0;
    vi.advanceTimersByTime(1234);
    history.pushState({}, '', '/dwell/spa');
    const pl = hits.find((h) => h.kind === 'pageview' && h.eventType === 'pageleave');
    expect(pl && pl.kind === 'pageview' ? pl.durationMs : -1).toBeGreaterThanOrEqual(1234);
  });

  it('attaches a scroll depth snapshot to pageleave', async () => {
    // The initial scroll measurement runs on the next tick.
    await new Promise((resolve) => setTimeout(resolve, 0));
    hits.length = 0;
    history.pushState({}, '', '/dwell/scroll');
    const pl = hits.find((h) => h.kind === 'pageview' && h.eventType === 'pageleave');
    const scroll = pl && pl.kind === 'pageview' ? pl.scroll : undefined;
    expect(scroll).toBeDefined();
    // jsdom has no layout, so the page is unscrollable and therefore fully viewed.
    expect(scroll!.max_scroll_percentage).toBe(1);
    expect(scroll!.max_content_percentage).toBe(1);
  });

  it('emits a final unload pageleave exactly once on pagehide', () => {
    hits.length = 0;
    window.dispatchEvent(new Event('pagehide'));
    window.dispatchEvent(new Event('pagehide'));
    const leaves = hits.filter((h) => h.kind === 'pageview' && h.eventType === 'pageleave');
    expect(leaves).toHaveLength(1);
    const leave = leaves[0]!;
    if (leave.kind === 'pageview') {
      expect(leave.unload).toBe(true);
      expect(leave.durationMs).toBeGreaterThanOrEqual(0);
    }
  });

  it('re-opens a pageview after bfcache restore and allows a later pageleave', () => {
    window.dispatchEvent(new Event('pagehide'));
    hits.length = 0;
    const pageshow = new Event('pageshow');
    Object.defineProperty(pageshow, 'persisted', { value: true });
    window.dispatchEvent(pageshow);
    expect(hits.some((h) => h.kind === 'pageview' && h.eventType === 'pageview')).toBe(true);

    window.dispatchEvent(new Event('pagehide'));
    expect(
      hits.some((h) => h.kind === 'pageview' && h.eventType === 'pageleave' && h.unload === true),
    ).toBe(true);
  });
});
