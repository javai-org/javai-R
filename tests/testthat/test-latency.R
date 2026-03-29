test_that("nearest_rank_percentile computes correct index for worked example", {
  # Section 12.2.2: n=200, p50 should use index 99 (100th order statistic)
  set.seed(42)
  latencies <- sort(round(rlnorm(200, meanlog = log(200), sdlog = 0.4)))

  p50 <- nearest_rank_percentile(latencies, 0.50)
  expect_equal(p50, latencies[100])  # ceil(0.50 * 200) - 1 = 99 -> index 100

  p90 <- nearest_rank_percentile(latencies, 0.90)
  expect_equal(p90, latencies[180])  # ceil(0.90 * 200) - 1 = 179 -> index 180

  p95 <- nearest_rank_percentile(latencies, 0.95)
  expect_equal(p95, latencies[190])  # ceil(0.95 * 200) - 1 = 189 -> index 190

  p99 <- nearest_rank_percentile(latencies, 0.99)
  expect_equal(p99, latencies[198])  # ceil(0.99 * 200) - 1 = 197 -> index 198
})

test_that("nearest_rank_percentile handles single observation", {
  result <- nearest_rank_percentile(c(250), 0.99)
  expect_equal(result, 250)
})

test_that("nearest_rank_percentile handles identical values", {
  result <- nearest_rank_percentile(rep(150, 10), 0.95)
  expect_equal(result, 150)
})

test_that("nearest_rank_percentile sorts unsorted input", {
  unsorted <- c(300, 100, 200, 400, 500)
  sorted <- c(100, 200, 300, 400, 500)

  expect_equal(
    nearest_rank_percentile(unsorted, 0.50),
    nearest_rank_percentile(sorted, 0.50)
  )
})

test_that("nearest_rank_percentile: higher percentiles >= lower percentiles", {
  latencies <- c(100, 120, 140, 160, 180, 200, 250, 300, 400, 500,
                 110, 130, 150, 170, 190, 220, 260, 350, 450, 600)

  p50 <- nearest_rank_percentile(latencies, 0.50)
  p90 <- nearest_rank_percentile(latencies, 0.90)
  p95 <- nearest_rank_percentile(latencies, 0.95)
  p99 <- nearest_rank_percentile(latencies, 0.99)

  expect_true(p50 <= p90)
  expect_true(p90 <= p95)
  expect_true(p95 <= p99)
})

test_that("nearest_rank_percentile: p=1 returns maximum", {
  latencies <- c(100, 200, 300, 400, 500)
  expect_equal(nearest_rank_percentile(latencies, 1.0), 500)
})

test_that("latency_summary computes correct statistics", {
  latencies <- c(100, 200, 300, 400, 500)
  result <- latency_summary(latencies)

  expect_equal(result$mean, 300)
  expect_equal(result$sd, sd(c(100, 200, 300, 400, 500)))
  expect_equal(result$max, 500)
})

test_that("latency_threshold_derive matches worked example", {
  # Section 12.4.5: Q=580, s=145, n=935, confidence=0.95 -> threshold=588
  result <- latency_threshold_derive(580, 145, 935, 0.95)

  expect_equal(result$threshold, 588)
})

test_that("latency_threshold_derive: zero variance yields baseline as threshold", {
  result <- latency_threshold_derive(200, 0, 100, 0.95)

  expect_equal(result$threshold, 200)
})

test_that("latency_threshold_derive: threshold never below baseline percentile", {
  # Even if raw_upper < baseline_percentile (can't happen with positive z and
  # positive sd, but the max() floor is the contract)
  result <- latency_threshold_derive(500, 10, 10000, 0.95)

  expect_true(result$threshold >= 500)
})

test_that("latency_threshold_derive: higher confidence yields higher threshold", {
  t_90 <- latency_threshold_derive(300, 100, 500, 0.90)
  t_95 <- latency_threshold_derive(300, 100, 500, 0.95)
  t_99 <- latency_threshold_derive(300, 100, 500, 0.99)

  expect_true(t_90$threshold <= t_95$threshold)
  expect_true(t_95$threshold <= t_99$threshold)
})

test_that("latency_min_samples returns correct minimums", {
  expect_equal(latency_min_samples(0.50), 5L)
  expect_equal(latency_min_samples(0.90), 10L)
  expect_equal(latency_min_samples(0.95), 20L)
  expect_equal(latency_min_samples(0.99), 100L)
})
