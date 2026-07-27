/**
 * Privacy layer — raw prompt/response 텍스트를 capture mode 에 맞는 파생 메타로 변환한다.
 *
 * Raw content is opt-in. Default capture modes retain derived metadata only,
 * and DOM text/value stays masked unless data-abto-include explicitly allows it.
 */

import type {
  CaptureMode,
  DerivedTextMeta,
  MaskMode,
  SensitiveCategory,
  TokenBucket,
} from './types.js';

/* ────────────────────────────────────────────────────────────────────────
 * DOM markers (Part 3 §9, §33)
 *
 * Mirrors PostHog's ph-no-capture / ph-sensitive / ph-include with ABTO-owned
 * attributes so it can coexist with PostHog.
 * ──────────────────────────────────────────────────────────────────────── */

export const NO_CAPTURE_ATTR = 'data-abto-no-capture';
export const SENSITIVE_ATTR = 'data-abto-sensitive';
export const INCLUDE_ATTR = 'data-abto-include';

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
export type DomCapturePolicy = 'no-capture' | 'sensitive' | 'include' | 'default';

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

/* ────────────────────────────────────────────────────────────────────────
 * Derived value helpers (Part 4 §15)
 * ──────────────────────────────────────────────────────────────────────── */

/** Map an exact token estimate into a coarse bucket so we don't leak length. */
export function tokenBucket(tokens: number): TokenBucket {
  if (tokens <= 0) return '0';
  if (tokens <= 50) return '1-50';
  if (tokens <= 200) return '51-200';
  if (tokens <= 500) return '201-500';
  if (tokens <= 1000) return '501-1000';
  if (tokens <= 2000) return '1001-2000';
  return '2000+';
}

/** Very rough token estimate (~4 chars/token). Replace with a real tokenizer if needed. */
export function estimateTokens(text: string): number {
  return Math.ceil(text.length / 4);
}

/**
 * Salted SHA-256 hash, returned as `sha256:<hex>`.
 * Async because SubtleCrypto is async. TODO: sync fallback for non-secure
 * contexts (currently returns a marker so we never accidentally ship raw text).
 */
export async function saltedHash(text: string, salt = ''): Promise<string> {
  const subtle = globalThis.crypto?.subtle;
  if (!subtle) return 'sha256:unavailable';
  const bytes = new TextEncoder().encode(`${salt}\u0000${text}`);
  const digest = await subtle.digest('SHA-256', bytes);
  const hex = Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
  return `sha256:${hex}`;
}

/* ── lightweight content heuristics (Part 4 §15) ───────────────────────────
 * These are intentionally cheap and conservative. The semantic task/PII
 * classifier is a P2 item (Part 6 §29). TODO: pluggable classifier hook.
 */

const CODE_HINT = /(function\s|=>|;\n|\{\n|import\s|class\s|def\s|<\/?[a-z]+>)/;
const PII_PATTERN =
  String.raw`(\b\d{3}-\d{2}-\d{4}\b|\b\d{16}\b|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,})`;
const SECRET_PATTERN =
  String.raw`(sk-[A-Za-z0-9]{16,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]+KEY-----)`;
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
  // TODO: healthcare/legal/finance classification (P2).
  return null;
}

/* ────────────────────────────────────────────────────────────────────────
 * The main entry point
 * ──────────────────────────────────────────────────────────────────────── */

export interface DeriveOptions {
  salt?: string;
}

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
 * Convert raw text into the metadata permitted by `mode`.
 *
 * The host app passes the raw text; this function guarantees the raw text never
 * appears in the returned object unless an explicit opt-in mode was chosen.
 */
export async function deriveTextMeta(
  text: string,
  mode: CaptureMode,
  opts: DeriveOptions = {},
): Promise<DerivedTextMeta> {
  const meta: DerivedTextMeta = { capture_mode: mode };

  if (mode === 'off') return meta;

  // hash is included for every non-off mode (cheap join key without content).
  meta.hash = await saltedHash(text, opts.salt ?? '');
  if (mode === 'hash') return meta;

  // metadata_only and full: length + bucket + heuristic flags.
  meta.length_chars = text.length;
  meta.token_bucket = tokenBucket(estimateTokens(text));
  meta.contains_code = containsCode(text);
  meta.pii_detected = detectPII(text);
  meta.sensitive_category = detectSensitiveCategory(text);
  if (mode === 'metadata_only') return meta;

  // mode === 'full' — strong opt-in. Callers must enforce consent/retention.
  meta.excerpt = text;
  return meta;
}
