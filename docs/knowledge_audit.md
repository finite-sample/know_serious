# Knowledge and item-selection audit

The initial alternatives preserve the direction of knowledge moderation. Changing Senate
credit or the Senate key barely changes the probability contrast; adding six knowledge
items gives a larger estimated contrast. This is stability within the tested family,
not evidence that every defensible measure would give the same result.

## Knowledge scoring

Every row uses the same 1,260 respondents and 6,233 item responses, the published
multinomial model, and equal weights over the same five economic items. The quantity
is the incentive effect on response bias at score 9.5 minus its effect at 4.5.
Negative values mean a larger reduction at higher measured knowledge. Scores are
rescaled to 0–13; these are fixed fractions of each scale, not identical latent
knowledge levels or each alternative's own quartiles.

| Knowledge score | Difference in effects (pp) | Pointwise 95% interval | Joint interaction p |
|---|---:|---:|---:|
| Published score | -7.82 | [-14.70, -0.93] | 0.0366 |
| Strict Senate, appendix key (51/49) | -7.79 | [-14.51, -1.08] | 0.0288 |
| Strict Senate, party membership (49/49) | -7.95 | [-14.73, -1.17] | 0.0276 |
| Omit Senate item | -7.86 | [-14.46, -1.26] | 0.0286 |
| Add six knowledge items | -10.00 | [-17.05, -2.95] | 0.0076 |

Intervals use the complete inverse-Hessian covariance and the delta method. The joint
test addresses both model-scale interaction coefficients; it is distinct from the
probability contrast. This retrospective family is exploratory and unadjusted for
multiple comparisons. Differences between alternative point estimates have not been
tested using their joint sampling covariance. Knowledge is not randomized.

Original-score incentive effects and model-based 95% intervals:

- At score 4.5: -1.09 points [-6.94, 4.76].
- At score 9.5: -8.91 points [-14.29, -3.53].
- Knowledge gradient under incentives: -2.43 points [-6.33, 1.46].

The lower-score result does not establish no incentive effect. Nonrejection of
the incentive-arm knowledge gradient does not establish that the association disappears.

## What the alternatives change

The fractional Senate component is explicitly present in the released recode script.
It is an intentional published rule, not an accidental R translation. The strict
appendix-key score separates the effect of partial credit from the answer key.
The literal-party variant reflects the questionnaire's wording about party members:
the 110th Senate had 49 Democrats, 49 Republicans, and two other senators who caucused
with Democrats. See the [official Senate history](https://www.senate.gov/about/parties-leadership/party-division.shtml).
The original visual-recoding script remains missing, so the upstream rationale is
not fully recovered. Both keys are reported rather than selecting one by its result.

The six added questions concern four Iraq authorization votes and two ideological
orderings. Their raw-response indicators exactly match the checkpoint's binary
scores. This alternative broadens political knowledge beyond the selected recognition
items and treats missing extra answers as zero, as those checkpoint scores do.
It is a different measurement choice, not a demonstrated correction. Knowledge
screens E/F precede the incentive instructions at Screen L-Intro in the questionnaire.

## Missing knowledge scores

All 103 respondents missing the published score also lack party identification.
Filling knowledge alone adds 0 model rows and 0 usable respondents.
They also lack substantive economic answers. Thus the apparent score-missingness
issue does not by itself alter Table 4's sample. Fifteen respondents already in
that sample have a missing numeric Senate response and published Senate credit zero;
the strict alternatives retain that zero to hold the sample fixed.

## Economic-item selection

The pooled monetary-versus-control bias effect is -5.38 points. Omitting each published
item in turn gives effects from -6.61 to -4.11 points; all remain negative.
3 of the ten two-sided 95% respondent-cluster delta intervals include zero.
These omit: Uninsured 2008, Gas Price 2008, Debt 2004. This interval
convention differs from the paper's one-sided tests. The result is sensitivity in
magnitude and precision, not a sign reversal. Omissions also change the relative
numbers of observed answers from each study; these are response-weighted pooled
comparisons, not estimates standardized to a fixed study mixture.

## Reproduce and extend

After `make analysis`, run `make sensitivity` and `Rscript scripts/09_report.R`.
`make audit` computes the original-score contrasts alone. All alternative fits
pass convergence, positive-Hessian, gradient, and 31/61-node quadrature checks.
The baseline coefficients, tables, and historical figures are preserved.

- [Retrospective plan](sensitivity_plan.md)
- [Score comparisons and intervals](../tabs/knowledge_sensitivity.csv)
- [Score changes](../tabs/knowledge_score_changes.csv)
- [Fit diagnostics](../tabs/knowledge_sensitivity_diagnostics.csv)
- [Economic-item comparisons](../tabs/economic_item_sensitivity.csv)
- [Knowledge sensitivity figure](../figs/knowledge_sensitivity.pdf)

The author's rationale for excluding the six knowledge items remains unresolved.
Randomized-format effects, leave-one-knowledge-item-out checks, and adding the
omitted 2004 tax-comparison and campaign-proposal questions require further work.
Those questions need explicit construct and partisan-direction definitions before
they can be treated as interchangeable economic outcomes.
