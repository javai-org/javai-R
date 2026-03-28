#' Check verification feasibility
#'
#' Determines whether a given sample size is sufficient to produce a
#' statistically meaningful verdict for a target proportion at the
#' specified confidence level.
#'
#' Uses the Wilson score criterion: feasible if n / (n + z^2) >= target.
#' Minimum required: n_min = ceil(target * z^2 / (1 - target)).
#'
#' @param target_proportion Numeric. The target pass rate (p0).
#' @param sample_size Integer. The configured sample size.
#' @param confidence Numeric. Confidence level.
#' @return A list with feasible, minimum_samples, and the criterion.
#' @export
check_feasibility <- function(target_proportion, sample_size, confidence) {
  alpha <- 1 - confidence
  z <- qnorm(1 - alpha)  # one-sided
  z_sq <- z^2

  n_min <- ceiling(target_proportion * z_sq / (1 - target_proportion))
  feasible <- sample_size >= n_min

  list(
    feasible = feasible,
    minimum_samples = as.integer(n_min),
    criterion = "wilson_score_one_sided_lower_bound"
  )
}

#' Generate feasibility reference cases
#'
#' @return A list suitable for JSON serialisation.
#' @export
generate_feasibility_cases <- function() {
  cases <- list(
    list(
      name = "fair_coin_n5_95pct",
      inputs = list(target_proportion = 0.50, sample_size = 5L, confidence = 0.95),
      expected = check_feasibility(0.50, 5, 0.95)
    ),
    list(
      name = "high_rate_n30_95pct",
      inputs = list(target_proportion = 0.90, sample_size = 30L, confidence = 0.95),
      expected = check_feasibility(0.90, 30, 0.95)
    ),
    list(
      name = "high_rate_n20_95pct_undersized",
      inputs = list(target_proportion = 0.90, sample_size = 20L, confidence = 0.95),
      expected = check_feasibility(0.90, 20, 0.95)
    ),
    list(
      name = "very_high_rate_n55_95pct",
      inputs = list(target_proportion = 0.95, sample_size = 55L, confidence = 0.95),
      expected = check_feasibility(0.95, 55, 0.95)
    ),
    list(
      name = "near_perfect_n100_95pct_undersized",
      inputs = list(target_proportion = 0.9999, sample_size = 100L, confidence = 0.95),
      expected = check_feasibility(0.9999, 100, 0.95)
    ),
    list(
      name = "high_rate_n30_99pct",
      inputs = list(target_proportion = 0.90, sample_size = 30L, confidence = 0.99),
      expected = check_feasibility(0.90, 30, 0.99)
    ),
    list(
      name = "high_rate_n60_99pct",
      inputs = list(target_proportion = 0.90, sample_size = 60L, confidence = 0.99),
      expected = check_feasibility(0.90, 60, 0.99)
    )
  )

  list(
    suite = "feasibility",
    description = "Verification feasibility checking — is the sample size sufficient?",
    method = "Wilson score criterion: n / (n + z^2) >= target; n_min = ceil(target * z^2 / (1 - target))",
    tolerance = 0,
    cases = cases
  )
}
