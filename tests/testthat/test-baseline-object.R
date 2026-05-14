test_that("Generator emits the expected six baseline cases", {
  result <- generate_baseline_object_cases()
  expect_equal(result$suite, "baseline_object")
  expect_equal(length(result$cases), 6)
  names <- vapply(result$cases, function(c) c$name, character(1))
  expect_true("consult_advice_eu_weekday" %in% names)
  expect_true("paired_evaluability_content_pattern" %in% names)
  expect_true("consult_advice_cross_policy_counterexample" %in% names)
})

test_that("Consult-advice baseline carries the three §10.3 criteria", {
  result <- generate_baseline_object_cases()
  case <- Filter(function(c) c$name == "consult_advice_eu_weekday",
                 result$cases)[[1]]
  criteria <- case$inputs$baseline$criteria
  expect_equal(length(criteria), 3)
  ids <- vapply(criteria, function(c) c$criterion_id, character(1))
  expect_setequal(ids, c("c_well_formed", "c_no_self_harm",
                         "c_layperson_readable"))
})

test_that("Paired baseline declares availability_criterion_ref", {
  result <- generate_baseline_object_cases()
  case <- Filter(function(c) c$name == "paired_evaluability_content_pattern",
                 result$cases)[[1]]
  content <- Filter(function(c) c$criterion_id == "c_layperson_readable",
                    case$inputs$baseline$criteria)[[1]]
  expect_equal(content$availability_criterion_ref, "c_evaluable_response")
  expect_equal(content$denominator_policy, "CONDITIONAL_ON_EVALUABLE")
})

test_that("All criteria carry the two-value denominator-policy enum", {
  result <- generate_baseline_object_cases()
  for (case in result$cases) {
    for (crit in case$inputs$baseline$criteria) {
      expect_true(
        crit$denominator_policy %in%
          c("CONDITIONAL_ON_EVALUABLE", "MARGINAL_COUNT_UNEVALUABLE_AS_FAIL"),
        info = paste(case$name, crit$criterion_id))
    }
  }
})

test_that("Every observation block carries the policy-derived n_c", {
  result <- generate_baseline_object_cases()
  for (case in result$cases) {
    for (crit in case$inputs$baseline$criteria) {
      o <- crit$observation
      expected_nc <- if (crit$denominator_policy == "CONDITIONAL_ON_EVALUABLE")
        o$n_evaluable else o$n_attempted
      expect_equal(o$n_c, expected_nc, info = paste(case$name, crit$criterion_id))
    }
  }
})

test_that("Generator output matches committed fixture", {
  fixture <- jsonlite::fromJSON("../../inst/cases/baseline_object.json",
                                simplifyVector = FALSE)
  generated <- generate_baseline_object_cases()
  expect_equal(length(fixture$cases), length(generated$cases))
  for (i in seq_along(fixture$cases)) {
    expect_equal(fixture$cases[[i]]$name, generated$cases[[i]]$name)
  }
})
