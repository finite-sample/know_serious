# Published model reconstruction

`R/models.R` implements the likelihood in the supplied GLLAMM source. The ordinal
model has ordered thresholds, item fixed effects, and a normal respondent random
intercept. The multinomial model uses congenial answers as the reference category
and adds the **same** respondent random intercept to both non-reference logits.
This restriction follows the `nominal` routine in the released `gllam_ll.ado`;
substituting independent category-specific random intercepts would change the model.

The fitting criterion is the respondent-integrated log likelihood plus
`dgamma(variance, shape = 2, scale = 10000, log = TRUE)`, matching
`calc_prior.ado`. Parameters are optimized using a log standard deviation and a
log threshold gap. There is no Jacobian in this objective: the transformation is
an optimization device, not a change of prior. Standard errors use the inverse
observed Hessian of that penalized criterion. Reported random-variance standard
errors use the delta method. The unpenalized log likelihood is reported separately.

Each hierarchical specification is estimated using 31 normal quadrature points
and re-estimated at 61 points from that solution. This is ordinary Gauss–Hermite
quadrature, rather than GLLAMM's adaptive quadrature. `model_quadrature.csv`
records the numerical difference. `model_estimates.csv` records convergence,
maximum absolute numerical gradient, and whether the Hessian is positive definite.
No output is called a verified replication solely because the optimizer returned.

`model_benchmarks.csv` compares substantive coefficients and standard errors in
Tables 2–4 to the two-decimal values in the final July 2015 manuscript. A match
requires a difference below 0.005. The source benchmarks are transcribed, not
computed from the replication results. Table B3 uses ordinary proportional-odds
maximum likelihood through `MASS::polr`; the hierarchical tables use the explicit
penalized objective.

Prediction exports integrate over the population distribution of the random
intercept, using each estimation-sample observation's actual covariates. Rows excluded from fitting are also excluded from predictions, matching GLLAPRED's default `e(sample)` restriction. These are the marginal
probabilities requested by the Stata plotting code. They are not conditional
posterior probabilities from JAGS; JAGS uncertainty intervals must be computed
and checked separately before Figure 1 is considered complete.

## Coverage and limitations

Implemented: Tables 2–4 coefficients, Tables B1–B3 coefficients, and marginal
predictions used by Figures 1 and 2. Model fits use the reconstructed long dataset.
The original Stata implementation has not been executed locally, so numerical
validation currently uses published rounded benchmarks and independent numerical
integration checks. All 42 main coefficient/standard-error entries, 156 appendix coefficient and fit-statistic entries, and 106 additional Wald, likelihood-ratio, sample-size and likelihood entries agree at their published precision.

The Table 4 Hausman–McFadden subset fits, footnote 12 unrestricted-incentive
likelihood-ratio comparison, internet-speed interaction comparisons, and
hierarchical joint Wald contrasts are also implemented. The likelihood-ratio
statistics use the penalized objective because GLLAMM stores this as `e(ll)`;
its separate `e(a_ll)` removes the prior contribution.

The IIA code contains an ordering error: it invokes `hausman tab4 omit*`, whereas
Stata's official IIA example uses `hausman omitted all, alleqs constant`.
`model_iia_diagnostics.csv` preserves the original matching-equation statistic
and also reports the sign-reversed statistic under the documented order. The
covariance differences are indefinite in these fits, so the displayed nominal
chi-square probabilities do not provide valid evidence for IIA. Omitting the
congenial baseline additionally changes the coefficient reference category;
equation-name matching alone does not restore a common estimand. These issues
concern the published diagnostic, not an established change in treatment effects.

No alternative knowledge scores or item-selection choices are evaluated here.

The tests verify the estimation-sample restriction, replacement of preexisting binary outcome columns with predicted probabilities, Hausman argument order, quadrature moments, category probability normalization, a
cluster likelihood against a hand-computed integral, and convergence and marginal
probabilities on simulated ordinal data. These tests check implementation
properties; published-number agreement is a separate check.

Official references consulted:

- [R optimization documentation](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/optim.html)
- [statmod manual, normal probability quadrature](https://cran.r-project.org/web/packages/statmod/statmod.pdf)

- [MASS proportional-odds model documentation](https://stat.ethz.ch/R-manual/R-devel/library/MASS/html/polr.html)
- [Stata Hausman test manual](https://www.stata.com/manuals/rhausman.pdf)


## Numerical acceptance

The full stage checks 21 hierarchical specifications, 31-versus-61-point
quadrature differences below 0.0001, positive-definite Hessians, successful
optimizer exit codes, and finite parameters/covariances. Numerical convergence
requires a maximum absolute score below 0.002 or a covariance-scaled score
`sqrt(g' V g)` below 0.01. The latter measures the local optimization error in
standard-error units and avoids treating gradients on different covariate scales
as interchangeable. For example, tightening Table 4 changed coefficients by less
than one millionth, with a covariance-scaled score of 0.00052.

Model outputs are gated against all 304 tabulated benchmarks. The published IIA
statistics are recorded separately because their invalid covariance differences
and the reference-category change preclude a valid chi-square interpretation.
The reconstructed literal IIA values are close but do not all round to the
published values; do not count those diagnostics as exact numerical matches.


## Final-bundle verification

The authoritative replication source is the July 29, 2015 root ZIP, preserved
under `data/raw/final_bundle/`. The earlier July 15 folder was checked against it:
all GLLAMM support `.ado` files and JAGS `.jag` models are byte-identical; all
model, contrast, and prediction commands in `PSK_Analysis.do` are unchanged after
whitespace normalization. `docs/bundle_model_verification.csv` records these
checks. Every shared model-input value is also unchanged. The final bundle adds
completion/dropout source fields, changes completion missingness, and revises
Figure 1's manually inserted intervals. Thus model estimates remain applicable,
while completion analyses and figure interval references use the final bundle.
