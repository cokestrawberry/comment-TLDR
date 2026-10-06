#!/usr/bin/env bash
set -euo pipefail

cat > retry.py <<'EOF'
def fetch_with_retry(client, url):
    # Fetch a URL, retrying on connection resets only.
    # Timeouts are not retried because the upstream proxy already retries
    # them twice, and retrying here as well tripled the load in outages.
    # We chose this after the March 2026 incident review.
    for attempt in range(3):
        try:
            return client.get(url)
        except ConnectionResetError:
            if attempt == 2:
                raise
EOF
