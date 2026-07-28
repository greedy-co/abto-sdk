/**
 * elements_chain serialization — the backbone for post-hoc analysis without pre-tagging.
 * Walks an element up its ancestors into `tag.class#id:attr="value"` segments joined by ';'.
 */

import { maskText } from './privacy.js';
import type { MaskMode } from './types.js';

const MAX_DEPTH = 20;
const TEXT_CAP = 255;
const HREF_CAP = 2048;
const CLASS_CAP = 10;
const CHAIN_CAP = 8192;
const TEXT_NODE = 3;

export function elementText(el: Element, cap = TEXT_CAP): string {
  let text = '';
  for (const node of Array.from(el.childNodes)) {
    if (node.nodeType === TEXT_NODE) text += node.textContent ?? '';
  }
  const normalized = text.trim().replace(/\s+/g, ' ');
  return normalized.length > cap ? normalized.slice(0, cap) : normalized;
}

function nthChild(el: Element): number {
  let position = 1;
  for (let sibling = el.previousElementSibling; sibling; sibling = sibling.previousElementSibling) {
    position++;
  }
  return position;
}

function nthOfType(el: Element): number {
  let position = 1;
  for (let sibling = el.previousElementSibling; sibling; sibling = sibling.previousElementSibling) {
    if (sibling.tagName === el.tagName) position++;
  }
  return position;
}

function escapeAttr(value: string): string {
  return value.replace(/"/g, '\\"');
}

function serializeElement(el: Element, mask: MaskMode): string {
  let head = el.tagName.toLowerCase();
  const rawMetadataAllowed = mask === 'off';
  if (rawMetadataAllowed) {
    const id = el.getAttribute('id');
    if (id) head += `#${id}`;
    const classes = (el.getAttribute('class') ?? '').split(/\s+/).filter(Boolean).slice(0, CLASS_CAP);
    for (const cls of classes) head += `.${cls}`;
  }

  const attrs: string[] = [];
  const text = elementText(el);
  if (text) attrs.push(`text="${escapeAttr(maskText(text, mask))}"`);
  if (rawMetadataAllowed) {
    const href = el.getAttribute('href');
    if (href) attrs.push(`href="${escapeAttr(href.slice(0, HREF_CAP))}"`);
    const role = el.getAttribute('role');
    if (role) attrs.push(`role="${escapeAttr(role)}"`);
    for (const attr of Array.from(el.attributes)) {
      if (attr.name.startsWith('data-abto-')) attrs.push(`${attr.name}="${escapeAttr(attr.value)}"`);
    }
  }
  attrs.push(`nth-child="${nthChild(el)}"`, `nth-of-type="${nthOfType(el)}"`);

  return `${head}:${attrs.join(':')}`;
}

export function serializeElementsChain(el: Element | null, mask: MaskMode = 'off'): string {
  const segments: string[] = [];
  let node: Element | null = el;
  for (let depth = 0; node && depth < MAX_DEPTH; depth++) {
    const tag = node.tagName.toLowerCase();
    if (tag === 'html') break;
    segments.push(serializeElement(node, mask));
    if (tag === 'body') break;
    node = node.parentElement;
  }
  const chain = segments.join(';');
  return chain.length > CHAIN_CAP ? chain.slice(0, CHAIN_CAP) : chain;
}
