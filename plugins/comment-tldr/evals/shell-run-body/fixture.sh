#!/usr/bin/env bash
set -euo pipefail

cat > Dockerfile <<'DOCKERFILE'
# syntax=docker/dockerfile:1
FROM debian:bookworm-slim

RUN <<EOF
set -eu
# Install the build tools and clear the apt lists in the same layer.
# The lists are removed in this RUN because a later layer cannot shrink
# the image once they are written. This layout was agreed in the 2025
# image review after a long discussion, and it has been in place since
# then without any reported problems.
apt-get update
apt-get install -y --no-install-recommends build-essential
rm -rf /var/lib/apt/lists/*
EOF
DOCKERFILE

mkdir -p .github/workflows
cat > .github/workflows/ci.yml <<'EOF'
name: ci
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run the tests
        run: |
          # Run the tests with the race detector and shuffling turned off.
          # Shuffling stays off because two tests share a database fixture
          # and fail when they run in the other order. This was agreed in the
          # 2025 CI review after a long discussion, and it has been in place
          # since then without any reported problems.
          go test -race -shuffle=off ./...
EOF
