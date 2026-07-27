import { describe, expect, expectTypeOf, it } from 'vitest';
import {
  defineEvents,
  type InferCustomEventProperties,
  validateCustomEventName,
  validateEventProperties,
} from './event-registry.js';

describe('defineEvents', () => {
  it('rejects ABTO-owned $ event and property names', () => {
    expect(() =>
      defineEvents({
        $pageview: { properties: {} },
      }),
    ).toThrow('reserved');

    expect(() =>
      defineEvents({
        checkout_completed: {
          properties: {
            $session_id: { type: 'string' },
          },
        },
      }),
    ).toThrow('property');
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
    expect(() =>
      defineEvents({
        [name]: { properties: {} },
      }),
    ).toThrow('system event on the wire');
  });

  it('enforces the Backend event_name UTF-16 length limit', () => {
    expect(validateCustomEventName('x'.repeat(200))).toBeUndefined();
    expect(validateCustomEventName('🙂'.repeat(100))).toBeUndefined();
    expect(validateCustomEventName('x'.repeat(201))).toContain('200 UTF-16');
    expect(validateCustomEventName('🙂'.repeat(101))).toContain('200 UTF-16');
    expect(() =>
      defineEvents({
        ['x'.repeat(201)]: { properties: {} },
      }),
    ).toThrow('200 UTF-16');
  });

  it('infers required, optional, and enum property types', () => {
    const registry = defineEvents({
      checkout_completed: {
        properties: {
          order_id: { type: 'string', required: true },
          amount: { type: 'number', required: true },
          currency: { type: 'string', enum: ['KRW', 'USD'] as const },
          recurring: { type: 'boolean' },
        },
      },
    });

    type Properties = InferCustomEventProperties<(typeof registry)['checkout_completed']>;
    expectTypeOf<Properties>().toMatchTypeOf<{
      order_id: string;
      amount: number;
      currency?: 'KRW' | 'USD';
      recurring?: boolean;
    }>();
  });

  it('rejects reserved $ keys supplied in a custom event payload', () => {
    const result = validateEventProperties(
      { properties: {} },
      { $schema_version: 'spoofed' },
    );

    expect(result).toEqual({
      valid: false,
      issues: ['$schema_version is reserved; $ properties belong to ABTO'],
    });
  });
});
