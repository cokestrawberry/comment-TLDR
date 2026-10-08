#!/usr/bin/env bash
set -euo pipefail

cat > config.py <<'EOF'
import json

DEFAULTS = {"retries": 3, "timeout": 10}


def load_config(path):
    # Load the settings file and fill in defaults for missing keys.
    # The file is parsed as JSON rather than YAML because the deploy image
    # ships without PyYAML and cannot install packages at startup.
    with open(path) as f:
        data = json.load(f)
    # That choice was settled in the 2024 image review, which also weighed
    # vendoring PyYAML and converting the settings at build time, before
    # the team kept JSON as the format with the fewest moving parts.
    for key, value in DEFAULTS.items():
        data.setdefault(key, value)
    return data
EOF
