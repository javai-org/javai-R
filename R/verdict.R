#' Evaluate a test verdict
#'
#' Determines pass/fail by comparing observed rate to threshold.
#' Computes false positive probability (alpha) and z-test statistic.
#'
#' @param successes Integer. Test successes.
#' @param trials Integer. Test trials.
#' @param threshold Numeric. The pass rate threshold.
#' @param confidence Numeric. Confidence level used for the test.
#' @return A list with passed, observed_rate, test_statistic, p_value,
#'   false_positive_probability.
evaluate_verdict <- function(successes, trials, threshold, confidence) {
  observed_rate <- successes / trials
  passed <- observed_rate >= threshold

  # Standard error under the null (threshold is the null proportion)
  se <- sqrt(threshold * (1 - threshold) / trials)

  # One-sided z-test: is observed rate significantly below threshold?
  test_statistic <- (observed_rate - threshold) / se

  # p-value for the one-sided test (H1: p < threshold)
  p_value <- pnorm(test_statistic)

  alpha <- 1 - confidence

  list(
    passed = passed,
    observed_rate = observed_rate,
    test_statistic = test_statistic,
    p_value = p_value,
    false_positive_probability = if (passed) 0 else alpha
  )
}

#' Generate verdict evaluation reference cases
#'
#' @return A list suitable for JSON serialisation.
#' @export
generate_verdict_cases <- function() {
  cases <- list(
    list(
      name = "clear_pass_48_of_50_threshold_90",
      inputs = list(
        successes = 48L, trials = 50L, threshold = 0.90, confidence = 0.95
      ),
      expected = evaluate_verdict(48, 50, 0.90, 0.95)
    ),
    list(
      name = "clear_fail_40_of_50_threshold_90",
      inputs = list(
        successes = 40L, trials = 50L, threshold = 0.90, confidence = 0.95
      ),
      expected = evaluate_verdict(40, 50, 0.90, 0.95)
    ),
    list(
      name = "borderline_pass_45_of_50_threshold_90",
      inputs = list(
        successes = 45L, trials = 50L, threshold = 0.90, confidence = 0.95
      ),
      expected = evaluate_verdict(45, 50, 0.90, 0.95)
    ),
    list(
      name = "perfect_score_50_of_50_threshold_95",
      inputs = list(
        successes = 50L, trials = 50L, threshold = 0.95, confidence = 0.95
      ),
      expected = evaluate_verdict(50, 50, 0.95, 0.95)
    ),
    list(
      name = "zero_successes_0_of_50_threshold_90",
      inputs = list(
        successes = 0L, trials = 50L, threshold = 0.90, confidence = 0.95
      ),
      expected = evaluate_verdict(0, 50, 0.90, 0.95)
    ),
    list(
      name = "large_sample_pass_920_of_1000_threshold_90",
      inputs = list(
        successes = 920L, trials = 1000L, threshold = 0.90, confidence = 0.95
      ),
      expected = evaluate_verdict(920, 1000, 0.90, 0.95)
    )
  )

  list(
    suite = "verdict",
    description = "Verdict evaluation — pass/fail determination with z-test statistics",
    method = "One-sided z-test: z = (p_hat - threshold) / SE; SE = sqrt(threshold * (1 - threshold) / n)",
    tolerance = 1e-10,
    cases = cases
  )
}
