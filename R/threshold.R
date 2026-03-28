#' Derive threshold using sample-size-first approach
#'
#' Given a baseline (successes/trials) and a test sample size, derives the
#' minimum pass rate threshold using the Wilson one-sided lower bound.
#'
#' @param baseline_successes Integer. Successes observed in baseline.
#' @param baseline_trials Integer. Total baseline trials.
#' @param test_samples Integer. Number of test samples to be run.
#' @param confidence Numeric. Confidence level.
#' @return Numeric. The derived threshold.
#' @export
threshold_sample_size_first <- function(baseline_successes, baseline_trials,
                                        test_samples, confidence) {
  # Step 1: derive baseline rate
  baseline_rate <- baseline_successes / baseline_trials

  # Step 2: Wilson lower bound on the baseline gives the threshold
  # The threshold is the Wilson one-sided lower bound of the baseline
  wilson_lower(baseline_successes, baseline_trials, confidence)
}

#' Derive implied confidence from an explicit threshold
#'
#' Given a baseline rate, sample size, and explicit threshold, finds the
#' confidence level at which the Wilson lower bound equals the threshold.
#' Uses binary search (no closed-form inverse for Wilson).
#'
#' @param baseline_successes Integer. Successes in baseline.
#' @param baseline_trials Integer. Trials in baseline.
#' @param threshold Numeric. The explicit threshold.
#' @param tol Numeric. Convergence tolerance for binary search.
#' @return A list with implied_confidence and is_sound (>= 0.80).
#' @export
threshold_first_implied_confidence <- function(baseline_successes,
                                                baseline_trials,
                                                threshold,
                                                tol = 1e-10) {
  lo <- 0.001
  hi <- 0.999

  for (i in seq_len(200)) {
    mid <- (lo + hi) / 2
    lb <- wilson_lower(baseline_successes, baseline_trials, mid)
    if (abs(lb - threshold) < tol) break
    if (lb > threshold) {
      lo <- mid
    } else {
      hi <- mid
    }
  }

  implied <- (lo + hi) / 2
  list(
    implied_confidence = implied,
    is_sound = implied >= 0.80
  )
}

#' Generate threshold derivation reference cases
#'
#' @return A list suitable for JSON serialisation.
#' @export
generate_threshold_derivation_cases <- function() {
  cases <- list(
    # Sample-size-first cases
    list(
      name = "ssf_95_of_100_test50_95pct",
      approach = "sample_size_first",
      inputs = list(
        baseline_successes = 95L, baseline_trials = 100L,
        test_samples = 50L, confidence = 0.95
      ),
      expected = list(
        threshold = threshold_sample_size_first(95, 100, 50, 0.95)
      )
    ),
    list(
      name = "ssf_950_of_1000_test100_95pct",
      approach = "sample_size_first",
      inputs = list(
        baseline_successes = 950L, baseline_trials = 1000L,
        test_samples = 100L, confidence = 0.95
      ),
      expected = list(
        threshold = threshold_sample_size_first(950, 1000, 100, 0.95)
      )
    ),
    list(
      name = "ssf_perfect_baseline_test50_95pct",
      approach = "sample_size_first",
      inputs = list(
        baseline_successes = 100L, baseline_trials = 100L,
        test_samples = 50L, confidence = 0.95
      ),
      expected = list(
        threshold = threshold_sample_size_first(100, 100, 50, 0.95)
      )
    ),
    list(
      name = "ssf_95_of_100_test50_99pct",
      approach = "sample_size_first",
      inputs = list(
        baseline_successes = 95L, baseline_trials = 100L,
        test_samples = 50L, confidence = 0.99
      ),
      expected = list(
        threshold = threshold_sample_size_first(95, 100, 50, 0.99)
      )
    ),
    # Threshold-first cases
    list(
      name = "tf_baseline_95pct_threshold_90",
      approach = "threshold_first",
      inputs = list(
        baseline_successes = 95L, baseline_trials = 100L,
        threshold = 0.90
      ),
      expected = threshold_first_implied_confidence(95, 100, 0.90)
    ),
    list(
      name = "tf_baseline_95pct_threshold_85",
      approach = "threshold_first",
      inputs = list(
        baseline_successes = 95L, baseline_trials = 100L,
        threshold = 0.85
      ),
      expected = threshold_first_implied_confidence(95, 100, 0.85)
    ),
    list(
      name = "tf_baseline_95pct_threshold_94",
      approach = "threshold_first",
      inputs = list(
        baseline_successes = 95L, baseline_trials = 100L,
        threshold = 0.94
      ),
      expected = threshold_first_implied_confidence(95, 100, 0.94)
    )
  )

  list(
    suite = "threshold_derivation",
    description = "Threshold derivation via sample-size-first and threshold-first approaches",
    method = "Wilson lower bound (sample-size-first); binary search for implied confidence (threshold-first)",
    tolerance = 1e-6,
    cases = cases
  )
}
