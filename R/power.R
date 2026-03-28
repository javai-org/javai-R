#' Compute required sample size for a one-sided binomial proportion test
#'
#' Uses the standard power formula for one-sided tests:
#'   n = ((z_alpha * sigma_0 + z_beta * sigma_1) / delta)^2
#'
#' @param baseline_rate Numeric. Null hypothesis proportion (p0).
#' @param min_detectable_effect Numeric. Minimum degradation to detect (delta).
#' @param confidence Numeric. Confidence level (1 - alpha).
#' @param power Numeric. Statistical power (1 - beta).
#' @return A list with required_samples and achieved_power.
#' @export
required_sample_size <- function(baseline_rate, min_detectable_effect,
                                  confidence, power) {
  alpha <- 1 - confidence
  z_alpha <- qnorm(1 - alpha)
  z_beta <- qnorm(power)

  p0 <- baseline_rate
  p1 <- baseline_rate - min_detectable_effect
  delta <- min_detectable_effect

  sigma_0 <- sqrt(p0 * (1 - p0))
  sigma_1 <- sqrt(p1 * (1 - p1))

  n <- ((z_alpha * sigma_0 + z_beta * sigma_1) / delta)^2
  n_ceil <- ceiling(n)

  # Compute achieved power at the ceiling sample size
  achieved <- achieved_power(n_ceil, baseline_rate, min_detectable_effect,
                              confidence)

  list(
    required_samples = as.integer(n_ceil),
    achieved_power = achieved
  )
}

#' Compute achieved power for a given sample size
#'
#' @param n Integer. Sample size.
#' @param baseline_rate Numeric. Null hypothesis proportion.
#' @param min_detectable_effect Numeric. Effect size.
#' @param confidence Numeric. Confidence level.
#' @return Numeric. Achieved power.
achieved_power <- function(n, baseline_rate, min_detectable_effect, confidence) {
  alpha <- 1 - confidence
  z_alpha <- qnorm(1 - alpha)

  p0 <- baseline_rate
  p1 <- baseline_rate - min_detectable_effect

  sigma_0 <- sqrt(p0 * (1 - p0))
  sigma_1 <- sqrt(p1 * (1 - p1))

  # Power = P(Z > z_alpha * sigma_0/sigma_1 - delta*sqrt(n)/sigma_1)
  z_beta <- (z_alpha * sigma_0 - min_detectable_effect * sqrt(n)) / sigma_1
  pnorm(-z_beta)  # = 1 - pnorm(z_beta)
}

#' Generate power analysis reference cases
#'
#' @return A list suitable for JSON serialisation.
#' @export
generate_power_analysis_cases <- function() {
  cases <- list(
    list(
      name = "typical_llm_95pct_5pct_effect_80power",
      inputs = list(
        baseline_rate = 0.95, min_detectable_effect = 0.05,
        confidence = 0.95, power = 0.80
      ),
      expected = required_sample_size(0.95, 0.05, 0.95, 0.80)
    ),
    list(
      name = "high_baseline_99pct_2pct_effect_80power",
      inputs = list(
        baseline_rate = 0.99, min_detectable_effect = 0.02,
        confidence = 0.95, power = 0.80
      ),
      expected = required_sample_size(0.99, 0.02, 0.95, 0.80)
    ),
    list(
      name = "fair_coin_50pct_10pct_effect_80power",
      inputs = list(
        baseline_rate = 0.50, min_detectable_effect = 0.10,
        confidence = 0.95, power = 0.80
      ),
      expected = required_sample_size(0.50, 0.10, 0.95, 0.80)
    ),
    list(
      name = "high_power_95pct_5pct_effect_95power",
      inputs = list(
        baseline_rate = 0.95, min_detectable_effect = 0.05,
        confidence = 0.95, power = 0.95
      ),
      expected = required_sample_size(0.95, 0.05, 0.95, 0.95)
    ),
    list(
      name = "small_effect_95pct_1pct_effect_80power",
      inputs = list(
        baseline_rate = 0.95, min_detectable_effect = 0.01,
        confidence = 0.95, power = 0.80
      ),
      expected = required_sample_size(0.95, 0.01, 0.95, 0.80)
    ),
    list(
      name = "high_confidence_95pct_5pct_effect_99conf",
      inputs = list(
        baseline_rate = 0.95, min_detectable_effect = 0.05,
        confidence = 0.99, power = 0.80
      ),
      expected = required_sample_size(0.95, 0.05, 0.99, 0.80)
    )
  )

  list(
    suite = "power_analysis",
    description = "Sample size calculation via power analysis for one-sided binomial proportion tests",
    method = "Standard power formula: n = ((z_alpha * sigma_0 + z_beta * sigma_1) / delta)^2",
    tolerance = 1e-10,
    cases = cases
  )
}
