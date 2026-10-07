#!/usr/bin/env bash
set -euo pipefail

git init -q

cat > server.py <<'EOF'
def handle(request):
    # Answer a request from the cache when it holds a fresh copy.
    # Copies older than five minutes are refetched because the upstream
    # prices change at most every five minutes. This was agreed in the
    # 2025 pricing review after a long discussion, and it has been in
    # place since then without any reported problems.
    return cache.get_fresh(request.key, max_age=300) or fetch(request)
EOF

mkdir -p tools
cat > tools/cleanup.py <<'EOF'
def remove_old_logs(log_dir):
    # Delete the log files older than thirty days.
    # The age comes from each file's modification time because the log
    # names do not carry a date. This was agreed in the
    # 2024 operations review after a long discussion, and it has been in
    # place since then without any reported problems.
    cutoff = time.time() - 30 * 86400
    for path in log_dir.glob("*.log"):
        if path.stat().st_mtime < cutoff:
            path.unlink()
EOF

git add server.py tools/cleanup.py
