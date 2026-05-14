#' Inferential-criterion verdict (companion §1.4.5, §1.4.6, §3.4, SC-RU-02)
#'
#' Per-inferential-criterion verdict generation, separated by procedure
#' direction (REGRESSION vs COMPLIANCE). Each procedure has its own
#' null/alternative, its own decision rule, and its own p-value tail.
#'
#' Shared mechanics:
#'   - Effective denominator n_c derived from policy (§1.4.5a):
#'       CONDITIONAL_ON_EVALUABLE:           n_c = n_evaluable
#'       MARGINAL_COUNT_UNEVALUABLE_AS_FAIL: n_c = n_attempted
#'     K_c is the count of postcondition successes among the evaluable
#'     trials in either case; unevaluable trials never contribute to
#'     K_c (the postcondition could not be checked on them).
#'   - p_hat_c = K_c / n_c (the policy-aware point estimate).
#'   - Feasibility gate (§8.4): refuses the inferential claim when
#'     n_c is too small to support the target proportion at confidence
#'     1 - alpha. Threshold target depends on procedure.
#'   - Inconclusive outcomes: n_c == 0, or feasibility gate REFUSE.
#'
#' REGRESSION (decision on integer cutoff per SC-RU-02):
#'   H_0: p_c >= p*_c (no degradation)
#'   H_1: p_c <  p*_c (degradation)
#'   p*_c = WilsonLB(p_hat_baseline; n_c, alpha)      [real-valued]
#'   c    = ceiling(n_c * p*_c)                       [integer cutoff]
#'   PASS iff K_c >= c
#'   p_value: lower-tail under H_0 boundary p = p*_c, i.e.
#'            P_{p*_c}(K <= K_c). Smaller K is more extreme in the
#'            direction of H_1.
#'
#' COMPLIANCE (decision on Wilson lower bound clearing requirement):
#'   H_0: p_c <= p_req
#'   H_1: p_c >  p_req
#'   wlr  = WilsonLB(p_hat_c; n_c, alpha)
#'   PASS iff wlr > p_req
#'   p_value: upper-tail under H_0 boundary p = p_req, i.e.
#'            P_{p_req}(K >= K_c). Larger K is more extreme in the
#'            direction of H_1.
#'
#' Three-strand verdict fields:
#'   - statistical:           PASS, FAIL, or INCONCLUSIVE.
#'   - observed_rate_status:  ABOVE_THRESHOLD / BELOW_THRESHOLD /
#'                            AT_THRESHOLD / NOT_APPLICABLE.
#'                            For REGRESSION the threshold is p*_c; for
#'                            COMPLIANCE it is p_req.
#'   - operational_caution_category: ADEQUATE_POWER /
#'                            STRANDS_DISAGREE / FEASIBILITY_REFUSED /
#'                            ZERO_EVALUABLE / FAIL_CLEAR.
#'                            A coarse classification surface that
#'                            frameworks can use to render the
#'                            "operational caution" prose of §10.3.

regression_verdict <- function(n_attempted, n_evaluable, K_c, alpha,
                               denominator_policy,
                               baseline_successes, baseline_trials) {
  n_c <- if (denominator_policy == "CONDITIONAL_ON_EVALUABLE")
    n_evaluable else n_attempted
  r_obs <- if (n_attempted == 0) 0 else n_evaluable / n_attempted

  if (n_c == 0) {
    return(list(
      n_c = as.integer(n_c), r_obs = r_obs,
      p_hat_c = NA_real_,
      wilson_lower_real = NA_real_, cutoff_integer = NA_integer_,
      achieved_size = NA_real_,
      feasibility_gate = "REFUSE",
      verdict = "INCONCLUSIVE",
      p_value = NA_real_,
      p_value_method = "exact-binomial-lower-tail",
      p_value_tail = "P_{p=p_star_c}(K <= K_c)",
      statistical_verdict = "INCONCLUSIVE",
      observed_rate_status = "NOT_APPLICABLE",
      operational_caution_category = "ZERO_EVALUABLE"
    ))
  }

  p_hat_baseline <- baseline_successes / baseline_trials
  # Perfect-baseline compression (§4.3.2): if baseline is perfect, use
  # Wilson lower bound of the baseline as the effective rate before
  # deriving the test threshold.
  effective_baseline <- if (baseline_successes == baseline_trials) {
    wilson_lower(baseline_successes, baseline_trials, 1 - alpha)
  } else {
    p_hat_baseline
  }

  wlr <- wilson_lower_from_rate(effective_baseline, n_c, 1 - alpha)
  cutoff <- as.integer(ceiling(n_c * wlr))
  achieved <- pbinom(cutoff - 1, size = n_c, prob = effective_baseline)
  # Feasibility gate (§8.4): the sample must be sufficient to support
  # an inferential claim against the effective baseline rate at the
  # stated confidence. A test against a near-perfect baseline at a
  # tiny n_c is structurally unable to support the claim, regardless
  # of the (degenerate) Wilson bound that emerges.
  feas <- check_feasibility(target_proportion = effective_baseline,
                            sample_size = n_c, confidence = 1 - alpha)
  feasibility_gate <- if (feas$feasible) "ADMIT" else "REFUSE"

  if (feasibility_gate == "REFUSE") {
    return(list(
      n_c = as.integer(n_c), r_obs = r_obs,
      p_hat_c = K_c / n_c,
      wilson_lower_real = wlr, cutoff_integer = cutoff,
      achieved_size = achieved,
      feasibility_gate = "REFUSE",
      verdict = "INCONCLUSIVE",
      p_value = NA_real_,
      p_value_method = "exact-binomial-lower-tail",
      p_value_tail = "P_{p=p_star_c}(K <= K_c)",
      statistical_verdict = "INCONCLUSIVE",
      observed_rate_status = "NOT_APPLICABLE",
      operational_caution_category = "FEASIBILITY_REFUSED"
    ))
  }

  passed <- K_c >= cutoff
  verdict <- if (passed) "PASS" else "FAIL"

  p_hat_c <- K_c / n_c
  # Lower-tail p-value under H_0 boundary p = p*_c
  p_value <- pbinom(K_c, size = n_c, prob = wlr)

  observed_rate_status <- if (p_hat_c > wlr) "ABOVE_THRESHOLD"
                          else if (p_hat_c < wlr) "BELOW_THRESHOLD"
                          else "AT_THRESHOLD"

  caution <- if (verdict == "PASS" && observed_rate_status == "ABOVE_THRESHOLD") {
    "ADEQUATE_POWER"
  } else if (verdict == "FAIL" && observed_rate_status == "BELOW_THRESHOLD") {
    "FAIL_CLEAR"
  } else {
    "STRANDS_DISAGREE"
  }

  list(
    n_c = as.integer(n_c), r_obs = r_obs,
    p_hat_c = p_hat_c,
    wilson_lower_real = wlr, cutoff_integer = cutoff,
    achieved_size = achieved,
    feasibility_gate = feasibility_gate,
    verdict = verdict,
    p_value = p_value,
    p_value_method = "exact-binomial-lower-tail",
    p_value_tail = "P_{p=p_star_c}(K <= K_c)",
    statistical_verdict = verdict,
    observed_rate_status = observed_rate_status,
    operational_caution_category = caution
  )
}

compliance_verdict <- function(n_attempted, n_evaluable, K_c, alpha,
                               denominator_policy, p_req) {
  n_c <- if (denominator_policy == "CONDITIONAL_ON_EVALUABLE")
    n_evaluable else n_attempted
  r_obs <- if (n_attempted == 0) 0 else n_evaluable / n_attempted

  if (n_c == 0) {
    return(list(
      n_c = as.integer(n_c), r_obs = r_obs,
      p_hat_c = NA_real_,
      wilson_lower_real = NA_real_,
      feasibility_gate = "REFUSE",
      verdict = "INCONCLUSIVE",
      p_value = NA_real_,
      p_value_method = "exact-binomial-upper-tail",
      p_value_tail = "P_{p=p_req}(K >= K_c)",
      statistical_verdict = "INCONCLUSIVE",
      observed_rate_status = "NOT_APPLICABLE",
      operational_caution_category = "ZERO_EVALUABLE"
    ))
  }

  p_hat_c <- K_c / n_c
  wlr <- wilson_lower_from_rate(p_hat_c, n_c, 1 - alpha)

  feas <- check_feasibility(target_proportion = p_req,
                            sample_size = n_c, confidence = 1 - alpha)
  feasibility_gate <- if (feas$feasible) "ADMIT" else "REFUSE"

  if (feasibility_gate == "REFUSE") {
    return(list(
      n_c = as.integer(n_c), r_obs = r_obs,
      p_hat_c = p_hat_c,
      wilson_lower_real = wlr,
      feasibility_gate = "REFUSE",
      verdict = "INCONCLUSIVE",
      p_value = NA_real_,
      p_value_method = "exact-binomial-upper-tail",
      p_value_tail = "P_{p=p_req}(K >= K_c)",
      statistical_verdict = "INCONCLUSIVE",
      observed_rate_status = "NOT_APPLICABLE",
      operational_caution_category = "FEASIBILITY_REFUSED"
    ))
  }

  passed <- wlr > p_req
  verdict <- if (passed) "PASS" else "FAIL"

  # Upper-tail p-value under H_0 boundary p = p_req
  p_value <- 1 - pbinom(K_c - 1, size = n_c, prob = p_req)

  observed_rate_status <- if (p_hat_c > p_req) "ABOVE_THRESHOLD"
                          else if (p_hat_c < p_req) "BELOW_THRESHOLD"
                          else "AT_THRESHOLD"

  # STRANDS_DISAGREE arises classically in COMPLIANCE: observed rate
  # above the requirement, but Wilson lower bound below it. The §10.3
  # layperson-readable case is the canonical example.
  caution <- if (verdict == "PASS" && observed_rate_status == "ABOVE_THRESHOLD") {
    "ADEQUATE_POWER"
  } else if (verdict == "FAIL" && observed_rate_status == "ABOVE_THRESHOLD") {
    "STRANDS_DISAGREE"
  } else if (verdict == "FAIL" && observed_rate_status == "BELOW_THRESHOLD") {
    "FAIL_CLEAR"
  } else {
    "STRANDS_DISAGREE"
  }

  list(
    n_c = as.integer(n_c), r_obs = r_obs,
    p_hat_c = p_hat_c,
    wilson_lower_real = wlr,
    feasibility_gate = feasibility_gate,
    verdict = verdict,
    p_value = p_value,
    p_value_method = "exact-binomial-upper-tail",
    p_value_tail = "P_{p=p_req}(K >= K_c)",
    statistical_verdict = verdict,
    observed_rate_status = observed_rate_status,
    operational_caution_category = caution
  )
}

#' Generate inferential-criterion verdict reference cases
#'
#' @return A list suitable for JSON serialisation.
#' @export
generate_criterion_verdict_inferential_cases <- function() {

  reg_case <- function(name, n_attempted, n_evaluable, K_c, alpha, policy,
                       baseline_successes, baseline_trials, description = NULL) {
    case <- list(
      name = name,
      procedure = "REGRESSION",
      inputs = list(
        procedure = "REGRESSION",
        n_attempted = as.integer(n_attempted),
        n_evaluable = as.integer(n_evaluable),
        K_c = as.integer(K_c),
        alpha = alpha,
        denominator_policy = policy,
        baseline_successes = as.integer(baseline_successes),
        baseline_trials = as.integer(baseline_trials)
      ),
      expected = regression_verdict(n_attempted, n_evaluable, K_c, alpha,
                                    policy, baseline_successes, baseline_trials)
    )
    if (!is.null(description)) case$description <- description
    case
  }

  com_case <- function(name, n_attempted, n_evaluable, K_c, alpha, policy,
                       p_req, description = NULL) {
    case <- list(
      name = name,
      procedure = "COMPLIANCE",
      inputs = list(
        procedure = "COMPLIANCE",
        n_attempted = as.integer(n_attempted),
        n_evaluable = as.integer(n_evaluable),
        K_c = as.integer(K_c),
        alpha = alpha,
        denominator_policy = policy,
        p_req = p_req
      ),
      expected = compliance_verdict(n_attempted, n_evaluable, K_c, alpha,
                                    policy, p_req)
    )
    if (!is.null(description)) case$description <- description
    case
  }

  cases <- list(
    # REGRESSION — clear PASS: K well above cutoff.
    reg_case("regression_clear_pass_consult_advice_well_formed",
             n_attempted = 1000, n_evaluable = 1000, K_c = 953, alpha = 0.05,
             policy = "MARGINAL_COUNT_UNEVALUABLE_AS_FAIL",
             baseline_successes = 951, baseline_trials = 1000,
             description = "§10.3 C_well_formed: K = 953 well above the derived cutoff."),

    # REGRESSION — clear FAIL: K well below cutoff.
    reg_case("regression_clear_fail_K_far_below_cutoff",
             n_attempted = 1000, n_evaluable = 1000, K_c = 850, alpha = 0.05,
             policy = "MARGINAL_COUNT_UNEVALUABLE_AS_FAIL",
             baseline_successes = 951, baseline_trials = 1000),

    # REGRESSION — borderline: K right at cutoff boundary.
    # SC-RU-02 worked example has cutoff = 91 for n=100; K=91 should PASS,
    # K=90 should FAIL.
    reg_case("regression_borderline_pass_K_equals_cutoff",
             n_attempted = 100, n_evaluable = 100, K_c = 91, alpha = 0.05,
             policy = "MARGINAL_COUNT_UNEVALUABLE_AS_FAIL",
             baseline_successes = 951, baseline_trials = 1000,
             description = "SC-RU-02 worked example: cutoff = 91; K = 91 → PASS (boundary)."),

    reg_case("regression_borderline_fail_K_one_below_cutoff",
             n_attempted = 100, n_evaluable = 100, K_c = 90, alpha = 0.05,
             policy = "MARGINAL_COUNT_UNEVALUABLE_AS_FAIL",
             baseline_successes = 951, baseline_trials = 1000,
             description = "SC-RU-02 worked example: cutoff = 91; K = 90 → FAIL."),

    # REGRESSION — INCONCLUSIVE via n_c = 0.
    reg_case("regression_inconclusive_zero_evaluable",
             n_attempted = 0, n_evaluable = 0, K_c = 0, alpha = 0.05,
             policy = "MARGINAL_COUNT_UNEVALUABLE_AS_FAIL",
             baseline_successes = 951, baseline_trials = 1000),

    # REGRESSION — INCONCLUSIVE via feasibility gate. Demanding threshold,
    # tiny n_c.
    reg_case("regression_inconclusive_feasibility_refused",
             n_attempted = 5, n_evaluable = 5, K_c = 5, alpha = 0.001,
             policy = "MARGINAL_COUNT_UNEVALUABLE_AS_FAIL",
             baseline_successes = 999, baseline_trials = 1000),

    # REGRESSION — policy difference. Same raw counts under two policies.
    # n_attempted=1000, n_evaluable=950, K_c=950. Under CONDITIONAL the
    # effective n_c=950 and the test compares K_c=950 to cutoff at n=950
    # against baseline 0.951. Under MARGINAL the effective n_c=1000 and
    # K_c=950 vs cutoff at n=1000 (lower threshold), but the unevaluable
    # 50 trials make K_c=950 < cutoff.
    reg_case("regression_policy_diff_conditional",
             n_attempted = 1000, n_evaluable = 950, K_c = 950, alpha = 0.05,
             policy = "CONDITIONAL_ON_EVALUABLE",
             baseline_successes = 951, baseline_trials = 1000,
             description = "Same data as the next case under different policy. CONDITIONAL: only the 950 evaluable trials count; observed rate is 1.0."),

    reg_case("regression_policy_diff_marginal",
             n_attempted = 1000, n_evaluable = 950, K_c = 950, alpha = 0.05,
             policy = "MARGINAL_COUNT_UNEVALUABLE_AS_FAIL",
             baseline_successes = 951, baseline_trials = 1000,
             description = "Same data as the previous case under MARGINAL: unevaluable trials count toward n_c but not K_c, so K_c/n_c = 0.95."),

    # COMPLIANCE — clear PASS: observed well above requirement, sample large.
    com_case("compliance_clear_pass",
             n_attempted = 10000, n_evaluable = 10000, K_c = 9990,
             alpha = 0.05, policy = "MARGINAL_COUNT_UNEVALUABLE_AS_FAIL",
             p_req = 0.99),

    # COMPLIANCE — clear FAIL: Wilson lower well below requirement.
    com_case("compliance_clear_fail",
             n_attempted = 1000, n_evaluable = 1000, K_c = 800,
             alpha = 0.05, policy = "MARGINAL_COUNT_UNEVALUABLE_AS_FAIL",
             p_req = 0.95),

    # COMPLIANCE — the canonical §10.3 layperson-readable disagreement:
    # p_hat = 0.985, p_req = 0.98, but Wilson LB at α = 0.001 below req.
    com_case("compliance_strands_disagree_consult_advice_layperson",
             n_attempted = 800, n_evaluable = 800, K_c = 788,
             alpha = 0.001, policy = "CONDITIONAL_ON_EVALUABLE",
             p_req = 0.98,
             description = "§10.3 C_layperson_readable: p_hat = 0.985 > p_req = 0.98, but Wilson LB ≈ 0.967 < 0.98 at α = 0.001 → FAIL with strands disagreeing."),

    # COMPLIANCE — INCONCLUSIVE via n_c = 0.
    com_case("compliance_inconclusive_zero_evaluable",
             n_attempted = 0, n_evaluable = 0, K_c = 0,
             alpha = 0.05, policy = "MARGINAL_COUNT_UNEVALUABLE_AS_FAIL",
             p_req = 0.95),

    # COMPLIANCE — INCONCLUSIVE via feasibility gate.
    com_case("compliance_inconclusive_feasibility_refused",
             n_attempted = 5, n_evaluable = 5, K_c = 5,
             alpha = 0.05, policy = "MARGINAL_COUNT_UNEVALUABLE_AS_FAIL",
             p_req = 0.999)
  )

  list(
    suite = "criterion_verdict_inferential",
    description = paste(
      "Per-inferential-criterion verdict cases, partitioned by",
      "procedure direction (REGRESSION vs COMPLIANCE). REGRESSION",
      "tests for degradation from a baseline (H_1: p_c < p*_c) and",
      "decides on the SC-RU-02 integer cutoff K_c >= c. COMPLIANCE",
      "tests whether the rate clears a requirement (H_1: p_c > p_req)",
      "and decides on the Wilson lower bound exceeding p_req. The",
      "effective denominator n_c is derived from the §1.4.5a policy.",
      "Each case carries the three-strand verdict and the p-value",
      "method/tail metadata."
    ),
    method = paste(
      "REGRESSION: Wilson lower bound centred on baseline rate at",
      "test n_c, integer cutoff via ceiling, decision K_c >= c;",
      "p-value = P_{p=p*_c}(K <= K_c) lower tail.",
      "COMPLIANCE: Wilson lower bound centred on observed p_hat_c at",
      "test n_c, decision wlr > p_req; p-value = P_{p=p_req}(K >= K_c)",
      "upper tail. Feasibility gate per §8.4."
    ),
    tolerance = 1e-9,
    cases = cases
  )
}
