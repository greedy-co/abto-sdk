import {
  ABTO_EVENT_NAME_MAX_LENGTH,
  BROWSER_SYSTEM_EVENT_WIRE_NAMES,
} from './system-events.generated.js';

/**
 * A Custom Event declaration.
 *
 * An event carries only the metric `value` and its unit label `scale`, so a declaration holds
 * nothing but the name and a human description. Free-form properties are not accepted: they
 * reached no dashboard and only accumulated in every event's jsonb. Build metrics from the
 * event name and its metric instead.
 */
export interface CustomEventDefinition {
  description?: string;
}

export type EventRegistry = Record<string, CustomEventDefinition>;

const SYSTEM_EVENT_WIRE_NAMES = new Set<string>(Object.values(BROWSER_SYSTEM_EVENT_WIRE_NAMES));

export function validateCustomEventName(name: string): string | undefined {
  if (name.trim() === '') return 'must not be empty';
  if (name.includes('\u0000')) return 'must not contain U+0000';
  if (name.startsWith('$')) return 'is reserved; $ names belong to ABTO';
  if (name.length > ABTO_EVENT_NAME_MAX_LENGTH) {
    return `must be at most ${ABTO_EVENT_NAME_MAX_LENGTH} UTF-16 code units`;
  }
  if (SYSTEM_EVENT_WIRE_NAMES.has(name)) {
    return 'is reserved for an ABTO system event on the wire';
  }
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
