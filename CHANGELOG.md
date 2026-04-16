# Changelog

All notable changes to the `javai-R` fixture releases are documented here.
Versions follow the fixture-versioning rules declared in `CLAUDE.md`:
**minor** bumps on 0.x mark breaking changes to fixture content or shape;
**patch** bumps mark additive changes.

## [0.5.0] — 2026-04-16

**Breaking — latency fixture schema and method change.**

Downstream conformance suites (punit, feotest) MUST be updated before
consuming this release. A requirements document describing the migration
exists at `plan/REQ-R-latency-threshold-binomial.md` in each consumer
repository.

### Changed

- `inst/cases/latency_threshold.json` — **inputs reshaped and method
  replaced**. The `s / sqrt(n_s)` standard-error approximation used to
  derive an upper bound on a baseline percentile has been superseded by
  an exact non-parametric construction: the binomial order-statistic
  upper confidence bound. Input fields changed from
  `{baseline_percentile, baseline_sd, baseline_n, confidence}` to
  `{baseline_latencies, p, confidence}`; expected output fields changed
  from `{raw_upper, threshold}` to `{rank, threshold, baseline_percentile, n}`.
  Tolerance is now zero (the expected threshold is always an exact order
  statistic of the integer-ms baseline).
- `inst/cases/latency_percentile.json` — summary cases drop the sample
  standard deviation (`sd`) field. `mean` and `max` remain. The latency
  distribution is not well-characterised by its second moment, and the
  new threshold construction does not use `s`.

### Added

- `inst/cases/latency_threshold_bootstrap.json` — informational
  reference data comparing the binomial order-statistic bound against a
  10,000-replicate percentile bootstrap on representative lognormal
  baselines. Not part of the conformance contract; provided so
  consumers can verify the §12.4.4 table in `STATISTICAL-COMPANION.md`
  without an R installation.
- `scripts/bootstrap_compare.R` — the script that generates the
  bootstrap comparison fixture.

### Notes

- A local `v0.4.0` tag existed on the commit that bumped `DESCRIPTION`
  to 0.4.0 but was never pushed to `origin`, so no 0.4.0 release was
  ever published. The 0.4.0 version number is skipped to avoid
  confusion with that un-released state. Downstream consumers
  upgrading should read this as 0.3.0 → 0.5.0 directly.

## [0.3.0] — 2026-03-28

Reference data upgraded to full-precision numerical output.

## [0.2.0] — 2026-03-28

JSON Schema for conformance case files added under `schema/`.

## [0.1.0] — 2026-03-28

Initial public release.
