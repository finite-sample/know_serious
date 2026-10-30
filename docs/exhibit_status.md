# Table and figure replication status

The main estimates reproduce, but not every displayed element has been verified
as an exact match. The full manuscript rebuild is outside the current scope.
Reproduction and statistical interpretation are assessed separately below.

| Exhibit | Reproduction evidence | Remaining qualification |
|---|---|---|
| Table 1 | All 44 point estimates and 14 counts match at published precision. | 26 of 44 rerun bootstrap SEs match printed rounding; the largest SE difference is 0.2081 percentage points. Exact Stata wrapper sampling behavior remains unverified. |
| Tables 2–4 | Checked coefficients, standard errors, fit statistics, and equality tests reproduce at published precision. | Table 4's IIA diagnostics are not validated chi-square tests; they are excluded from the claim that model benchmarks match. |
| Tables B1–B3 | Checked completion-time, answer-window, and item-specific model benchmarks reproduce at published precision. | The booklet reformats the original tables and now includes equality tests and item-model diagnostics; significance symbols are omitted. |
| Figure 1 | Marginal points are reconstructed; all 20 literal interval endpoints agree with released posterior summaries within 0.005 percentage points. | The historical display combines marginal model points with conditional posterior intervals from a different prior specification. The separate rerun plot pairs posterior means with their matching intervals. |
| Figures 2a–d | Category construction, estimation samples, predictions, and documented Stata LOWESS formulas are reproduced. | Ordering within tied knowledge scores has not been checked in Stata; exact historical curve coordinates are unverified. |
| Figure A1 | The respondent-level knowledge score and party percentages reproduce. | Explicit one-point bins replace implicit Stata defaults; histogram coordinates are not an exact reproduction. |
| Tables A1–A2 | Questionnaire wording and keys are preserved in the source documents. | These documentary tables have not been regenerated as new tables. |

The model benchmark total is 304 checked cells across the main and appendix
models. This count does not include Table 1's bootstrap standard errors, Figure 2
coordinates, or the defective IIA diagnostics.

## What the estimates establish

The descriptive result is a reduction in partisan response bias among classifiable
answers: pooled congenial answers fall from 39.6% to 34.8%, and the congenial-minus-
uncongenial gap falls from 11.5 to 6.1 percentage points. Response-level weighting
gives more weight to respondents with more classifiable answers. This is evidence
about reported answers under the experiment's incentives; it does not by itself
identify underlying beliefs or motives.

The pooled congenial-response effect is -4.769 percentage points. The rerun
bootstrap gives a one-sided p-value of .001918 and an independent respondent-cluster
delta calculation gives .001466. Both support p < .01, but the prose claim p < .001
is incompatible with the exact effect and the published standard-error precision.

The cue interaction's one-sided p = .23 does not establish attenuation. Likewise,
a failure to reject equality of appeal and monetary effects does not establish
equivalence. The knowledge curves show fitted patterns; without direct contrasts
and uncertainty they cannot establish that an incentive effect is absent at low
knowledge or that the knowledge association disappears under incentives.

Direct equal-item contrasts at the baseline knowledge quartiles, 4.5 and 9.5, give
incentive effects on bias of -1.09 points (95% interval -6.94 to 4.76) and -8.91
points (-14.29 to -3.53). Their difference is -7.82 points (-14.70 to -0.93).
The joint interaction test gives chi-square(2) = 6.616, p = .0366. These model-based
comparisons support moderation under the original measurement and specification;
the low-score interval does not establish absence of an effect. Knowledge is not
randomized, so knowledge gradients are associations, not causal knowledge effects.

The [separate knowledge audit](knowledge_audit.md) compares alternative scores and
item selection while preserving the publication baseline.

Detailed evidence: [descriptive audit](descriptive_audit.md),
[model audit](model_audit.md), [JAGS interval audit](jags_notes.md), and
[exhibit inventory](exhibits.csv).
