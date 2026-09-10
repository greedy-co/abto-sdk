import { describe, expect, it } from 'vitest';
import { defineEvents, validateCustomEventName } from './event-registry.js';
import {
  ABTO_ERR_EVENT_NAME_DOLLAR_PREFIX,
  ABTO_ERR_EVENT_NAME_RESERVED,
  ABTO_ERR_EVENT_NAME_TOO_LONG,
} from './delivery-policy.generated.js';

describe('defineEvents', () => {
  it('rejects ABTO-owned $ event names', () => {
    expect(() => defineEvents({ $pageview: {} })).toThrow(ABTO_ERR_EVENT_NAME_DOLLAR_PREFIX);
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
    expect(() => defineEvents({ [name]: {} })).toThrow(ABTO_ERR_EVENT_NAME_RESERVED);
  });

  it('enforces the Backend event_name UTF-16 length limit', () => {
    expect(validateCustomEventName('x'.repeat(200))).toBeUndefined();
    expect(validateCustomEventName('🙂'.repeat(100))).toBeUndefined();
    expect(validateCustomEventName('x'.repeat(201))).toBe(ABTO_ERR_EVENT_NAME_TOO_LONG);
    expect(validateCustomEventName('🙂'.repeat(101))).toBe(ABTO_ERR_EVENT_NAME_TOO_LONG);
    expect(() => defineEvents({ ['x'.repeat(201)]: {} })).toThrow(ABTO_ERR_EVENT_NAME_TOO_LONG);
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
