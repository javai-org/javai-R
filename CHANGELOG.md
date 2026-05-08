# Changelog

All notable changes to the `javai-R` fixture releases are documented here.
Versions follow the fixture-versioning rules declared in `CLAUDE.md`:
**minor** bumps on 0.x mark breaking changes to fixture content or shape;
**patch** bumps mark additive changes.

## [0.6.0] — 2026-05-08

**Breaking — threshold-derivation fixture content and signature change.**

The `threshold_sample_size_first` and `threshold_first_implied_confidence`
generators were not matching the statistical companion: they ignored
their `test_samples` parameter and computed `wilson_lower(k_baseline,
n_baseline, conf)` regardless. The companion's §3.4 / §4.3.2 / §6.3
construction is the one-sided Wilson lower bound at the *test* sample
size, with a two-step compression for the perfect-baseline case. This
release replaces the generators with the companion-correct construction
and regenerates the affected fixture.

Downstream conformance suites (punit, feotest) MUST be updated before
consuming this release. A requirements document describing the migration
exists at `plan/REQ-R-threshold-derivation-test-sample-size.md` in each
consumer repository.

### Changed

- `inst/cases/threshold_derivation.json` — **expected values change for
  every case, and the threshold-first input shape adds a required
  `test_samples` field**. `sample_size_first` thresholds are now derived
  by Wilson lower bound at the test sample size: general case (§3.4)
  uses the baseline point estimate as the formula's centre; perfect-
  baseline case (§4.3.2) compresses the baseline through its own Wilson
  lower bound first, then applies the same Wilson construction at the
  test sample size. New cases sweep `test_samples` to make the new
  sensitivity verifiable from the fixture alone (`ssf_950_of_1000_test50`,
  `ssf_950_of_1000_test200`, `ssf_perfect_baseline_n1000_test100`).
  Threshold-first cases acquire a `test_samples` input.
- `R/threshold.R` — `threshold_sample_size_first(...)` and
  `threshold_first_implied_confidence(...)` rewritten to follow the
  companion. `threshold_first_implied_confidence` gains `test_samples`
  in its signature; the binary search runs against the corrected
  forward construction.
- `R/wilson.R` — adds `wilson_lower_from_rate(p_hat, n, confidence)`
  for the continuous-rate Wilson lower bound that the threshold
  construction needs (the discrete `wilson_lower(k, n, conf)` is now a
  thin wrapper).

### Why

The previous generator effectively published `wilson_lower(baseline)`
under the name "threshold". A test passes (per §5.1) when the
*observed* test rate clears the threshold, and the threshold's role is
to bound the test-side false-positive rate at the configured α. That
calls for a Wilson construction parametrised by `n_test`, not
`n_baseline` — exactly what §3.4 / §3.5 already specified and what the
generators had drifted from. Smaller test samples lower the threshold
(§3.5), which the new fixture demonstrates.

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
