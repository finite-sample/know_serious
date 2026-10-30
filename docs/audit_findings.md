# Replication findings

The July 29, 2015 replication bundle is the canonical source. All 41 released input
fields reconstruct from the earliest available survey files, and every value and
missingness position in the released wide and long analytical files agrees with the
R recodes. All 44 Table 1 point estimates, 14 respondent/response counts, and 304
checked model benchmarks reproduce at their published precision. These agreements
support numerical reproduction, not every interpretation attached to the results.

## Significance reporting

The published article's pooled congenial-answer effect is −4.769162 percentage
points. The prose reports p < .001, while Table 1 gives an SE of 1.6 points. Under
the stated one-sided testing convention, even the smallest SE that rounds to 1.6
(1.55) implies p ≥ .001046. The reconstructed bootstrap gives p = .001918 and an
independent cluster delta calculation gives p = .001466. Those two reconstructed
values are checks, not recovered original Stata draws. The reduction remains
supported at .01; the stronger prose threshold does not follow from the table.

For the accuracy appeal, the prose's p < .05 and Table 1's plus marker (< .10)
are also inconsistent as significance labels. This result is near the boundary:
the rounded SE permits either side of .05, so the original draws are needed to
resolve which label was intended. See `prose_significance.csv` and
[publication verification](publication_verification.md).

## IIA diagnostic

The supplied Hausman–McFadden calls reverse the model order in Stata's documented
example. Reversing that order changes the three reproduced statistics from roughly
1.704, .583, and −21.251 to −1.704, −.583, and 21.251. Neither ordering produces
positive-definite covariance differences in these fits. Omitting the reference
outcome also changes coefficient interpretation. The reported tests therefore do
not establish IIA. This is a diagnostic failure; it does not itself establish an
error in the reproduced treatment coefficients. See [model notes](model_notes.md)
and `model_iia_diagnostics.csv`.

## Samples and comparisons

The paper describes 618 Study 1 respondents as reaching the final economic item.
Four retained records instead code that item as not asked, leaving 614 with a
recorded final-item response. The archive retains the published analysis sample
and records the discrepancy rather than choosing a new sample.

Table 1's participant counts include seven Study 1 people with no classifiable
answer. The counts and response proportions reproduce, but their denominators
should not be conflated. Similarly, the quoted 14.6-point bias among consistent
partisans describes Study 2, while the comparison of 11.5 points pools both studies;
the corresponding all-partisan Study 2 figure is 9.9 points. These comparisons
change study coverage as well as respondent composition.

## Posterior computation and figure interpretation

The original centered JAGS parameterization failed the modern multi-chain check
for the random-effect scale. The failed diagnostics are retained in
`jags_centered_diagnostics.csv`. The computational replacement writes each random
intercept as its standard deviation times a standard-normal latent variable,
which preserves the model and priors. Both final four-chain runs pass the
diagnostic gates: every monitored R-hat is below 1.01 and every effective sample
size is at least 400. Actual schedules and diagnostics are retained in
`jags_run_settings.csv` and `jags_diagnostics.csv`.

The final bundle's Figure 1 endpoints agree with the archived JAGS CSVs after
rounding. The original figure combines marginal GLLAMM points with conditional
JAGS intervals. The archive preserves that historical construction and separately
plots conditional posterior means with their matching intervals. It does not
interpret the two constructions as the same estimand.
The estimators also use different priors on the random-effect scale, as in the
original scripts. Differences between their outputs cannot be attributed solely
to conditioning versus integration.

## Source limits and separate sensitivity audit

The original 2008 delivery and visual-recoding script are absent; the available
checkpoint already contains some upstream coding. Exact Stata bootstrap-wrapper
behavior and tied-observation sorting have not been executed locally. The R
bootstrap standard errors agree with the independent cluster delta calculation
within three approximate Monte Carlo standard errors in all 44 comparisons.

An older extracted July 15 folder has stale intervals, dropout code, and comments.
Those differences are superseded in the July 29 bundle and are not findings about
the published archive. Knowledge scoring and item inclusion remain unchanged;
their reassessment is recorded in [the separate knowledge audit](knowledge_audit.md).
