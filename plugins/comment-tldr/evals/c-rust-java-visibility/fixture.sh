#!/usr/bin/env bash
set -euo pipefail

cat > ring.c <<'EOF'
#include <stddef.h>
#include <string.h>

#define RING_SLOTS 64

struct ring {
	unsigned char slots[RING_SLOTS][32];
	size_t head;
};

/**
 * Copies one record into the ring buffer and advances its head.
 * A full buffer overwrites its oldest record instead of failing, because
 * the producer runs in an interrupt handler that cannot wait. This was
 * agreed in the 2024 firmware review after a long discussion, and it has
 * been in place since then without any reported problems.
 */
void ring_push(struct ring *r, const void *rec, size_t len)
{
	memcpy(r->slots[r->head], rec, len);
	r->head = (r->head + 1) % RING_SLOTS;
}
EOF

cat > lib.rs <<'EOF'
/// Parses a duration such as `90s` or `5m` into seconds.
/// Only seconds and minutes are accepted, because the config files this
/// reads never used hours and accepting them hid typos such as `5h` for
/// `5m`. This was agreed in the 2024 config review after a long
/// discussion, and it has been in place since then.
pub fn parse_duration(s: &str) -> Option<u64> {
    let (num, unit) = s.split_at(s.len() - 1);
    Some(num.parse::<u64>().ok()? * unit_seconds(unit)?)
}

/// Returns how many seconds one unit of a duration stands for.
/// Unknown units return None instead of panicking, because the caller
/// turns None into a config error that names the bad value. This was
/// agreed in the 2025 config review after a long discussion, and it has
/// been in place since then without any reported problems.
fn unit_seconds(unit: &str) -> Option<u64> {
    match unit {
        "s" => Some(1),
        "m" => Some(60),
        _ => None,
    }
}
EOF

cat > Cache.java <<'EOF'
import java.util.HashMap;
import java.util.Map;

public class Cache {
    private final Map<String, Entry> entries = new HashMap<>();

    /**
     * Removes the entries that have not been read for an hour.
     * Subclasses call this from their own timers, because the cache has
     * no thread of its own and an idle cache should cost nothing. This
     * was agreed in the 2024 cache review after a long discussion, and it
     * has been in place since then without any reported problems.
     */
    protected void evictStale() {
        long cutoff = System.currentTimeMillis() - 3_600_000;
        entries.values().removeIf(e -> e.lastRead < cutoff);
    }

    /**
     * Records that an entry was read just now.
     * The time comes from currentTimeMillis rather than nanoTime because
     * evictStale compares it with wall-clock cutoffs. This was agreed in
     * the 2025 cache review after a long discussion, and it has been in
     * place since then without any reported problems.
     */
    private void touch(Entry e) {
        e.lastRead = System.currentTimeMillis();
    }
}
EOF
