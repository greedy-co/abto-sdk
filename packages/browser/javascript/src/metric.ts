import {
  ABTO_METRIC_MAX_FRACTION_DIGITS,
  ABTO_SCALE_MAX_LENGTH,
} from './delivery-policy.generated.js';

/**
 * The bounds Analytics can store in its numeric metric column.
 *
 * Capture time and send time must reach the same verdict: capture warns and omits, and the
 * transport checks once more as the last line of defence. If the two disagree, a value outside
 * the contract rides along silently.
 */
const METRIC_ABSOLUTE_LIMIT = 1e38;

function decimalScale(value: number): number {
  const [coefficient, exponentText] = Math.abs(value).toString().toLowerCase().split('e');
  const fractionDigits = (coefficient?.split('.')[1] ?? '').replace(/0+$/, '').length;
  const exponent = exponentText === undefined ? 0 : Number(exponentText);
  return Math.max(0, fractionDigits - exponent);
}

export function isCollectorMetricValue(value: unknown): value is number {
  return (
    typeof value === 'number' &&
    Number.isFinite(value) &&
    Math.abs(value) < METRIC_ABSOLUTE_LIMIT &&
    decimalScale(value) <= ABTO_METRIC_MAX_FRACTION_DIGITS
  );
}

export function isCollectorScale(value: unknown): value is string {
  return typeof value === 'string' && value !== '' && value.length <= ABTO_SCALE_MAX_LENGTH;
}
