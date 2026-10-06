#!/usr/bin/env bash
set -euo pipefail

cat > report.py <<'EOF'
# Copyright 2026 Example Corp.
# SPDX-License-Identifier: MIT
# Permission is granted to use, copy, and modify this file under the
# terms of the MIT License; see the LICENSE file for details.

# This module builds the weekly usage report that finance pulls every
# Monday. Totals are rounded down because the billing system truncates
# fractional units, and rounding up made the two disagree. The rule was
# settled after several escalations from the finance team, which took
# most of a quarter to resolve.


def build_report(rows):
    """Build the weekly usage report.

    Groups the rows by account, sums the usage of each account, and
    rounds every total down to a whole unit so the report matches the
    billing system, which truncates fractional units. The rounding rule
    was settled in the 2025 billing review.

    Returns a list of (account, total) pairs sorted by account.
    """
    totals = {}
    for account, units in rows:
        totals[account] = totals.get(account, 0) + units
    return sorted((a, int(t)) for a, t in totals.items())
EOF
