import { randomBytes as nodeRandomBytes } from 'node:crypto';

export function randomHex(length: number): string {
  return nodeRandomBytes(length).toString('hex');
}

/** Create a canonical, lowercase RFC 9562 UUIDv7 string. */
export function newUuidV7(now = Date.now()): string {
  const timestamp = Math.min(Math.max(Math.floor(now), 0), 0xffff_ffff_ffff);
  const timestampHex = timestamp.toString(16).padStart(12, '0');
  const bytes = nodeRandomBytes(16);

  for (let index = 0; index < 6; index += 1) {
    bytes[index] = Number.parseInt(timestampHex.slice(index * 2, index * 2 + 2), 16);
  }
  bytes[6] = (bytes[6]! & 0x0f) | 0x70;
  bytes[8] = (bytes[8]! & 0x3f) | 0x80;

  const hex = bytes.toString('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

/** W3C trace IDs are 32 hex characters, not UUID strings. */
export function newUuidV7TraceId(): string {
  return newUuidV7().replace(/-/g, '');
}
