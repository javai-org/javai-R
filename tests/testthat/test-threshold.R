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

test_that("Larger baseline sample produces higher threshold", {
  t_small <- threshold_sample_size_first(95, 100, 50, 0.95)
  t_large <- threshold_sample_size_first(950, 1000, 50, 0.95)

  expect_true(t_large > t_small)
})

test_that("Perfect baseline does not produce threshold of 1.0", {
  threshold <- threshold_sample_size_first(100, 100, 50, 0.95)

  expect_true(threshold < 1.0)
  expect_true(threshold > 0.90)
})

test_that("Threshold-first round-trips with sample-size-first", {
  # Derive a threshold, then recover the confidence
  original_confidence <- 0.95
  threshold <- threshold_sample_size_first(95, 100, 50, original_confidence)
  recovered <- threshold_first_implied_confidence(95, 100, threshold)

  expect_equal(recovered$implied_confidence, original_confidence, tolerance = 1e-4)
})

test_that("Threshold-first flags unsound when threshold too close to baseline", {
  # Threshold very close to baseline rate => low implied confidence
  result <- threshold_first_implied_confidence(95, 100, 0.949)

  # This should require very low confidence, likely unsound
  expect_true(result$implied_confidence < 0.80)
  expect_false(result$is_sound)
})
