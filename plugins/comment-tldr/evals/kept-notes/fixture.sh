#!/usr/bin/env bash
set -euo pipefail

cat > cache.js <<'EOF'
/**
 * Picks the cache entry to evict when the cache is full.
 * It scans every entry and returns the one with the oldest access time,
 * because entries are small and the cache rarely holds more than a few
 * hundred of them, so a heap was not worth its complexity. This design
 * came out of the 2024 performance review, where we also looked at an
 * LRU list and a clock algorithm before settling on the linear scan.
 *
 * @param {Map<string, {atime: number}>} entries - The cached entries.
 * @returns {string} The key of the entry to evict.
 */
function pickVictim(entries) {
  // The scan below compares access times only; sizes are ignored on
  // purpose, since every entry is about the same size and weighting by
  // size made eviction order hard to predict when debugging. We tried
  // size-weighted eviction in the 2024 performance review and reverted
  // it after two weeks.
  //
  // TODO(cache): switch to a heap if the cache grows past 10k entries.
  let victim = null;
  let oldest = Infinity;
  for (const [key, { atime }] of entries) {
    if (atime < oldest) {
      oldest = atime;
      victim = key;
    }
  }
  return victim;
}

export function evict(entries) {
  return pickVictim(entries);
}
EOF
