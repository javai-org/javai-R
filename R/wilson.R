#' Wilson score confidence interval (two-sided)
#'
#' Computes the Wilson score interval for a binomial proportion.
#' This is the reference implementation against which all javai framework
#' implementations (punit, feotest, baseltest, ...) must conform.
#'
#' @param successes Integer. Number of successes.
#' @param trials Integer. Total number of trials.
#' @param confidence Numeric. Confidence level (e.g. 0.95).
#' @return A list with lower, upper, and point estimate.
#' @export
wilson_ci <- function(successes, trials, confidence) {
  alpha <- 1 - confidence
  z <- qnorm(1 - alpha / 2)
  p_hat <- successes / trials
  n <- trials

  denom <- 1 + z^2 / n
  centre <- (p_hat + z^2 / (2 * n)) / denom
  margin <- (z / denom) * sqrt(p_hat * (1 - p_hat) / n + z^2 / (4 * n^2))

  list(
    lower = centre - margin,
    upper = centre + margin,
    point = p_hat
  )
}

#' Wilson score lower bound (one-sided)
#'
#' Computes the one-sided lower bound of the Wilson score interval.
#' Used for threshold derivation in the sample-size-first approach.
#'
#' @param successes Integer. Number of successes.
#' @param trials Integer. Total number of trials.
#' @param confidence Numeric. Confidence level (e.g. 0.95).
#' @return Numeric. The lower bound.
#' @export
wilson_lower <- function(successes, trials, confidence) {
  alpha <- 1 - confidence
  z <- qnorm(1 - alpha)  # one-sided
  p_hat <- successes / trials
  n <- trials

  denom <- 1 + z^2 / n
  centre <- (p_hat + z^2 / (2 * n)) / denom
  margin <- (z / denom) * sqrt(p_hat * (1 - p_hat) / n + z^2 / (4 * n^2))

  centre - margin
}

#' Generate Wilson CI reference cases
#'
#' @return A list suitable for JSON serialisation.
#' @export
generate_wilson_ci_cases <- function() {
  cases <- list(
    # Fair coin — textbook case
    list(
      name = "fair_coin_100_trials_95pct",
      inputs = list(successes = 50L, trials = 100L, confidence = 0.95),
      expected = wilson_ci(50, 100, 0.95)
    ),
    # High pass rate — typical LLM service
    list(
      name = "high_rate_95_of_100_95pct",
      inputs = list(successes = 95L, trials = 100L, confidence = 0.95),
      expected = wilson_ci(95, 100, 0.95)
    ),
    # Perfect baseline — the "perfect baseline problem"
    list(
      name = "perfect_baseline_100_of_100_95pct",
      inputs = list(successes = 100L, trials = 100L, confidence = 0.95),
      expected = wilson_ci(100, 100, 0.95)
    ),
    # Zero successes — boundary
    list(
      name = "zero_successes_0_of_100_95pct",
      inputs = list(successes = 0L, trials = 100L, confidence = 0.95),
      expected = wilson_ci(0, 100, 0.95)
    ),
    # Small sample
    list(
      name = "small_sample_3_of_5_95pct",
      inputs = list(successes = 3L, trials = 5L, confidence = 0.95),
      expected = wilson_ci(3, 5, 0.95)
    ),
    # Large sample
    list(
      name = "large_sample_950_of_1000_95pct",
      inputs = list(successes = 950L, trials = 1000L, confidence = 0.95),
      expected = wilson_ci(950, 1000, 0.95)
    ),
    # 90% confidence
    list(
      name = "fair_coin_100_trials_90pct",
      inputs = list(successes = 50L, trials = 100L, confidence = 0.90),
      expected = wilson_ci(50, 100, 0.90)
    ),
    # 99% confidence
    list(
      name = "fair_coin_100_trials_99pct",
      inputs = list(successes = 50L, trials = 100L, confidence = 0.99),
      expected = wilson_ci(50, 100, 0.99)
    ),
    # Near-boundary low rate
    list(
      name = "low_rate_2_of_100_95pct",
      inputs = list(successes = 2L, trials = 100L, confidence = 0.95),
      expected = wilson_ci(2, 100, 0.95)
    ),
    # Single trial success
    list(
      name = "single_trial_success_95pct",
      inputs = list(successes = 1L, trials = 1L, confidence = 0.95),
      expected = wilson_ci(1, 1, 0.95)
    )
  )

  list(
    suite = "wilson_ci",
    description = "Wilson score confidence intervals (two-sided)",
    method = "qnorm-based Wilson score interval",
    tolerance = 1e-10,
    cases = cases
  )
}

#' Generate Wilson lower bound reference cases
#'
#' @return A list suitable for JSON serialisation.
#' @export
generate_wilson_lower_cases <- function() {
  cases <- list(
    list(
      name = "baseline_95_of_100_95pct",
      inputs = list(successes = 95L, trials = 100L, confidence = 0.95),
      expected = list(lower_bound = wilson_lower(95, 100, 0.95))
    ),
    list(
      name = "perfect_baseline_100_of_100_95pct",
      inputs = list(successes = 100L, trials = 100L, confidence = 0.95),
      expected = list(lower_bound = wilson_lower(100, 100, 0.95))
    ),
    list(
      name = "baseline_950_of_1000_95pct",
      inputs = list(successes = 950L, trials = 1000L, confidence = 0.95),
      expected = list(lower_bound = wilson_lower(950, 1000, 0.95))
    ),
    list(
      name = "baseline_95_of_100_99pct",
      inputs = list(successes = 95L, trials = 100L, confidence = 0.99),
      expected = list(lower_bound = wilson_lower(95, 100, 0.99))
    ),
    list(
      name = "baseline_95_of_100_90pct",
      inputs = list(successes = 95L, trials = 100L, confidence = 0.90),
      expected = list(lower_bound = wilson_lower(95, 100, 0.90))
    ),
    list(
      name = "fair_coin_50_of_100_95pct",
      inputs = list(successes = 50L, trials = 100L, confidence = 0.95),
      expected = list(lower_bound = wilson_lower(50, 100, 0.95))
    ),
    list(
      name = "small_sample_5_of_5_95pct",
      inputs = list(successes = 5L, trials = 5L, confidence = 0.95),
      expected = list(lower_bound = wilson_lower(5, 5, 0.95))
    )
  )

  list(
    suite = "wilson_lower",
    description = "Wilson score one-sided lower bound",
    method = "qnorm-based Wilson score lower bound (one-sided z)",
    tolerance = 1e-10,
    cases = cases
  )
}
