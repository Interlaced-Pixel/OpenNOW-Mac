#!/bin/bash

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
MANIFEST="$ROOT/Docs/NVST/NativeNVSTRuntimeManifest.json"
FRAMEWORKS="$ROOT/vendor/nvidia-gfn/Frameworks"

/usr/bin/python3 - "$MANIFEST" "$FRAMEWORKS" <<'PY'
import hashlib
import json
import pathlib
import re
import subprocess
import sys

manifest_path = pathlib.Path(sys.argv[1])
frameworks = pathlib.Path(sys.argv[2])
manifest = json.loads(manifest_path.read_text())

for artifact in manifest["artifacts"]:
    path = frameworks / artifact["path"]
    if not path.is_file():
        raise SystemExit(f"Missing native NVST artifact: {path}")
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    if digest != artifact["sha256"]:
        raise SystemExit(f"Native NVST SHA-256 mismatch: {artifact['path']}")
    output = subprocess.check_output(["dwarfdump", "--uuid", str(path)], text=True)
    uuids = {architecture: uuid.upper() for uuid, architecture in re.findall(r"UUID: ([0-9A-F-]+) \(([^)]+)\)", output)}
    if uuids.get("arm64") != artifact["arm64UUID"] or uuids.get("x86_64") != artifact["x86_64UUID"]:
        raise SystemExit(f"Native NVST Mach-O UUID mismatch: {artifact['path']}")

print(f"Validated {len(manifest['artifacts'])} native NVST artifacts.")
PY
