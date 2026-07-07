# Paper Reproduction Instructions

## Objective

Reproduce the experiment defined in `docs/reproduction_target.md`.

Successful execution alone does not count as successful reproduction.
The experiment must match the paper's model, checkpoint, dataset split,
prompt, generation settings, random seed, evaluator, and metric whenever
these details are available.

## Local and server responsibilities

The current Codex workspace is on a local Windows computer.

Local responsibilities:

- inspect the paper and repository;
- modify source code and configuration;
- create Linux-compatible server scripts;
- run static checks and lightweight tests when possible;
- analyze logs copied back from the server.

Server responsibilities:

- create the Python environment;
- install CUDA-related dependencies;
- download models and datasets;
- run GPU inference, evaluation, and training.

Do not assume that a command succeeding locally means it will succeed on
the Linux GPU server.

## Safety rules

- Do not commit API keys, passwords, tokens, `.env` files, datasets, or
  model weights.
- Do not change the algorithm or metric just to match the reported result.
- Do not silently replace an unavailable model with another model.
- Do not change dataset splits without documenting the deviation.
- Do not generate Windows commands for scripts intended to run on the server.
- Server scripts must use Bash and Linux paths.
- Do not start with a full training or evaluation run.
- Always create a one-sample or one-batch smoke test first.
- Distinguish compatibility fixes from methodological changes.

## Required workflow

1. Inspect the paper, appendix, README, configurations, and scripts.
2. Map the target paper experiment to repository files and commands.
3. Identify missing checkpoints, data, APIs, and undocumented settings.
4. Create an environment inspection script for the Linux server.
5. Create a one-sample smoke-test script.
6. Analyze the server log.
7. Make the smallest necessary compatibility fixes.
8. Run the target experiment.
9. Compare the reproduced and reported results.
10. Document all deviations.

## Change management

Before editing:

- inspect `git status`;
- explain the planned changes;
- identify files that will be modified.

After editing:

- show the diff;
- run relevant lightweight checks;
- do not commit automatically;
- summarize compatibility fixes and methodological changes separately.