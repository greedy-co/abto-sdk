import { describe, expect, it } from 'vitest';
import { defineEvents, validateCustomEventName } from './event-registry.js';

describe('defineEvents', () => {
  it('rejects ABTO-owned $ event names', () => {
    expect(() => defineEvents({ $pageview: {} })).toThrow('reserved');
  });

  it.each([
    'pageview',
    'pageleave',
    'interaction_autocaptured',
    'interaction_rageclick',
    'interaction_deadclick',
    'llm_prompt_submitted',
    'llm_response_rendered',
    'llm_response_interacted',
  ])('rejects the ABTO-owned %s Backend wire name', (name) => {
    expect(() => defineEvents({ [name]: {} })).toThrow('system event on the wire');
  });

  it('enforces the Backend event_name UTF-16 length limit', () => {
    expect(validateCustomEventName('x'.repeat(200))).toBeUndefined();
    expect(validateCustomEventName('🙂'.repeat(100))).toBeUndefined();
    expect(validateCustomEventName('x'.repeat(201))).toContain('200 UTF-16');
    expect(validateCustomEventName('🙂'.repeat(101))).toContain('200 UTF-16');
    expect(() => defineEvents({ ['x'.repeat(201)]: {} })).toThrow('200 UTF-16');
  });

  it('keeps the declaration to a name and a human description', () => {
    const registry = defineEvents({
      checkout_completed: { description: '결제 완료' },
      summary_copied: {},
    });

    expect(Object.keys(registry)).toEqual(['checkout_completed', 'summary_copied']);
    expect(registry.checkout_completed.description).toBe('결제 완료');
  });
});
