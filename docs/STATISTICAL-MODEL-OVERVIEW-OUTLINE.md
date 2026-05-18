The statistical companion is now doing two jobs at once:

1. A rigorous statistical reference for reviewers, implementors, and auditors.
2. A conceptual justification for why probabilistic testing is needed at all.

Those audiences should not be forced through the same document. A 2–3 page summary should be positioned as the front door: it tells a non-statistician what problem the model solves, what kind of evidence it produces, and what it deliberately does not claim.

Here is the structure I want to use for a new document called STATISTICAL-MODEL-OVERVIEW.md:

---

## Suggested title

Probabilistic Testing: A Practical Summary of the javai Statistical Model

Alternative, punchier:

Testing When One Run Is Not Evidence

---

## Recommended 2–3 page structure

### 1. Motivation: deterministic testing breaks at uncertainty's boundary

Start with the central contrast:

Traditional software testing assumes that the same input should produce the same output. For deterministic software, that assumption is usually sound: one failing test is meaningful evidence of a defect. But modern AI-backed services, especially LLM-based services, often do not behave that way. Their behaviour is distributional. The same prompt may produce a correct response most of the time, an invalid response occasionally, and a borderline response rarely.

This is directly aligned with the companion's opening claim that LLMs promote uncertainty from a nuisance to an intrinsic property of the system under test, and that "the distribution of outputs is the behaviour."

Then state the practical consequence:

In such systems, the question is no longer simply "did this invocation pass?" The better question is: "how often does this service satisfy its contract, under stated conditions, and with what evidential strength?"

That gives the reader the whole motivation without statistical overload.

---

### 2. Scope: what the model is for

This section should be very explicit.

The model covers two main forms of stochastic behaviour:

The javai model focuses on two quality dimensions: functional stochasticity, meaning whether the service produces an acceptable result, and temporal stochasticity, meaning how long successful invocations take. Correctness is modelled as repeated pass/fail observations; latency is modelled through empirical percentiles rather than averages. The two dimensions are both required for an overall verdict, but the model does not assume they are statistically independent.

Then define what it does not try to do:

The model does not claim to prove that an AI system is safe, truthful, or correct in any absolute sense. It provides disciplined, repeatable evidence about observed behaviour under stated sampling conditions. It is therefore a testing and evidence framework, not a philosophical theory of AI correctness.

That sentence will make statisticians and auditors more comfortable.

---

### 3. The core model, in plain language

Avoid formulas here, or include only one optional boxed formula. Explain:

Each invocation of the service is treated as a trial. For a given criterion — for example, "the response parses as JSON" or "the answer satisfies a rubric" — the trial either passes or fails. Repeating the invocation over a defined set of inputs produces a count: how many trials passed out of how many attempted. Under stated assumptions of approximate independence and stationarity, that count can be treated as binomial evidence about the service's success rate.

Then introduce Wilson, but don't teach it:

The model uses Wilson score bounds rather than naive observed percentages. This matters because an observed rate is not the same thing as a reliable lower bound. If a service passes 95 out of 100 trials, the model does not pretend the true success rate is exactly 95%. It asks what lower success rate is still compatible with the evidence at the configured confidence level.

This is the key non-statistician insight.

---

### 4. Compliance vs regression

This is one of the companion's most important conceptual contributions, and it should be in the summary.

The model distinguishes two testing questions that are often confused. A compliance test asks whether the service has shown enough evidence to satisfy an external requirement, such as an SLA, SLO, or policy threshold. A regression test asks whether current behaviour has degraded relative to a measured baseline. Both use repeated observations and one-sided decision rules, but the interpretation of PASS and FAIL differs. A compliance PASS means evidence supports compliance at the configured level. A regression PASS means no degradation signal was observed at the configured cutoff; it does not prove equivalence to the baseline.

This is very important for avoiding overclaiming.

---

### 5. Criteria: why one "overall correctness" number is not enough

The per-criterion model is a strong differentiator, but the summary should avoid getting bogged down.

Suggested wording:

Real service contracts rarely contain one kind of failure. A malformed JSON response, a slightly unsuitable tone, a missing required field, and a safety violation are all "failures," but they are not failures of the same kind. Aggregating them into one pass rate can hide exactly the failure mode that matters most. The javai model therefore allows a contract to be decomposed into criteria, each with its own threshold, confidence level, input set, and verdict.

Then the statistical caveat:

The combined contract verdict is structural: all required criteria must pass. The model does not assume that criteria are statistically independent merely because they are reported separately.

That is statistician-safe.

---

### 6. Empirical vs categorical clauses

This deserves a short section because it addresses a likely objection: "surely some failures are unacceptable at any rate."

Suggested wording:

The model distinguishes between failures that are tolerable only below a stated rate and failures that are not tolerable as rate-bounded claims at all. An empirical clause says, in effect, "this behaviour must succeed at least this often." A categorical clause says, "this must not happen." The model does not pretend that setting a threshold to 99.999% converts a categorical obligation into a statistical one. Intolerable failures are handled architecturally — for example by guardrails, filters, schemas, or refusal mechanisms — and those architectural controls can themselves be tested statistically.

The companion's best one-liner should appear here:

> Tolerable failures are bounded statistically; intolerable failures are bounded architecturally; and the architecture itself is bounded statistically.

That is memorable and defensible.

---

### 7. What the model offers that ordinary tests cannot

This is the "so what?" section.

I would list four claims:

First, it turns flaky-looking behaviour into measurable behaviour.
Second, it separates observed rates from statistically supported claims.
Third, it records the assumptions under which a verdict is meaningful: model version, factor configuration, covariates, baseline age, sampling design, and population claim.
Fourth, it produces audit-friendly evidence: counts, thresholds, confidence bounds, cutoffs, caveats, and provenance.

Transparent statistics mode is explicitly framed in the companion as serving auditors, stakeholders, educators, and regulators by exposing the reasoning behind verdicts.

---

### 8. What the model does not offer

This section is essential. It prevents hype.

Suggested wording:

The model does not remove uncertainty. It measures it. It does not guarantee that future behaviour will match past behaviour. It assumes, and then documents, the conditions under which repeated observations can be interpreted: approximate independence, stationarity, and a defined input population. Where those assumptions are doubtful, the model does not magically repair them; it surfaces the doubt as part of the evidence trail.

This is a strong closing because it sounds honest.

---

## A compact draft opening

You could begin the summary like this:

Traditional automated testing was built for systems whose behaviour is expected to be deterministic. Given the same input, the same output should appear; if it does not, the test fails. That premise does not hold for many AI-backed services. A Large Language Model may produce an acceptable answer most of the time, a malformed answer occasionally, and a dangerous or policy-violating answer rarely. In such systems, behaviour is not a single outcome but a distribution of outcomes.

The javai probabilistic testing model provides a disciplined way to test such systems. It treats repeated invocations as evidence, not noise. Instead of asking whether one run passed, it asks how often a defined contract is satisfied under stated conditions, how strong the evidence is, and what assumptions are required for the verdict to be meaningful.

The model is frequentist by default. Its core functional model treats each criterion as a stream of pass/fail trials, aggregates those trials with binomial reasoning, and uses Wilson score bounds to avoid over-reading raw percentages. A reported confidence level is therefore not a claim that an individual verdict has a certain probability of being correct. It is a statement about the long-run behaviour of the decision procedure under the stated assumptions.
