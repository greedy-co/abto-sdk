/**
 * RFC 9562 UUIDv7 helpers for browser-generated identifiers.
 *
 * UUIDv7 carries the current Unix timestamp in its first 48 bits, so event and
 * identity records retain useful insertion locality without a UUID dependency.
 */

function randomBytes(length: number): Uint8Array {
  const bytes = new Uint8Array(length);
  const cryptoObj = globalThis.crypto;
  if (cryptoObj?.getRandomValues) {
    cryptoObj.getRandomValues(bytes);
    return bytes;
  }

  for (let index = 0; index < length; index += 1) {
    bytes[index] = Math.floor(Math.random() * 256);
  }
  return bytes;
}

export function randomHex(length: number): string {
  return Array.from(randomBytes(length), (byte) => byte.toString(16).padStart(2, '0')).join('');
}

/** Create a canonical, lowercase UUIDv7 string. */
export function newUuidV7(now = Date.now()): string {
  const timestamp = Math.min(Math.max(Math.floor(now), 0), 0xffff_ffff_ffff);
  const timestampHex = timestamp.toString(16).padStart(12, '0');
  const bytes = randomBytes(16);

  for (let index = 0; index < 6; index += 1) {
    bytes[index] = Number.parseInt(timestampHex.slice(index * 2, index * 2 + 2), 16);
  }
  bytes[6] = (bytes[6]! & 0x0f) | 0x70;
  bytes[8] = (bytes[8]! & 0x3f) | 0x80;

  const hex = Array.from(bytes, (byte) => byte.toString(16).padStart(2, '0')).join('');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

/** W3C trace IDs are 32 hex characters, not UUID strings. */
export function newUuidV7TraceId(): string {
  return newUuidV7().replace(/-/g, '');
}
