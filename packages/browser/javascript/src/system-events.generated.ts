// GENERATED FILE — DO NOT EDIT.

export const ABTO_SCHEMA_VERSION = "2026-07-15" as const;
export const ABTO_EVENT_NAME_MAX_LENGTH = 200 as const;

export const BROWSER_SYSTEM_EVENT_WIRE_NAMES = {
  "$pageview": "pageview",
  "$pageleave": "pageleave",
  "$autocapture": "interaction_autocaptured",
  "$rageclick": "interaction_rageclick",
  "$dead_click": "interaction_deadclick",
  "$ai_prompt_submitted": "llm_prompt_submitted",
  "$ai_response_rendered": "llm_response_rendered",
  "$ai_response_interacted": "llm_response_interacted"
} as const;

export const BROWSER_SYSTEM_EVENTS = [
  "$pageview",
  "$pageleave",
  "$autocapture",
  "$rageclick",
  "$dead_click",
  "$ai_prompt_submitted",
  "$ai_response_rendered",
  "$ai_response_interacted"
] as const;

export type BrowserSystemEventName = (typeof BROWSER_SYSTEM_EVENTS)[number];
export type BrowserSystemEventWireName =
  (typeof BROWSER_SYSTEM_EVENT_WIRE_NAMES)[BrowserSystemEventName];

export function toBrowserSystemEventWireName(name: string): string {
  if (!Object.prototype.hasOwnProperty.call(BROWSER_SYSTEM_EVENT_WIRE_NAMES, name)) return name;
  return BROWSER_SYSTEM_EVENT_WIRE_NAMES[name as BrowserSystemEventName];
}
