import {
  ABTO_EVENT_NAME_MAX_LENGTH,
  BROWSER_SYSTEM_EVENT_WIRE_NAMES,
} from './system-events.generated.js';
import {
  ABTO_ERR_EVENT_NAME_BLANK,
  ABTO_ERR_EVENT_NAME_DOLLAR_PREFIX,
  ABTO_ERR_EVENT_NAME_NUL,
  ABTO_ERR_EVENT_NAME_RESERVED,
  ABTO_ERR_EVENT_NAME_TOO_LONG,
} from './delivery-policy.generated.js';

/**
 * A Custom Event declaration.
 *
 * The registry declares names and descriptions; capture separately requires value/scale
 * and accepts optional JSON properties. No per-event property schema is inferred here.
 */
export interface CustomEventDefinition {
  description?: string;
}

export type EventRegistry = Record<string, CustomEventDefinition>;

const SYSTEM_EVENT_WIRE_NAMES = new Set<string>(Object.values(BROWSER_SYSTEM_EVENT_WIRE_NAMES));

export function validateCustomEventName(name: string): string | undefined {
  if (name.trim() === '') return ABTO_ERR_EVENT_NAME_BLANK;
  if (name.includes('\u0000')) return ABTO_ERR_EVENT_NAME_NUL;
  if (name.startsWith('$')) return ABTO_ERR_EVENT_NAME_DOLLAR_PREFIX;
  if (name.length > ABTO_EVENT_NAME_MAX_LENGTH) return ABTO_ERR_EVENT_NAME_TOO_LONG;
  if (SYSTEM_EVENT_WIRE_NAMES.has(name)) return ABTO_ERR_EVENT_NAME_RESERVED;
  return undefined;
}

export function defineEvents<const R extends EventRegistry>(registry: R): R {
  for (const name of Object.keys(registry)) {
    const eventNameIssue = validateCustomEventName(name);
    if (eventNameIssue !== undefined) {
      throw new Error(`[abto] custom event name "${name}" ${eventNameIssue}.`);
    }
  }
  return registry;
}
