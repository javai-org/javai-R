#' Empirical percentile using nearest-rank method
#'
#' Computes the empirical percentile from a vector of latency observations
#' using the nearest-rank (ceiling) method. This is the reference
#' implementation against which all javai framework implementations must
#' conform.
#'
#' @param latencies Numeric vector. Observed latencies (need not be sorted).
#' @param p Numeric. Percentile level in (0, 1].
#' @return Numeric. The percentile value.
#' @export
nearest_rank_percentile <- function(latencies, p) {
  sorted <- sort(latencies)
  n <- length(sorted)
  idx <- ceiling(p * n) - 1L
  idx <- max(0L, min(idx, n - 1L))
  sorted[idx + 1L]
}

#' Latency summary statistics
#'
#' Computes mean, sample standard deviation, and maximum from a vector
#' of successful-response latencies.
#'
#' @param latencies Numeric vector. Observed latencies.
#' @return A list with mean, sd, and max.
#' @export
latency_summary <- function(latencies) {
  list(
    mean = mean(latencies),
    sd = sd(latencies),
    max = max(latencies)
  )
}

#' Derive latency threshold from baseline
#'
#' Computes a one-sided upper confidence bound on a baseline percentile,
#' suitable for use as a latency threshold in verification tests.
#'
#' @param baseline_percentile Numeric. The observed baseline percentile value.
#' @param baseline_sd Numeric. Sample standard deviation of baseline latencies.
#' @param baseline_n Integer. Number of successful samples in the baseline.
#' @param confidence Numeric. Confidence level (e.g. 0.95).
#' @return A list with raw_upper (before ceiling/floor), threshold (final
#'   integer-millisecond value).
#' @export
latency_threshold_derive <- function(baseline_percentile, baseline_sd,
                                     baseline_n, confidence) {
  alpha <- 1 - confidence
  z <- qnorm(1 - alpha)  # one-sided
  se <- baseline_sd / sqrt(baseline_n)
  raw_upper <- baseline_percentile + z * se
  threshold <- max(baseline_percentile, ceiling(raw_upper))

  list(
    raw_upper = raw_upper,
    threshold = threshold
  )
}

#' Minimum sample size for percentile reliability
#'
#' Returns the minimum number of successful samples required for a
#' percentile estimate to be non-degenerate.
#'
#' @param p Numeric. Percentile level (e.g. 0.99).
#' @return Integer. Minimum sample count.
#' @export
latency_min_samples <- function(p) {
  if (p <= 0.50) return(5L)
  if (p <= 0.90) return(10L)
  if (p <= 0.95) return(20L)
  if (p <= 0.99) return(100L)
  100L  # conservative default for any higher percentile
}

#' Generate latency percentile reference cases
#'
#' @return A list suitable for JSON serialisation.
#' @export
generate_latency_percentile_cases <- function() {
  # Deterministic test vectors — hand-crafted to exercise edge cases
  # Typical right-skewed latency distribution (ms)
  typical_latencies <- c(
    120, 125, 130, 132, 135, 138, 140, 142, 145, 148,
    150, 152, 155, 158, 160, 162, 165, 170, 175, 180,
    185, 190, 195, 200, 210, 220, 240, 260, 300, 450
  )

  # Uniform-ish distribution (no skew)
  uniform_latencies <- c(
    100, 110, 120, 130, 140, 150, 160, 170, 180, 190,
    200, 210, 220, 230, 240, 250, 260, 270, 280, 290
  )

  # Heavy-tailed with outliers
  heavy_tail_latencies <- c(
    100, 105, 108, 110, 112, 115, 118, 120, 122, 125,
    128, 130, 132, 135, 138, 140, 145, 150, 155, 160,
    165, 170, 180, 200, 250, 300, 500, 800, 1500, 3000
  )

  # Minimal sample (exactly 5 values — minimum for p50)
  minimal_latencies <- c(100, 200, 300, 400, 500)

  # Single value (degenerate case)
  single_latency <- c(250)

  # Two identical values
  identical_latencies <- rep(150, 10)

  # Large sample (200 observations) for the worked example in Section 12.2.2
  set.seed(42)
  large_sample <- sort(round(rlnorm(200, meanlog = log(200), sdlog = 0.4)))

  cases <- list(
    # Typical right-skewed: all four standard percentiles
    list(
      name = "typical_skewed_p50",
      inputs = list(latencies = typical_latencies, percentile = 0.50),
      expected = list(value = nearest_rank_percentile(typical_latencies, 0.50))
    ),
    list(
      name = "typical_skewed_p90",
      inputs = list(latencies = typical_latencies, percentile = 0.90),
      expected = list(value = nearest_rank_percentile(typical_latencies, 0.90))
    ),
    list(
      name = "typical_skewed_p95",
      inputs = list(latencies = typical_latencies, percentile = 0.95),
      expected = list(value = nearest_rank_percentile(typical_latencies, 0.95))
    ),
    list(
      name = "typical_skewed_p99",
      inputs = list(latencies = typical_latencies, percentile = 0.99),
      expected = list(value = nearest_rank_percentile(typical_latencies, 0.99))
    ),
    # Uniform distribution
    list(
      name = "uniform_p50",
      inputs = list(latencies = uniform_latencies, percentile = 0.50),
      expected = list(value = nearest_rank_percentile(uniform_latencies, 0.50))
    ),
    list(
      name = "uniform_p95",
      inputs = list(latencies = uniform_latencies, percentile = 0.95),
      expected = list(value = nearest_rank_percentile(uniform_latencies, 0.95))
    ),
    # Heavy-tailed with outliers
    list(
      name = "heavy_tail_p90",
      inputs = list(latencies = heavy_tail_latencies, percentile = 0.90),
      expected = list(value = nearest_rank_percentile(heavy_tail_latencies, 0.90))
    ),
    list(
      name = "heavy_tail_p95",
      inputs = list(latencies = heavy_tail_latencies, percentile = 0.95),
      expected = list(value = nearest_rank_percentile(heavy_tail_latencies, 0.95))
    ),
    list(
      name = "heavy_tail_p99",
      inputs = list(latencies = heavy_tail_latencies, percentile = 0.99),
      expected = list(value = nearest_rank_percentile(heavy_tail_latencies, 0.99))
    ),
    # Minimal sample (n=5)
    list(
      name = "minimal_sample_p50",
      inputs = list(latencies = minimal_latencies, percentile = 0.50),
      expected = list(value = nearest_rank_percentile(minimal_latencies, 0.50))
    ),
    # Single observation — all percentiles collapse to the same value
    list(
      name = "single_observation_p50",
      inputs = list(latencies = single_latency, percentile = 0.50),
      expected = list(value = nearest_rank_percentile(single_latency, 0.50))
    ),
    list(
      name = "single_observation_p99",
      inputs = list(latencies = single_latency, percentile = 0.99),
      expected = list(value = nearest_rank_percentile(single_latency, 0.99))
    ),
    # Identical values — percentiles should all equal the common value
    list(
      name = "identical_values_p95",
      inputs = list(latencies = identical_latencies, percentile = 0.95),
      expected = list(value = nearest_rank_percentile(identical_latencies, 0.95))
    ),
    # Large sample (n=200) — the worked example from Section 12.2.2
    list(
      name = "large_sample_p50",
      inputs = list(latencies = large_sample, percentile = 0.50),
      expected = list(value = nearest_rank_percentile(large_sample, 0.50))
    ),
    list(
      name = "large_sample_p90",
      inputs = list(latencies = large_sample, percentile = 0.90),
      expected = list(value = nearest_rank_percentile(large_sample, 0.90))
    ),
    list(
      name = "large_sample_p95",
      inputs = list(latencies = large_sample, percentile = 0.95),
      expected = list(value = nearest_rank_percentile(large_sample, 0.95))
    ),
    list(
      name = "large_sample_p99",
      inputs = list(latencies = large_sample, percentile = 0.99),
      expected = list(value = nearest_rank_percentile(large_sample, 0.99))
    )
  )

  # Add summary statistics cases
  summary_cases <- list(
    list(
      name = "typical_skewed_summary",
      inputs = list(latencies = typical_latencies),
      expected = latency_summary(typical_latencies)
    ),
    list(
      name = "heavy_tail_summary",
      inputs = list(latencies = heavy_tail_latencies),
      expected = latency_summary(heavy_tail_latencies)
    ),
    list(
      name = "large_sample_summary",
      inputs = list(latencies = large_sample),
      expected = latency_summary(large_sample)
    ),
    list(
      name = "single_observation_summary",
      inputs = list(latencies = single_latency),
      expected = list(mean = mean(single_latency), sd = NA, max = max(single_latency))
    ),
    list(
      name = "identical_values_summary",
      inputs = list(latencies = identical_latencies),
      expected = latency_summary(identical_latencies)
    )
  )

  list(
    suite = "latency_percentile",
    description = "Empirical percentile estimation using nearest-rank method, with summary statistics",
    method = "Nearest-rank (ceiling) percentile; sample mean, sd, max",
    tolerance = 1e-10,
    cases = c(cases, summary_cases)
  )
}

#' Generate latency threshold derivation reference cases
#'
#' @return A list suitable for JSON serialisation.
#' @export
generate_latency_threshold_cases <- function() {
  cases <- list(
    # Worked example from Section 12.4.5
    list(
      name = "worked_example_p95_935_samples",
      inputs = list(
        baseline_percentile = 580, baseline_sd = 145,
        baseline_n = 935, confidence = 0.95
      ),
      expected = latency_threshold_derive(580, 145, 935, 0.95)
    ),
    # Small baseline — wider margin
    list(
      name = "small_baseline_p95_50_samples",
      inputs = list(
        baseline_percentile = 480, baseline_sd = 120,
        baseline_n = 50, confidence = 0.95
      ),
      expected = latency_threshold_derive(480, 120, 50, 0.95)
    ),
    # Large baseline — narrow margin
    list(
      name = "large_baseline_p95_5000_samples",
      inputs = list(
        baseline_percentile = 200, baseline_sd = 80,
        baseline_n = 5000, confidence = 0.95
      ),
      expected = latency_threshold_derive(200, 80, 5000, 0.95)
    ),
    # 99% confidence — wider margin
    list(
      name = "high_confidence_p95_500_samples",
      inputs = list(
        baseline_percentile = 350, baseline_sd = 100,
        baseline_n = 500, confidence = 0.99
      ),
      expected = latency_threshold_derive(350, 100, 500, 0.99)
    ),
    # Zero sd — threshold equals baseline percentile
    list(
      name = "zero_variance_p95",
      inputs = list(
        baseline_percentile = 200, baseline_sd = 0,
        baseline_n = 100, confidence = 0.95
      ),
      expected = latency_threshold_derive(200, 0, 100, 0.95)
    ),
    # Very high sd — large margin
    list(
      name = "high_variance_p95_100_samples",
      inputs = list(
        baseline_percentile = 300, baseline_sd = 500,
        baseline_n = 100, confidence = 0.95
      ),
      expected = latency_threshold_derive(300, 500, 100, 0.95)
    )
  )

  list(
    suite = "latency_threshold",
    description = "Latency threshold derivation from baseline percentiles",
    method = "One-sided upper confidence bound: max(Q(p), ceil(Q(p) + z * s / sqrt(n)))",
    tolerance = 1e-10,
    cases = cases
  )
}
