#!/usr/bin/env bash
set -euo pipefail

git init -q -b main
git config user.name eval
git config user.email eval@example.com

cat > queue.py <<'EOF'
def push(queue, item):
    # Add an item to the back of the queue.
    # No lock is taken because only the producer thread calls this, and a
    # lock here doubled the latency in the load test. This was agreed in
    # the 2024 queue review after a long discussion, and it has been in
    # place since then without any reported problems.
    queue.append(item)
EOF
git add queue.py
git commit -q -m "Add push"

git checkout -q -b feature
cat >> queue.py <<'EOF'


def pop(queue):
    # Take the item at the front of the queue.
    # An empty queue returns None instead of raising, because the consumer
    # polls it in a loop and treats None as a reason to wait. This was
    # agreed in the 2025 queue review after a long discussion, and it has
    # been in place since then without any reported problems.
    return queue.pop(0) if queue else None
EOF
git commit -q -am "Add pop"
