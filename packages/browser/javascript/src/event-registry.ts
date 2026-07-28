import {
  ABTO_EVENT_NAME_MAX_LENGTH,
  BROWSER_SYSTEM_EVENT_WIRE_NAMES,
} from './system-events.generated.js';

export type CustomPropertyType = 'string' | 'number' | 'boolean';
export type CustomPropertyScalar = string | number | boolean;

export interface CustomPropertyDefinition<
  T extends CustomPropertyType = CustomPropertyType,
  E extends readonly CustomPropertyScalar[] | undefined = readonly CustomPropertyScalar[] | undefined,
> {
  type: T;
  required?: boolean;
  enum?: E;
  description?: string;
}

export interface CustomEventDefinition<
  P extends Record<string, CustomPropertyDefinition> = Record<string, CustomPropertyDefinition>,
> {
  description?: string;
  properties: P;
}

export type EventRegistry = Record<string, CustomEventDefinition>;

type ScalarForType<T extends CustomPropertyType> = T extends 'string'
  ? string
  : T extends 'number'
    ? number
    : boolean;

type ValueForDefinition<D extends CustomPropertyDefinition> = D['enum'] extends readonly (
  infer E
)[]
  ? E
  : ScalarForType<D['type']>;

type RequiredPropertyKeys<P extends Record<string, CustomPropertyDefinition>> = {
  [K in keyof P]-?: P[K]['required'] extends true ? K : never;
}[keyof P];

type OptionalPropertyKeys<P extends Record<string, CustomPropertyDefinition>> = Exclude<
  keyof P,
  RequiredPropertyKeys<P>
>;

export type InferCustomEventProperties<D extends CustomEventDefinition> = {
  [K in RequiredPropertyKeys<D['properties']>]: ValueForDefinition<D['properties'][K]>;
} & {
  [K in OptionalPropertyKeys<D['properties']>]?: ValueForDefinition<D['properties'][K]>;
};

export type CustomEventPayloadMap<R extends EventRegistry> = {
  [K in keyof R]: InferCustomEventProperties<R[K]>;
};

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
    const event = registry[name];
    if (event === undefined) continue;
    const eventNameIssue = validateCustomEventName(name);
    if (eventNameIssue !== undefined) {
      throw new Error(`[abto] custom event name "${name}" ${eventNameIssue}.`);
    }
    for (const property of Object.keys(event.properties)) {
      if (property.startsWith('$')) {
        throw new Error(
          `[abto] custom property name "${property}" is reserved; $ properties belong to ABTO.`,
        );
      }
    }
  }
  return registry;
}

export interface EventValidationResult {
  valid: boolean;
  issues: string[];
}

export function validateCustomPropertyNames(properties: Record<string, unknown>): string[] {
  return Object.keys(properties)
    .filter((name) => name.startsWith('$'))
    .map((name) => `${name} is reserved; $ properties belong to ABTO`);
}

export function validateEventProperties(
  definition: CustomEventDefinition,
  properties: Record<string, unknown>,
): EventValidationResult {
  const issues = validateCustomPropertyNames(properties);
  for (const [name, property] of Object.entries(definition.properties)) {
    const value = properties[name];
    if (value === undefined) {
      if (property.required === true) issues.push(`${name} is required`);
      continue;
    }
    if (typeof value !== property.type) {
      issues.push(`${name} must be ${property.type}`);
      continue;
    }
    if (property.enum !== undefined && !property.enum.includes(value as never)) {
      issues.push(`${name} must be one of ${property.enum.join(', ')}`);
    }
  }
  return { valid: issues.length === 0, issues };
}
