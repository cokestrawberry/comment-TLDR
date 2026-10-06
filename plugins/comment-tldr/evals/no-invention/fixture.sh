#!/usr/bin/env bash
set -euo pipefail

cat > limits.py <<'EOF'
def clamp_batch(size):
    # The upstream API rejects batches above 500 items with a generic 400
    # error that does not say why. It also counts each batch's metadata
    # record as an item, so 450 leaves room under that limit. This was
    # found during the 2025 migration, when nightly imports failed for a
    # week before anyone traced it to the batch size.
    if size < 1:
        raise ValueError("batch size must be positive")
    return min(size, 450)
EOF
