# javai-R

This is the R member of the javai project family. It generates
language-agnostic reference datasets for statistical computations used across
all javai probabilistic testing frameworks.

## Role

javai-R is the **statistical oracle**. It uses R — the gold standard for
statistical computing — to produce canonical expected outputs. Framework
implementations (punit, feotest, baseltest, ...) verify conformance against
these outputs.

javai-R does not implement a testing framework. It produces reference data.

## Structure

```
R/              # R source: one file per statistical computation family
inst/cases/     # Generated JSON: the reference datasets (committed)
tests/testthat/ # R tests validating the generators themselves
scripts/        # Regeneration script
schema/         # JSON schema for the case format
```

## Conventions

- All statistical computations use R's base `stats` functions (`qnorm`,
  `pnorm`, etc.) — not custom implementations. The whole point is to rely on
  R's vetted statistical library.
- JSON files in `inst/cases/` are committed. They are the deliverable.
  Consumers should not need R installed.
- Each JSON file declares its own `tolerance` for floating-point comparison.
- Test cases should include edge cases (p=0, p=1, small n, large n) and
  realistic cases (typical LLM service pass rates around 0.90-0.99).
- The package is designed to grow. Future additions include design of
  experiments (DoE) reference data.

## Regenerating

```
Rscript scripts/generate_all.R
```

## Relationship to other projects

- **punit** and **feotest** consume `inst/cases/*.json` in their conformance
  tests.
- **javai-orchestrator** tracks javai-R in the project registry and feature
  inventory.
- javai-R is an independent git repository, included as a submodule in
  javai-orchestrator.
