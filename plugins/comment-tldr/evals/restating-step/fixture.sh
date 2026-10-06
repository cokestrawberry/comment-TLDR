#!/usr/bin/env bash
set -euo pipefail

cat > export.py <<'EOF'
import csv
import logging

log = logging.getLogger(__name__)


def export_report(rows, path):
    # Export the report rows to a CSV file.
    # First take the header from the first row and write every row under
    # it, so the columns keep the order the caller built them in. Finally,
    # log how many rows were exported.
    #
    # The file is opened with newline="" because the csv module writes its
    # own line endings, and Windows otherwise shows a blank line between
    # rows. We picked csv over pandas in the 2025 tooling review to keep
    # this script free of heavy dependencies.
    header = list(rows[0].keys())
    with open(path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=header)
        writer.writeheader()
        writer.writerows(rows)
    log.info("exported %d rows", len(rows))
EOF
