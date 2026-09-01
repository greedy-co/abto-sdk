/**
 * Privacy layer for prompt metadata and DOM text masking.
 *
 * Raw content is opt-in. Default capture modes retain derived metadata only,
 * and DOM text/value stays masked unless data-abto-include explicitly allows it.
 */

import type { CaptureMode, MaskMode, SensitiveCategory } from './types.js';

/* ────────────────────────────────────────────────────────────────────────
 * DOM capture markers
 *
 * Mirrors PostHog's ph-no-capture / ph-sensitive / ph-include with ABTO-owned
 * attributes so it can coexist with PostHog.
 * ──────────────────────────────────────────────────────────────────────── */

const NO_CAPTURE_ATTR = 'data-abto-no-capture';
const SENSITIVE_ATTR = 'data-abto-sensitive';
const INCLUDE_ATTR = 'data-abto-include';

/**
 * Walk from `el` up to the document root looking for a capture marker.
 * `no-capture` and `sensitive` are security boundaries and always win over an
 * inner `include`. This prevents a deeply nested element from weakening a
 * parent container's policy.
 *
 * - `no-capture` : drop the event entirely.
 * - `sensitive`  : capture the event but never the text payload.
 * - `include`    : explicit allow when no sensitive/no-capture ancestor exists.
 * - `default`    : follow the configured capture mode.
 */
type DomCapturePolicy = 'no-capture' | 'sensitive' | 'include' | 'default';

export function resolveDomPolicy(el: Element | null): DomCapturePolicy {
  let sensitive = false;
  let include = false;
  let node: Element | null = el;
  while (node) {
    if (node.hasAttribute(NO_CAPTURE_ATTR)) return 'no-capture';
    if (node.hasAttribute(SENSITIVE_ATTR)) sensitive = true;
    if (node.hasAttribute(INCLUDE_ATTR)) include = true;
    node = node.parentElement;
  }
  if (sensitive) return 'sensitive';
  if (include) return 'include';
  return 'default';
}

/**
 * Salted SHA-256 hash, returned as `sha256:<hex>`.
 * Async because SubtleCrypto is async. When it is unavailable, return a marker
 * rather than risk sending raw text.
 */
async function saltedHash(text: string, salt: string): Promise<string> {
  const subtle = globalThis.crypto?.subtle;
  if (!subtle) return 'sha256:unavailable';
  const bytes = new TextEncoder().encode(`${salt}\u0000${text}`);
  const digest = await subtle.digest('SHA-256', bytes);
  const hex = Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
  return `sha256:${hex}`;
}

/* ── Lightweight content heuristics. These are intentionally cheap and conservative. */

const CODE_HINT = /(function\s|=>|;\n|\{\n|import\s|class\s|def\s|<\/?[a-z]+>)/;
const PII_PATTERN =
  String.raw`(\b\d{3}-\d{2}-\d{4}\b|\b\d{16}\b|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,})`;
const SECRET_PATTERN =
  String.raw`(ck-abto-[A-Za-z0-9]{16,}|sk-[A-Za-z0-9]{16,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]+KEY-----)`;
const PII_HINT = new RegExp(PII_PATTERN);
const SECRET_HINT = new RegExp(SECRET_PATTERN);
const PII_REDACTION = new RegExp(PII_PATTERN, 'g');
const SECRET_REDACTION = new RegExp(SECRET_PATTERN, 'g');

function containsCode(text: string): boolean {
  return CODE_HINT.test(text);
}

function detectPII(text: string): boolean {
  return PII_HINT.test(text);
}

function detectSensitiveCategory(text: string): SensitiveCategory {
  if (SECRET_HINT.test(text)) return 'credential';
  if (PII_HINT.test(text)) return 'pii';
  return null;
}

/* ────────────────────────────────────────────────────────────────────────
 * The main entry point
 * ──────────────────────────────────────────────────────────────────────── */

/** Mask runs that look like PII / secrets before producing an excerpt. */
function redact(text: string): string {
  let out = text;
  out = out.replace(SECRET_REDACTION, '«redacted-secret»');
  out = out.replace(PII_REDACTION, '«redacted-pii»');
  return out;
}

/** Sync DOM text/value masking. 'sensitive' redacts PII/secret runs; 'all' replaces content with a length marker. */
export function maskText(text: string, mode: MaskMode): string {
  if (mode === 'off' || text === '') return text;
  if (mode === 'all') return `«masked:${text.length}»`;
  return redact(text);
}

/**
 * Convert raw prompt text into the metadata permitted by a non-full mode.
 * Full capture is handled by the caller and never reaches this helper.
 */
interface DerivedPromptMeta {
  hash?: string;
  lengthChars?: number;
  containsCode?: boolean;
  piiDetected?: boolean;
  sensitiveCategory?: SensitiveCategory;
}

export async function derivePromptMeta(
  text: string,
  mode: Exclude<CaptureMode, 'full'>,
  projectKey: string,
): Promise<DerivedPromptMeta> {
  if (mode === 'off') return {};

  const hash = await saltedHash(text, projectKey);
  if (mode === 'hash') return { hash };

  return {
    hash,
    lengthChars: text.length,
    containsCode: containsCode(text),
    piiDetected: detectPII(text),
    sensitiveCategory: detectSensitiveCategory(text),
  };
}
