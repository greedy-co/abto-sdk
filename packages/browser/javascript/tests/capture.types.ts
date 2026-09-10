import { initAbto, defineEvents, type CaptureOptions } from '../src/index.js';
const sdk = initAbto({ projectKey: 'test', events: defineEvents({ checkout_completed: {} }) });
const input = { value: 49000, scale: 'KRW', tier: 'pro' } satisfies CaptureOptions;
sdk.capture('checkout_completed', input);
sdk.capture('checkout_completed', { value: 1, scale: 'count' });
sdk.capture('checkout_completed');
sdk.capture('checkout_completed', { value: 49000 });
sdk.capture('checkout_completed', { scale: 'KRW' });
// A property named properties is ordinary user data, not a metric envelope.
sdk.capture('checkout_completed', { properties: { value: 49000, scale: 'KRW' } });
// @ts-expect-error event name comes from the registry
sdk.capture('checkout_compeleted', input);
// @ts-expect-error scalar properties cannot contain deeper object trees
sdk.capture('checkout_completed', { value: 1, scale: 'count', deep: { nested: {} } });
// @ts-expect-error value must be a number
sdk.capture('checkout_completed', { value: '49000', scale: 'KRW' });
// @ts-expect-error scale must be a string
sdk.capture('checkout_completed', { value: 49000, scale: 1 });

sdk.capture('checkout_completed', {});
sdk.capture('checkout_completed', { tier: 'pro' });
