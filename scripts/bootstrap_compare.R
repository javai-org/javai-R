#!/usr/bin/env Rscript
#
# Bootstrap vs. binomial-bound comparison for §12.4.4 of the
# STATISTICAL-COMPANION. Computes the one-sided 95% upper bound on Q(p) for
# two reference baselines using (a) a 10,000-replicate percentile bootstrap
# and (b) the exact binomial order-statistic construction used by the
# methodology.
#
# Output: a markdown table printed to stdout; suitable for pasting into
# §12.4.4. Also writes inst/cases/latency_threshold_bootstrap.json for
# regression tracking.

r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
for (f in r_files) source(f)

bootstrap_upper <- function(baseline, p, confidence, B = 10000L, seed = 1L) {
  set.seed(seed)
  n <- length(baseline)
  reps <- replicate(B, {
    nearest_rank_percentile(sample(baseline, n, replace = TRUE), p)
  })
  unname(quantile(reps, probs = confidence, type = 1))
}

compare_row <- function(label, baseline, p, confidence = 0.95) {
  bin <- latency_threshold_derive(baseline, p, confidence)
  boot <- bootstrap_upper(baseline, p, confidence)
  list(
    sample = label,
    n = length(baseline),
    p = p,
    point_estimate = nearest_rank_percentile(baseline, p),
    binomial_bound = bin$threshold,
    binomial_rank = bin$rank,
    bootstrap_upper = boot,
    diff = bin$threshold - boot
  )
}

set.seed(42)
sample_200 <- sort(round(rlnorm(200, meanlog = log(200), sdlog = 0.4)))

set.seed(42)
sample_935 <- sort(round(rlnorm(935, meanlog = log(500), sdlog = 0.3)))

rows <- list(
  compare_row("lognormal_n200", sample_200, 0.95),
  compare_row("lognormal_n200", sample_200, 0.99),
  compare_row("lognormal_n935", sample_935, 0.95),
  compare_row("lognormal_n935", sample_935, 0.99)
)

cat("| Sample | n_s | p | Point estimate | Bootstrap 95% upper | Binomial bound (rank) | diff (ms) |\n")
cat("|---|---|---|---|---|---|---|\n")
for (r in rows) {
  cat(sprintf("| %s | %d | %.2f | %g | %g | %g (k=%d) | %+g |\n",
              r$sample, r$n, r$p,
              r$point_estimate, r$bootstrap_upper,
              r$binomial_bound, r$binomial_rank,
              r$diff))
}

out <- list(
  suite = "latency_threshold_bootstrap",
  description = "Bootstrap vs. binomial order-statistic upper bound comparison (informational)",
  method = "10,000-replicate percentile bootstrap (type-1 quantile) vs. exact binomial rank",
  tolerance = 0,
  cases = lapply(rows, function(r) {
    list(name = sprintf("%s_p%g", r$sample, r$p * 100),
         inputs = list(n = r$n, p = r$p, confidence = 0.95),
         expected = list(
           point_estimate = r$point_estimate,
           binomial_bound = r$binomial_bound,
           binomial_rank = r$binomial_rank,
           bootstrap_upper = r$bootstrap_upper,
           diff = r$diff
         ))
  })
)

out_path <- file.path("inst", "cases", "latency_threshold_bootstrap.json")
if (!dir.exists(dirname(out_path))) dir.create(dirname(out_path), recursive = TRUE)
jsonlite::write_json(out, out_path, pretty = TRUE, auto_unbox = TRUE, digits = NA)
message("\nWrote: ", out_path)
