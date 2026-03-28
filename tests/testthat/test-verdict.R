test_that("Clear pass is detected", {
  result <- evaluate_verdict(48, 50, 0.90, 0.95)

  expect_true(result$passed)
  expect_equal(result$observed_rate, 0.96)
  expect_equal(result$false_positive_probability, 0)
})

test_that("Clear fail is detected", {
  result <- evaluate_verdict(40, 50, 0.90, 0.95)

  expect_false(result$passed)
  expect_equal(result$observed_rate, 0.80)
  expect_equal(result$false_positive_probability, 0.05)
})

test_that("Perfect score passes", {
  result <- evaluate_verdict(50, 50, 0.95, 0.95)

  expect_true(result$passed)
  expect_equal(result$observed_rate, 1.0)
})

test_that("Zero successes fails", {
  result <- evaluate_verdict(0, 50, 0.90, 0.95)

  expect_false(result$passed)
  expect_equal(result$observed_rate, 0.0)
})

test_that("Test statistic is positive when passing", {
  result <- evaluate_verdict(48, 50, 0.90, 0.95)

  expect_true(result$test_statistic > 0)
})

test_that("Test statistic is negative when failing", {
  result <- evaluate_verdict(40, 50, 0.90, 0.95)

  expect_true(result$test_statistic < 0)
})
