#!/usr/bin/env bash
set -euo pipefail

cat > release.py <<'EOF'
import tarfile
from hashlib import sha256


def build_release(src, out):
    # Build a release archive from a source tree.
    # First collect the files to ship, leaving out the tests directory and
    # compiled .pyc files. Then write a manifest that lists each file with
    # its SHA-256 digest. Finally pack the manifest and the files into a
    # gzip-compressed tarball, manifest first.
    #
    # The manifest goes first in the archive because the installer checks
    # each digest while it unpacks, and a manifest at the end would make it
    # read the whole archive twice. This was settled in the 2025 packaging
    # review after a zip archive was tried and dropped.
    files = [p for p in src.rglob("*") if p.is_file()]
    files = [p for p in files if "tests" not in p.parts and p.suffix != ".pyc"]
    lines = [f"{sha256(p.read_bytes()).hexdigest()}  {p.relative_to(src)}" for p in files]
    manifest = out.with_suffix(".manifest")
    manifest.write_text("\n".join(lines) + "\n")
    with tarfile.open(out, "w:gz") as tar:
        tar.add(manifest, arcname="MANIFEST")
        for p in files:
            tar.add(p, arcname=p.relative_to(src))
EOF
