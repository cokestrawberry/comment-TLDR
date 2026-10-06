#!/usr/bin/env bash
set -euo pipefail

cat > rows.py <<'EOF'
def read_rows(path):
    # Read the raw rows of an export file.
    # The file is opened in binary mode because some exports contain
    # stray NUL bytes, and text mode raises on them under Windows.

    # The NUL bytes come from the legacy exporter, which pads fixed-width
    # fields with them, and the exporter team has no date for a fix.
    # Opening in text mode with errors="ignore" still raised on them.

    # This approach was agreed in the Q3 planning meeting after a long
    # discussion, and it has been in place since release 2.4.
    with open(path, "rb") as f:
        data = f.read()
    text = data.replace(b"\x00", b"").decode("utf-8")
    return [line.split(",") for line in text.splitlines()]
EOF
