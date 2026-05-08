test_that("Sample-size-first threshold is below baseline rate", {
  threshold <- threshold_sample_size_first(95, 100, 50, 0.95)
  baseline_rate <- 95 / 100

  expect_true(threshold < baseline_rate)
  expect_true(threshold > 0)
})

test_that("Higher confidence produces lower threshold", {
  t_90 <- threshold_sample_size_first(95, 100, 50, 0.90)
  t_95 <- threshold_sample_size_first(95, 100, 50, 0.95)
  t_99 <- threshold_sample_size_first(95, 100, 50, 0.99)

  expect_true(t_90 > t_95)
  expect_true(t_95 > t_99)
})

test_that("Smaller test sample size produces lower threshold (companion §3.5)", {
  # Holding the baseline fixed, the threshold drops as the test sample
  # shrinks — smaller tests carry more sampling noise, so the framework
  # demands less to maintain the same false-positive rate.
  t_test50 <- threshold_sample_size_first(950, 1000, 50, 0.95)
  t_test100 <- threshold_sample_size_first(950, 1000, 100, 0.95)
  t_test500 <- threshold_sample_size_first(950, 1000, 500, 0.95)

  expect_true(t_test50 < t_test100)
  expect_true(t_test100 < t_test500)
})

test_that("Threshold matches companion §3.5 reference table at p_hat = 0.951", {
  # §3.5 Wilson lower bounds for p_hat = 0.951:
  # | Test Samples | 95% Lower Bound |
  # |     50       |      0.874      |
  # |    100       |      0.902      |
  # |    200       |      0.919      |
  # |    500       |      0.933      |
  # The §3.4 worked example reports the same 100-sample case rounded to
  # ≈ 0.904 because its derivation uses z = 1.645 (3 dp) rather than
  # qnorm(0.95) at full precision.
  expect_equal(threshold_sample_size_first(951, 1000,  50, 0.95), 0.874, tolerance = 0.001)
  expect_equal(threshold_sample_size_first(951, 1000, 100, 0.95), 0.902, tolerance = 0.001)
  expect_equal(threshold_sample_size_first(951, 1000, 200, 0.95), 0.919, tolerance = 0.001)
  expect_equal(threshold_sample_size_first(951, 1000, 500, 0.95), 0.933, tolerance = 0.001)
})

test_that("Perfect baseline does not produce threshold of 1.0", {
  threshold <- threshold_sample_size_first(100, 100, 50, 0.95)

  expect_true(threshold < 1.0)
  expect_true(threshold > 0.85)
})

test_that("Perfect baseline two-step matches companion §4.3.2 worked example", {
  # §4.3.2: n_baseline = 1000, k_baseline = 1000, n_test = 100, conf = 0.95.
  # Step 1: p_0 = 1000 / (1000 + 1.645^2) ≈ 0.9973.
  # Step 2: Wilson lower at (p_0, n_test=100) ≈ 0.9686.
  threshold <- threshold_sample_size_first(1000, 1000, 100, 0.95)
  expect_equal(threshold, 0.9686, tolerance = 0.001)
})

test_that("Perfect baseline two-step matches §4.3.3 reference table", {
  # §4.3.3 selected entries (confidence = 0.95):
  expect_equal(threshold_sample_size_first(100,  100,  50, 0.95), 0.906, tolerance = 0.001)
  expect_equal(threshold_sample_size_first(100,  100, 100, 0.95), 0.932, tolerance = 0.001)
  expect_equal(threshold_sample_size_first(300,  300,  50, 0.95), 0.933, tolerance = 0.001)
  expect_equal(threshold_sample_size_first(1000, 1000, 50, 0.95), 0.944, tolerance = 0.001)
})

test_that("Larger baseline at perfect rate produces tighter threshold", {
  # Two-step intuition: more baseline samples => p_0 closer to 1 =>
  # threshold also moves up.
  t_n100  <- threshold_sample_size_first(100,  100,  100, 0.95)
  t_n1000 <- threshold_sample_size_first(1000, 1000, 100, 0.95)

  expect_true(t_n1000 > t_n100)
})

test_that("Threshold-first round-trips with sample-size-first", {
  # Derive a threshold for a specific (baseline, test_samples, confidence),
  # then recover the confidence with the inverse.
  original_confidence <- 0.95
  threshold <- threshold_sample_size_first(95, 100, 50, original_confidence)
  recovered <- threshold_first_implied_confidence(95, 100, 50, threshold)

  expect_equal(recovered$implied_confidence, original_confidence, tolerance = 1e-4)
})

test_that("Threshold-first flags unsound when threshold too close to baseline", {
  # Threshold very close to baseline rate => low implied confidence.
  result <- threshold_first_implied_confidence(95, 100, 100, 0.949)

  expect_true(result$implied_confidence < 0.80)
  expect_false(result$is_sound)
})
