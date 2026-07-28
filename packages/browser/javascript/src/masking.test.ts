import { describe, it, expect, afterEach } from 'vitest';
import { installAutocapture, type AutocaptureHit } from './autocapture.js';
import { maskText } from './privacy.js';

let teardown: (() => void) | undefined;
afterEach(() => {
  teardown?.();
  teardown = undefined;
});

describe('maskText', () => {
  it('off keeps text as-is', () => expect(maskText('hello', 'off')).toBe('hello'));
  it('all replaces with a length marker', () => expect(maskText('hello', 'all')).toBe('«masked:5»'));
  it('sensitive redacts PII patterns', () =>
    expect(maskText('mail me at a@b.com', 'sensitive')).toContain('«redacted-pii»'));
  it('sensitive redacts every repeated PII and secret pattern', () => {
    const masked = maskText(
      'a@b.com and c@d.com sk-abcdefghijklmnop sk-qrstuvwxyzABCDEF',
      'sensitive',
    );
    expect(masked).toBe(
      '«redacted-pii» and «redacted-pii» «redacted-secret» «redacted-secret»',
    );
  });
});

describe('autocapture masking', () => {
  it('masks text by default even when installAutocapture is used directly', () => {
    document.body.innerHTML = '<button>Default secret</button>';
    const hits: AutocaptureHit[] = [];
    teardown = installAutocapture((h) => hits.push(h));
    document.querySelector('button')!.dispatchEvent(new MouseEvent('click', { bubbles: true }));
    const hit = hits.find((h) => h.kind === 'interaction');
    if (hit && hit.kind === 'interaction') expect(hit.element.text).toBe('«masked:14»');
  });

  it("mask 'all' masks element text in meta and elements_chain", () => {
    document.body.innerHTML = '<button>Buy Now</button>';
    const hits: AutocaptureHit[] = [];
    teardown = installAutocapture((h) => hits.push(h), { mask: 'all' });
    document.querySelector('button')!.dispatchEvent(new MouseEvent('click', { bubbles: true }));
    const hit = hits.find((h) => h.kind === 'interaction' && h.eventType === 'click');
    if (hit && hit.kind === 'interaction') {
      expect(hit.element.text).toBe('«masked:7»');
      expect(hit.elementsChain).not.toContain('Buy Now');
    }
  });

  it("mask 'all' masks input change values", () => {
    document.body.innerHTML = '<input type="text" name="n" />';
    const hits: AutocaptureHit[] = [];
    teardown = installAutocapture((h) => hits.push(h), { mask: 'all' });
    const input = document.querySelector('input')! as HTMLInputElement;
    input.value = 'secret-value';
    input.dispatchEvent(new Event('change', { bubbles: true }));
    const hit = hits.find((h) => h.kind === 'interaction' && h.element.name === 'n');
    if (hit && hit.kind === 'interaction') expect(hit.element.value).toBe('«masked:12»');
  });

  it('data-abto-sensitive masks content even when mask is off', () => {
    document.body.innerHTML = '<div data-abto-sensitive><input type="text" name="s" /></div>';
    const hits: AutocaptureHit[] = [];
    teardown = installAutocapture((h) => hits.push(h), { mask: 'off' });
    const input = document.querySelector('input')! as HTMLInputElement;
    input.value = 'private';
    input.dispatchEvent(new Event('change', { bubbles: true }));
    const hit = hits.find((h) => h.kind === 'interaction' && h.element.name === 's');
    if (hit && hit.kind === 'interaction') expect(hit.element.value).toBe('«masked:7»');
  });

  it('data-abto-include explicitly unmasks content under the default all mask', () => {
    document.body.innerHTML = '<button data-abto-include>Show me</button>';
    const hits: AutocaptureHit[] = [];
    teardown = installAutocapture((h) => hits.push(h), { mask: 'all' });
    document.querySelector('button')!.dispatchEvent(new MouseEvent('click', { bubbles: true }));
    const hit = hits.find((h) => h.kind === 'interaction');
    if (hit && hit.kind === 'interaction') expect(hit.element.text).toBe('Show me');
  });

  it('requires data-abto-include before raw DOM identifiers enter elements_chain', () => {
    document.body.innerHTML =
      '<button id="private-id" class="private-class" data-abto-include>Show me</button>';
    const hits: AutocaptureHit[] = [];
    teardown = installAutocapture((h) => hits.push(h), { mask: 'all' });
    document.querySelector('button')!.dispatchEvent(new MouseEvent('click', { bubbles: true }));
    const hit = hits.find((h) => h.kind === 'interaction');
    if (hit && hit.kind === 'interaction') {
      expect(hit.elementsChain).toContain('#private-id');
      expect(hit.elementsChain).toContain('.private-class');
    }
  });

  it('does not let include override a sensitive ancestor', () => {
    document.body.innerHTML =
      '<div data-abto-sensitive><button data-abto-include>Private</button></div>';
    const hits: AutocaptureHit[] = [];
    teardown = installAutocapture((h) => hits.push(h), { mask: 'off' });
    document.querySelector('button')!.dispatchEvent(new MouseEvent('click', { bubbles: true }));
    const hit = hits.find((h) => h.kind === 'interaction');
    if (hit && hit.kind === 'interaction') expect(hit.element.text).toBe('«masked:7»');
  });

  it('does not let include override a no-capture ancestor', () => {
    document.body.innerHTML =
      '<div data-abto-no-capture><button data-abto-include>Private</button></div>';
    const hits: AutocaptureHit[] = [];
    teardown = installAutocapture((h) => hits.push(h), { mask: 'off' });
    document.querySelector('button')!.dispatchEvent(new MouseEvent('click', { bubbles: true }));
    expect(hits.some((h) => h.kind === 'interaction')).toBe(false);
  });

  it.each([
    ['hidden', 'token'],
    ['text', 'credit_card_number'],
    ['text', 'cvc'],
    ['text', 'social_security_number'],
  ])('never captures protected %s/%s field values', (type, name) => {
    document.body.innerHTML = `<input data-abto-include type="${type}" name="${name}" />`;
    const hits: AutocaptureHit[] = [];
    teardown = installAutocapture((h) => hits.push(h), { mask: 'off' });
    const input = document.querySelector('input')! as HTMLInputElement;
    input.value = '4111111111111111';
    input.dispatchEvent(new Event('change', { bubbles: true }));
    const hit = hits.find((h) => h.kind === 'interaction');
    if (hit && hit.kind === 'interaction') expect(hit.element.value).toBeUndefined();
  });
});
