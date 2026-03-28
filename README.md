# javai-r

Reference statistical computations for the [javai](https://javai.org) project
family, implemented in R.

## Purpose

This R package generates language-agnostic reference datasets — canonical
expected outputs for the statistical computations that underpin probabilistic
testing frameworks across the javai family:

- **[punit](https://github.com/javai-org/punit)** (Java)
- **[feotest](https://github.com/javai-org/feotest)** (Rust)
- **[baseltest](https://github.com/javai-org/baseltest)** (Python, planned)

Each framework implements the same statistical methods independently, in its own
language and idiom. This project provides the shared truth: if your
implementation produces results that match the R-generated reference data
(within stated tolerances), it conforms.

## Why R?

R is the lingua franca of statistics. By generating reference data with R's
well-vetted statistical functions (`qnorm`, `pnorm`, `prop.test`, etc.),
anyone — statistician, auditor, contributor — can verify the expected outputs
independently. No need to trust a Java or Rust implementation.

## What's covered

### Statistics engine conformance (current)

| Suite | File | Covers |
|---|---|---|
| Wilson CI | `inst/cases/wilson_ci.json` | Two-sided Wilson score confidence intervals |
| Wilson lower | `inst/cases/wilson_lower.json` | One-sided Wilson score lower bound |
| Threshold derivation | `inst/cases/threshold_derivation.json` | Sample-size-first and threshold-first approaches |
| Power analysis | `inst/cases/power_analysis.json` | Sample size calculation via power analysis |
| Feasibility | `inst/cases/feasibility.json` | Verification feasibility checking |
| Verdict | `inst/cases/verdict.json` | Pass/fail verdict evaluation with z-test |

### Design of experiments (planned)

Future suites will cover DoE reference data as the javai family expands into
experimental design capabilities.

## Usage

### Regenerate the reference data

```r
Rscript scripts/generate_all.R
```

This writes JSON files to `inst/cases/`. These files are committed to the
repository so that consumers can read them without needing R installed.

### Install as an R package

```r
devtools::install_github("javai-org/javai-r")
```

### Run the R tests

```r
devtools::test()
```

## JSON format

Each suite file contains:

```json
{
  "suite": "wilson_ci",
  "description": "Wilson score confidence intervals (two-sided)",
  "method": "qnorm-based Wilson score interval",
  "tolerance": 1e-10,
  "cases": [
    {
      "name": "fair_coin_100_trials_95pct",
      "inputs": { "successes": 50, "trials": 100, "confidence": 0.95 },
      "expected": { "lower": 0.40383, "upper": 0.59617, "point": 0.50 }
    }
  ]
}
```

The `tolerance` field specifies the maximum acceptable absolute difference
between a framework's output and the reference value. Framework conformance
tests should use this tolerance for floating-point comparison.

## Consuming the reference data

Framework projects read the JSON files and assert conformance. For example:

- **punit** (Java): a JUnit test reads the JSON, deserialises the cases, and
  asserts each computation matches within tolerance.
- **feotest** (Rust): a `#[test]` reads the JSON via `serde_json` and asserts
  conformance.

The JSON files are the contract. The R code is the oracle.

## Contributing

Contributions welcome — especially from statisticians who want to:

- Add edge cases that stress-test implementations
- Verify the R computations against textbook values
- Propose new suites for emerging capabilities (DoE, sequential analysis, etc.)

## License

Apache-2.0
