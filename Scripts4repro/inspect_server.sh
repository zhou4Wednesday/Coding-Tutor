#!/usr/bin/env bash
set -u

echo "=== TRAVER server environment inspection ==="
echo "This script is read-only. It does not install packages, download data, or run inference."
echo

section() {
  echo
  echo "## $1"
}

run_check() {
  local label="$1"
  shift
  echo
  echo "\$ $label"
  "$@" 2>&1 || echo "[WARN] command failed: $label"
}

section "System"
run_check "date" date
run_check "hostname" hostname
run_check "uname -a" uname -a
if [ -f /etc/os-release ]; then
  run_check "cat /etc/os-release" cat /etc/os-release
fi
run_check "pwd" pwd
run_check "disk free" df -h .

section "Shell and Conda"
echo "SHELL=${SHELL:-<unset>}"
echo "CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-<unset>}"
echo "CONDA_PREFIX=${CONDA_PREFIX:-<unset>}"
run_check "which conda" which conda
run_check "conda info --envs" conda info --envs

section "Python"
run_check "which python" which python
run_check "python --version" python --version
run_check "which pip" which pip
run_check "pip --version" pip --version

section "GPU and CUDA"
run_check "nvidia-smi" nvidia-smi
run_check "which nvcc" which nvcc
run_check "nvcc --version" nvcc --version
run_check "which gcc" which gcc
run_check "gcc --version" gcc --version
run_check "which g++" which g++
run_check "g++ --version" g++ --version

section "Selected Environment Variables"
for name in CUDA_HOME CUDA_PATH LD_LIBRARY_PATH TRANSFORMERS_CACHE HF_HOME HF_HUB_CACHE HF_TOKEN OPENAI_API_KEY AZURE_OPENAI_API_KEY AZURE_OPENAI_ENDPOINT; do
  value="${!name-}"
  if [ -z "${value}" ]; then
    echo "${name}=<unset>"
  else
    case "${name}" in
      *KEY*|*TOKEN*)
        echo "${name}=<set, hidden>"
        ;;
      *)
        echo "${name}=${value}"
        ;;
    esac
  fi
done

section "Python Package Versions"
python - <<'PY'
import importlib
import sys

packages = [
    "torch",
    "transformers",
    "vllm",
    "flash_attn",
    "deepspeed",
    "bitsandbytes",
    "peft",
    "accelerate",
    "datasets",
    "tokenizers",
    "safetensors",
    "openai",
    "tiktoken",
    "numpy",
]

print("python_executable:", sys.executable)
print("python_version:", sys.version.replace("\n", " "))

for package in packages:
    try:
        module = importlib.import_module(package)
        version = getattr(module, "__version__", "<no __version__>")
        print(f"{package}: {version}")
    except Exception as exc:
        print(f"{package}: NOT IMPORTABLE ({type(exc).__name__}: {exc})")

try:
    import torch
    print("torch.cuda.is_available:", torch.cuda.is_available())
    print("torch.version.cuda:", torch.version.cuda)
    print("torch.cuda.device_count:", torch.cuda.device_count())
    for idx in range(torch.cuda.device_count()):
        props = torch.cuda.get_device_properties(idx)
        total_gb = props.total_memory / (1024 ** 3)
        print(f"cuda_device_{idx}: {props.name}, capability={props.major}.{props.minor}, total_memory_gb={total_gb:.2f}")
except Exception as exc:
    print(f"torch_cuda_details: UNAVAILABLE ({type(exc).__name__}: {exc})")
PY

section "Repository Files"
for path in \
  docs/reproduction_target.md \
  docs/TRAVER.pdf \
  README.md \
  requirements.txt \
  prompt/namespaces.json \
  prompt/prompt_elements_final.jsonl \
  benchmark/EvoCodeBench-2403/metadata.jsonl \
  scripts/run/run_traver.sh \
  scripts/run/run_engine_student.sh \
  scripts/eval/eval_TOR.py \
  traver/run_traver.py \
  traver/train_verifier.py; do
  if [ -e "${path}" ]; then
    if [ -f "${path}" ]; then
      bytes=$(wc -c < "${path}" 2>/dev/null || echo "?")
      echo "FOUND file ${path} (${bytes} bytes)"
    else
      echo "FOUND dir  ${path}"
    fi
  else
    echo "MISSING ${path}"
  fi
done

section "Configured Data and Model Path Probes"
for path in \
  /code/models \
  /code/models/Mixtral-8x7B-Instruct-v0.1-AWQ \
  /code/models/Mistral-7B-v0.1 \
  /code/models/Meta-Llama-3.1-8B-Instruct \
  /code/models/Meta-Llama-3.1-70B-Instruct \
  /code/models/Qwen2-7B-Instruct \
  /code/models/Qwen2-72B-Instruct \
  /data/EvoCodeBench/EvoCodeBench-2403 \
  /data/EvoCodeBench/EvoCodeBench-2403/Source_Code \
  /data/EvoCodeBench/EvoCodeBench-2403/Dependency_Data; do
  if [ -e "${path}" ]; then
    echo "FOUND ${path}"
  else
    echo "MISSING ${path}"
  fi
done

section "Namespace Split Summary"
python - <<'PY'
import json
from pathlib import Path

path = Path("prompt/namespaces.json")
if not path.exists():
    print("prompt/namespaces.json: missing")
else:
    data = json.loads(path.read_text(encoding="utf-8"))
    part_lists = data.get("part_lists", [])
    print("namespaces_all:", len(data.get("namespaces_all", [])))
    print("num_parts:", data.get("num_parts"))
    print("part_lengths:", [len(part) for part in part_lists])
    if data.get("namespaces_all"):
        print("first_namespace:", data["namespaces_all"][0])
PY

echo
echo "=== Inspection complete ==="
