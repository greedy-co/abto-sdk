import { describe, it, expect } from 'vitest';
import { serializeElementsChain, elementText } from './elements-chain.js';

describe('serializeElementsChain', () => {
  it('serializes tag, class, id, text and ancestors', () => {
    document.body.innerHTML =
      '<div id="root" class="a b"><span>hi</span><button class="cta">Go</button></div>';
    const chain = serializeElementsChain(document.querySelector('button'));
    expect(chain).toContain('button.cta');
    expect(chain).toContain('text="Go"');
    expect(chain).toContain('#root');
    // Walk up through ancestors such as button;div;body.
    expect(chain.split(';').length).toBeGreaterThanOrEqual(2);
  });

  it('preserves data-abto-* attributes', () => {
    document.body.innerHTML =
      '<button data-abto-action="accept" data-abto-feature-id="resume.make">x</button>';
    const chain = serializeElementsChain(document.querySelector('button'));
    expect(chain).toContain('data-abto-action="accept"');
    expect(chain).toContain('data-abto-feature-id="resume.make"');
  });

  it('caps long text', () => {
    document.body.innerHTML = `<button>${'x'.repeat(500)}</button>`;
    expect(elementText(document.querySelector('button')!).length).toBeLessThanOrEqual(255);
  });
});
