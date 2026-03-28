test_that("Smaller effect size requires more samples", {
  large_effect <- required_sample_size(0.95, 0.10, 0.95, 0.80)
  small_effect <- required_sample_size(0.95, 0.05, 0.95, 0.80)

  expect_true(small_effect$required_samples > large_effect$required_samples)
})

test_that("Higher power requires more samples", {
  low_power <- required_sample_size(0.95, 0.05, 0.95, 0.80)
  high_power <- required_sample_size(0.95, 0.05, 0.95, 0.95)

  expect_true(high_power$required_samples > low_power$required_samples)
})

test_that("Higher confidence requires more samples", {
  low_conf <- required_sample_size(0.95, 0.05, 0.90, 0.80)
  high_conf <- required_sample_size(0.95, 0.05, 0.99, 0.80)

  expect_true(high_conf$required_samples > low_conf$required_samples)
})

test_that("Achieved power meets or exceeds target", {
  result <- required_sample_size(0.95, 0.05, 0.95, 0.80)

  expect_true(result$achieved_power >= 0.80)
})

test_that("Achieved power at computed sample size is close to target", {
  result <- required_sample_size(0.95, 0.05, 0.95, 0.80)

  # Should be close to 0.80 (within a few percent, due to ceiling)
  expect_true(result$achieved_power >= 0.80)
  expect_true(result$achieved_power < 0.90)
})
