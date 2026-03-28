test_that("Zero samples are never feasible", {
  result <- check_feasibility(0.90, 0, 0.95)

  expect_false(result$feasible)
})

test_that("Minimum samples are sufficient", {
  result <- check_feasibility(0.90, 30, 0.95)

  if (result$feasible) {
    n_minus_1 <- check_feasibility(0.90, result$minimum_samples - 1L, 0.95)
    expect_false(n_minus_1$feasible)
  }
})

test_that("Higher target requires more samples", {
  low_target <- check_feasibility(0.50, 100, 0.95)
  high_target <- check_feasibility(0.95, 100, 0.95)

  expect_true(high_target$minimum_samples > low_target$minimum_samples)
})

test_that("Higher confidence requires more samples", {
  low_conf <- check_feasibility(0.90, 100, 0.90)
  high_conf <- check_feasibility(0.90, 100, 0.99)

  expect_true(high_conf$minimum_samples > low_conf$minimum_samples)
})

test_that("Near-perfect target requires very large sample", {
  result <- check_feasibility(0.9999, 100, 0.95)

  expect_false(result$feasible)
  expect_true(result$minimum_samples > 10000)
})
