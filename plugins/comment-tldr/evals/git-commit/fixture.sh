#!/usr/bin/env bash
set -euo pipefail

git init -q -b main
git config user.name eval
git config user.email eval@example.com

cat > retry.py <<'EOF'
def backoff(attempt):
    # Return the delay in seconds before the given retry attempt.
    # The delay doubles with each attempt and stops growing at 30 seconds,
    # because the gateway drops idle connections after 60 seconds. This
    # was agreed in the 2024 gateway review after a long discussion, and
    # it has been in place since then without any reported problems.
    return min(2**attempt, 30)
EOF
git add retry.py
git commit -q -m "Add backoff"

cat >> retry.py <<'EOF'


def jitter(delay, rng):
    # Spread a retry delay over a random range around its value.
    # The range is 0.5 to 1.5 times the delay so that clients which failed
    # together do not all retry at the same moment. This was agreed in the
    # 2025 retry review after a long discussion, and it has been in place
    # since then without any reported problems.
    return delay * rng.uniform(0.5, 1.5)
EOF
git commit -q -am "Add jitter"

{ head -n 9 retry.py; cat <<'EOF'; tail -n +10 retry.py; } > retry.py.new
def should_give_up(attempt, started, now):
    # Decide whether to stop retrying a request.
    # Retrying stops after 5 attempts or 120 seconds, whichever comes
    # first, because the client's own timeout is 150 seconds. This was
    # agreed in the 2026 client review after a long discussion, and it
    # has been in place since then without any reported problems.
    return attempt >= 5 or now - started >= 120


EOF
mv retry.py.new retry.py
git commit -q -am "Add should_give_up"
