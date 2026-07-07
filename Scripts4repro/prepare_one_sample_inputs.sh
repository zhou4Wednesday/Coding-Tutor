#!/usr/bin/env bash
set -euo pipefail

SMOKE_DIR="${SMOKE_DIR:-tmp/repro_smoke}"
PROMPT_SOURCE="${PROMPT_SOURCE:-prompt/prompt_elements_final.jsonl}"
NAMESPACE_SOURCE="${NAMESPACE_SOURCE:-prompt/namespaces.json}"

mkdir -p "${SMOKE_DIR}"

python - <<'PY'
import json
import os
from pathlib import Path

smoke_dir = Path(os.environ.get("SMOKE_DIR", "tmp/repro_smoke"))
prompt_source = Path(os.environ.get("PROMPT_SOURCE", "prompt/prompt_elements_final.jsonl"))
namespace_source = Path(os.environ.get("NAMESPACE_SOURCE", "prompt/namespaces.json"))

if not prompt_source.exists():
    raise SystemExit(f"Missing prompt source: {prompt_source}")
if not namespace_source.exists():
    raise SystemExit(f"Missing namespace source: {namespace_source}")

with prompt_source.open("r", encoding="utf-8") as f:
    first = json.loads(next(line for line in f if line.strip()))

namespace = first["namespace"]
prompt_out = smoke_dir / "prompt_one_sample.jsonl"
namespace_out = smoke_dir / "namespaces_one_sample.json"

with prompt_out.open("w", encoding="utf-8") as f:
    f.write(json.dumps(first, ensure_ascii=False) + "\n")

namespace_payload = {
    "namespaces_all": [namespace],
    "num_parts": 1,
    "part_lists": [[namespace]],
}
with namespace_out.open("w", encoding="utf-8") as f:
    json.dump(namespace_payload, f, ensure_ascii=False, indent=2)
    f.write("\n")

print(f"namespace={namespace}")
print(f"prompt_file={prompt_out}")
print(f"namespace_file={namespace_out}")
PY

