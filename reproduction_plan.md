# TRAVER Reproduction Plan

## Scope

This project uses TRAVER as a baseline for a tutoring benchmark. The current target is not to reproduce every result in the paper. The immediate goal is:

1. Run a one-sample smoke test of the released TRAVER tutoring workflow.
2. Run the original DICT evaluation workflow on a small subset.
3. Use the results to understand TRAVER's behavior and evaluation pipeline.

The paper is "Training Turn-by-Turn Verifiers for Dialogue Tutoring Agents: The Curious Case of LLMs as Your Coding Tutors". The local paper file is `docs/TRAVER.pdf`; the target statement is `docs/reproduction_target.md`.

## Paper Experiment To Reproduce

The relevant paper experiment is the TRAVER tutor evaluated with DICT:

- A tutor agent teaches a simulated student on coding tasks.
- The simulated student is tested before and after tutoring.
- Post-test code generation is evaluated with dependency recall and unit-test pass metrics.
- Tutoring outcome is measured from the improvement between pre-test and post-test.
- TRAVER uses knowledge tracing plus a trained turn-by-turn verifier to select among multiple tutor responses.

For the current stage, the target is a smoke-test version of this workflow, not a full training or full evaluation run.

## Repository Mapping

### Paper and instructions

- Target statement: `docs/reproduction_target.md`
- Paper PDF: `docs/TRAVER.pdf`
- Project README: `README.md`
- Python dependencies: `requirements.txt`

### Main entry points

- Baseline tutoring dialogue:
  - `scripts/run/run_base.sh`
  - `traver/run_base.py`
- TRAVER tutoring dialogue:
  - `scripts/run/run_traver.sh`
  - `traver/run_traver.py`
- Student vLLM server:
  - `scripts/run/run_engine_student.sh`
- Tutor vLLM server for open-weight tutor models:
  - `scripts/run/run_engine_tutor.sh`
- Verifier-data preparation:
  - `scripts/run/prepare_verifier_darta.sh`
  - `traver/verifier/preprocess_data.py`
- Verifier training:
  - `scripts/run/run_verifier.sh`
  - `traver/train_verifier.py`
- Pre-test:
  - `scripts/run/run_pretest.sh`
  - `traver/utils/make_prompt.py`
  - `traver/utils/LM_inference.py`
  - `traver/parser/recall_k.py`
  - `traver/parser/pass_k.py`
- Post-test code generation:
  - `scripts/run/run_code_gen.sh`
  - `traver/utils/make_prompt.py`
  - `traver/utils/LM_inference.py`
  - `traver/utils/process_completion.py`
- Coding-test metrics:
  - `scripts/run/run_coding_test.sh`
  - `traver/parser/recall_k.py`
  - `traver/parser/pass_k.py`
- Result summary and plotting:
  - `scripts/eval/eval_pretest.py`
  - `scripts/eval/eval_TOR.py`
  - `scripts/eval/eval_TOC.py`

## Stage Separation

### 1. Environment inspection

Run only read-only checks on the Linux GPU server:

```bash
bash Scripts4repro/inspect_server.sh
```

This should be run after activating the conda environment intended for reproduction.

### 2. One-sample smoke test

The first runnable experiment should use one namespace from `prompt/namespaces.json`, one student level, and one tutor setting. It should verify:

- the student vLLM server can start;
- the tutor path can produce a response;
- the output JSON format is compatible with downstream scripts;
- no full dataset, full multi-level run, or full verifier training is triggered.

### 3. Dialogue inference

Dialogue generation is handled by `traver/run_base.py` or `traver/run_traver.py`.

Important settings:

- `max_interaction_round`: default 8
- `max_latest_messages`: default 8
- tutor `temperature`: default 0.4
- tutor `top_p`: default 0.95
- tutor max tokens: default 300
- student max tokens: default 300
- student backend temperature/top_p in code: 0.4 / 0.95
- moderator backend temperature/top_p in code: 0.1 / 0.95

TRAVER-specific settings:

- verifier base model: `Mistral-7B-v0.1`
- verifier checkpoint dir: `output/verifier_model`
- verifier fold parts: default `0,1,2,3,4`
- verifier max length: default 2000
- `tutor_num_responses`: default in `run_traver.py` is 1; `scripts/run/run_traver.sh` sets 10 for GPT-4o.

### 4. Verifier training

Verifier training is not part of the first smoke test unless the released verifier checkpoint is unavailable or incompatible.

Repository training settings in `scripts/run/run_verifier.sh`:

- base model: `/code/models/Mistral-7B-v0.1`
- data: `output/verifier_data`
- folds: `part0` through `part4`
- max length: 2200
- per-device train batch size: 2
- gradient accumulation: 8
- fp16: true
- learning rate: 1e-5
- epochs: 3
- DeepSpeed config: `config/deepspeed_config_s2.json`
- save steps: 100
- eval steps: 500

### 5. Pre-test and post-test

Code generation uses vLLM through `traver/utils/LM_inference.py`.

Important settings:

- decoding: `sampling`
- `N`: 10
- temperature: default 0.4
- top_p: default 0.95
- context window: default 20000
- max tokens: default 500
- max interaction rounds for post-test prompt construction: 8
- max cognitive load: 60 words

### 6. Evaluation and summary

Evaluation computes:

- Recall@k using `traver/parser/recall_k.py` and `scripts/eval/eval_utils.py`
- Pass@k using `traver/parser/pass_k.py` and `scripts/eval/eval_utils.py`
- TOR in `scripts/eval/eval_TOR.py`
- TO curves in `scripts/eval/eval_TOC.py`

Default k values are `1,3,5,10`; default `n` is 10.

## Models, Checkpoints, Data, APIs

### Models and checkpoints

- Tutor models:
  - `gpt-3.5`
  - `gpt-4o`
  - `Meta-Llama-3.1-8B-Instruct`
  - `Meta-Llama-3.1-70B-Instruct`
  - `Qwen2-7B-Instruct`
  - `Qwen2-72B-Instruct`
- Student simulator:
  - `Mixtral-8x7B-Instruct-v0.1-AWQ`
- Verifier base model:
  - `Mistral-7B-v0.1`
- Released verifier checkpoint:
  - README points to `jwanglvy/Verifier-7B`

### Data

- Full dataset expected by scripts:
  - EvoCodeBench-2403
  - `Source_Code`
  - `Dependency_Data`
  - metadata file such as `metadata.jsonl` or `data_final.jsonl`
- Local repository includes:
  - `benchmark/EvoCodeBench-2403/metadata.jsonl`
  - `prompt/namespaces.json`
  - `prompt/prompt_elements_final.jsonl`
  - zipped released outputs under `output/`

`prompt/namespaces.json` contains 100 namespaces split into 5 folds of 20 each. This appears to correspond to the paper's preprocessed target-task set. The local benchmark metadata has 275 rows and should not be treated as the final evaluation split without checking how the paper filtered it.

### External APIs

- Azure OpenAI API for GPT tutor models.
- Required values:
  - API key file path
  - Azure endpoint
  - deployment names
  - API version

Never commit API keys, endpoint secrets, `.env` files, datasets, model weights, or downloaded checkpoints.

## Public Resource Assessment

- Official repository is public.
- EvoCodeBench is publicly referenced, but the server must still download the full dataset and build its execution environment.
- `jwanglvy/Verifier-7B` is publicly referenced by the README.
- Qwen and Mixtral model repos are public in normal Hugging Face usage.
- Llama-3.1 models may require Hugging Face access approval and license acceptance.
- GPT-3.5, GPT-4o, and o1-mini are not downloadable public resources; they require Azure OpenAI credentials and matching deployment names.

## Paper vs Repository Defaults

Known matches:

- Student simulator is Mixtral-8x7B-Instruct-AWQ.
- Dialogue max turns are 8.
- Temperature/top_p defaults are 0.4/0.95 for tutor and student generation.
- Evaluation uses Recall@k and Pass@k with k in `1,3,5,10`.
- `prompt/namespaces.json` uses 5 folds of 20 namespaces.

Known mismatches or issues:

- README says `prepare_verifier_data.sh`, but the repository file is `scripts/run/prepare_verifier_darta.sh`.
- `scripts/run/run_base.sh` branches on `$tutor_model` before defining it.
- Some scripts use `mid_level`; the Python code and most paths use `med_level`.
- `scripts/run/run_coding_test.sh` uses `metadata_file=EvoCodeBench-2403/metadata.jsonl`, while the local repository path is `benchmark/EvoCodeBench-2403/metadata.jsonl` and the server full dataset path is likely different.
- `scripts/run/run_pretest.sh` uses `$ROOT/data_final.jsonl`, while other scripts use `metadata.jsonl`.
- The scripts contain placeholder local paths such as `/code/models` and `/data/EvoCodeBench/EvoCodeBench-2403`.
- `scripts/run/run_traver.sh` is configured for TRAVER with `gpt-4o` and `tutor_num_responses=10`, not every paper setting.
- Paper reports different candidate counts for some tutor models; the script default only covers one configuration.

These should be documented as compatibility fixes if changed. They should not be hidden as methodological changes.

## Missing Information Needed For Full Reproduction

- Exact Azure OpenAI deployment names available on the server.
- Exact GPT model snapshots available behind each Azure deployment.
- Whether the released verifier checkpoint contains all 5 folds in the path layout expected by `traver/run_traver.py`.
- Exact model paths on the server for Mistral, Mixtral-AWQ, Qwen, and Llama models.
- Whether Llama model access has already been granted.
- Exact EvoCodeBench directory layout after server download.
- Whether `metadata.jsonl` or `data_final.jsonl` is the authoritative file for each script.
- How the 100 target namespaces were selected from the 275-row local metadata file.
- Whether released zipped outputs under `output/` are intended for evaluation reuse or only examples.
- Exact expected result table or figure target for the baseline run.
- Random seeds for vLLM sampling and any server-side deterministic settings; many generation paths do not explicitly set a seed.

## Compatibility Risks

### PyTorch and CUDA

`requirements.txt` pins `torch==2.4.0`. The server must have a compatible NVIDIA driver and CUDA runtime. Check this before installing CUDA-dependent packages.

### vLLM

`requirements.txt` pins `vllm==0.5.4`. Risks:

- model support for Mixtral AWQ, Qwen2, and Llama-3.1;
- GPU memory pressure from `--max-model-len 10380` for student and `16384` for tutor;
- tensor parallel settings not matching actual GPU count;
- AWQ quantization recognition may need explicit verification.

### FlashAttention

`requirements.txt` pins `flash-attn==2.7.2.post1`. It may require:

- Linux build tools;
- compatible CUDA toolkit/runtime;
- compatible PyTorch wheel;
- GPU architecture support.

Do not assume it can be built on every server. Inspect first.

### Transformers and PEFT

`transformers==4.44.2` and `peft==0.13.2` should be checked against Mistral, Llama-3.1, and Qwen2 tokenizer/model loading. `trust_remote_code=True` is used in verifier loading.

### bitsandbytes and DeepSpeed

Verifier training uses 4-bit loading through bitsandbytes and DeepSpeed. This is highly CUDA-sensitive and should not be attempted until the smoke test and environment inspection pass.

## First Server Run Order

1. Activate conda environment.
2. Run `bash Scripts4repro/inspect_server.sh`.
3. Copy back the inspection log.
4. Decide whether dependency installation is feasible.
5. Create or run a one-sample smoke script only after confirming paths, model access, and CUDA package compatibility.
6. Only after the smoke test passes, consider small-subset DICT evaluation.
7. Only after small-subset evaluation is understood, consider full target runs.

## Change Classification

Compatibility fixes may include:

- correcting script typos;
- parameterizing server paths;
- adding one-sample smoke-test wrappers;
- making scripts fail early when models/data/API settings are missing;
- normalizing `mid_level` to `med_level` if the existing code requires it.

Methodological changes include:

- changing model/backbone/checkpoint;
- changing dataset split;
- changing prompt templates;
- changing generation settings;
- changing verifier scoring;
- changing Recall@k, Pass@k, TOR, or TOC formulas.

Methodological changes must be explicitly documented and should not be used simply to match reported results.
