// Simple ULID-like ID generator
// Format: timestamp (10 chars) + random (16 chars) = 26 chars
// Sortable by creation time, unique enough for file-based storage

const ENCODING = "0123456789abcdefghjkmnpqrstvwxyz"; // Crockford's Base32

function encodeTime(time: number, length: number): string {
  let str = "";
  for (let i = length - 1; i >= 0; i--) {
    const mod = time % 32;
    str = ENCODING[mod] + str;
    time = Math.floor(time / 32);
  }
  return str;
}

function encodeRandom(length: number): string {
  let str = "";
  for (let i = 0; i < length; i++) {
    str += ENCODING[Math.floor(Math.random() * 32)];
  }
  return str;
}

export function ulid(): string {
  const time = Date.now();
  return encodeTime(time, 10) + encodeRandom(16);
}

// Generate a tracking token in TRK-XXXX-XXXX format
const TOKEN_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ0123456789";

export function trackingToken(): string {
  let part1 = "";
  let part2 = "";
  for (let i = 0; i < 4; i++) {
    part1 += TOKEN_CHARS[Math.floor(Math.random() * TOKEN_CHARS.length)];
    part2 += TOKEN_CHARS[Math.floor(Math.random() * TOKEN_CHARS.length)];
  }
  return `TRK-${part1}-${part2}`;
}
