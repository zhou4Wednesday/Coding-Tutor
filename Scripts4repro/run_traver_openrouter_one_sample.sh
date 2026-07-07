#!/usr/bin/env bash
set -euo pipefail

SMOKE_DIR="${SMOKE_DIR:-tmp/repro_smoke}"
OUTPUT_DIR="${OUTPUT_DIR:-outputs/smoke_traver_one_sample}"
LOG_DIR="${LOG_DIR:-logs}"

STUDENT_MODEL_PATH="${STUDENT_MODEL_PATH:-$HOME/traver/student}"
VERIFIER_BASE_MODEL_PATH="${VERIFIER_BASE_MODEL_PATH:-$HOME/traver/verifier_model}"
VERIFIER_MODEL_DIR="${VERIFIER_MODEL_DIR:-$HOME/traver/verifier_checkpoint}"

TUTOR_MODEL_NAME="${TUTOR_MODEL_NAME:-openai/gpt-4o}"
TUTOR_OPENAI_BASE_URL="${TUTOR_OPENAI_BASE_URL:-https://openrouter.ai/api/v1}"
OPENROUTER_API_KEY_FILE="${OPENROUTER_API_KEY_FILE:-}"

STUDENT_LEVEL="${STUDENT_LEVEL:-low_level}"
STUDENT_ENDPOINT="${STUDENT_ENDPOINT:-http://localhost:8002/v1}"
VLLM_API_KEY="${VLLM_API_KEY:-EMPTY}"
TUTOR_SETTING="${TUTOR_SETTING:-traver_openrouter_smoke}"
TUTOR_NUM_RESPONSES="${TUTOR_NUM_RESPONSES:-1}"
MAX_INTERACTION_ROUND="${MAX_INTERACTION_ROUND:-1}"
RUN_GPU_ID="${RUN_GPU_ID:-1}"

mkdir -p "${OUTPUT_DIR}" "${LOG_DIR}"

if [ -z "${OPENROUTER_API_KEY_FILE}" ]; then
  if [ -z "${OPENROUTER_API_KEY:-}" ]; then
    echo "Set OPENROUTER_API_KEY or OPENROUTER_API_KEY_FILE before running." >&2
    exit 1
  fi
  OPENROUTER_API_KEY_FILE="${SMOKE_DIR}/openrouter_api_key.txt"
  mkdir -p "${SMOKE_DIR}"
  printf '%s\n' "${OPENROUTER_API_KEY}" > "${OPENROUTER_API_KEY_FILE}"
  chmod 600 "${OPENROUTER_API_KEY_FILE}"
fi

for path in "${STUDENT_MODEL_PATH}" "${VERIFIER_BASE_MODEL_PATH}" "${VERIFIER_MODEL_DIR}"; do
  if [ ! -e "${path}" ]; then
    echo "Missing required path: ${path}" >&2
    exit 1
  fi
done

bash Scripts4repro/prepare_one_sample_inputs.sh

cmd=(
  python traver/run_traver.py
  --tutor_setting "${TUTOR_SETTING}"
  --namespace_file "${SMOKE_DIR}/namespaces_one_sample.json"
  --prompt_element_file "${SMOKE_DIR}/prompt_one_sample.jsonl"
  --output_dir "${OUTPUT_DIR}"
  --use_KT true
  --verifier_base_model_path "${VERIFIER_BASE_MODEL_PATH}"
  --verifier_model_dir "${VERIFIER_MODEL_DIR}"
  --verifier_model_parts 0
  --tutor_model_name_or_path "${TUTOR_MODEL_NAME}"
  --tutor_openai_base_url "${TUTOR_OPENAI_BASE_URL}"
  --tutor_num_responses "${TUTOR_NUM_RESPONSES}"
  --student_model_name_or_path "${STUDENT_MODEL_PATH}"
  --student_setting "${STUDENT_LEVEL}"
  --api_key_file "${OPENROUTER_API_KEY_FILE}"
  --vllm_api_key "${VLLM_API_KEY}"
  --vllm_endpoint_student "${STUDENT_ENDPOINT}"
  --max_interaction_round "${MAX_INTERACTION_ROUND}"
  --show_description false
  --show_message false
)

echo "Running OpenRouter TRAVER one-sample smoke test"
printf ' %q' "${cmd[@]}"
echo

CUDA_VISIBLE_DEVICES="${RUN_GPU_ID}" "${cmd[@]}" | tee "${LOG_DIR}/traver_openrouter_one_sample.log"

