# Independent model implementation review

The ordinal and multinomial fitting objectives agree with the supplied GLLAMM
source. An independently written respondent-by-respondent adaptive integration
check, using `stats::integrate()` rather than the implementation's quadrature
helper, matched the saved Table 2 column 1 objective to displayed machine precision
and Table 4 within 1.53e-9. The independently checked computation multiplied each
respondent's conditional response probabilities before integrating over that
respondent's normal random intercept.

## Verified implementation details

- `gllam_ll.ado`'s unexpanded nominal-response branch assigns the same random
  intercept to both nonreference logits, and leaves the reference numerator at one.
  The R multinomial probabilities reproduce this restriction. Independent
  category-specific random effects would be a different model.
- `calc_prior.ado` computes the gamma density on `CHmat * CHmat'` when the variance
  option is requested. The R penalty is gamma(shape=2, scale=10000) on the random
  variance. The log-standard-deviation parameterization is an optimizer transform;
  no Jacobian belongs in this penalized objective.
- The ordinal cutpoints are increasing by construction. The inverse observed
  Hessian estimates covariance in the fitted coordinates; the coefficient block
  does not need another transform. The random-variance standard error correctly
  uses derivative `2 * variance` with respect to log standard deviation.
- GLLAMM preserves its penalized criterion in `e(ll)` and stores the unpenalized
  value in `e(a_ll)` (`gllamm.ado`, lines 2479–2483). Consequently, matching legacy
  `lrtest` requires the penalized criterion, as implemented. This reproduces the
  legacy diagnostic; it does not independently establish its asymptotic reference
  distribution under penalization.
- Specification filters and complete-case selection reproduce the intended
  ordinal, nominal, and item-specific samples. Study 1 drops from models requiring
  `acc`, `mon`, `app`, or `pk` because those fields are missing there.

## Prediction sample correction

The first R prediction export used the whole specification input. The original
`gllapred.ado` explicitly restricts to `e(sample)` unless `fsample` is requested
(lines 185–193). The published calls do not request `fsample`. Predictions must
therefore use the fitted rows, not every row with complete predictors.

The corrected exports now contain exactly 4,324 rows for Table 2 column 1, 3,276
for Table 2 column 2a, and 6,233 for Table 4. Their respondent/item keys agree with
`fit$rows`; probability columns are unique, interior, and agree with independently
recomputed model predictions within 5.6e-16. The explicit export columns also avoid
accidentally exporting the existing binary response indicators as probabilities.

Before this correction, Table 4's average predicted correct probability was .323055
in control and .323891 under incentives. Restricting to the estimation sample gives
.332680 and .333749. The correction changes prediction averaging and the knowledge
curves, not the fitted coefficients. For Figure 1a, the corrected bias estimates
are 11.7681 and 6.33395 percentage points, agreeing with the printed 11.8 and 6.3.

## Remaining limits

The IIA routine intentionally reproduces the published equation-matching calculation
and flags its defects. Reversing the Hausman order alone does not fix the change of
reference category when the congenial category is omitted, nor does it repair an
indefinite covariance difference. These diagnostics cannot be labeled valid
chi-square evidence for IIA. No substantive treatment-coefficient error follows
from this diagnostic problem alone.

The model integration check establishes numerical accuracy at the checked fitted
parameters. It does not prove that every optimizer run found a global optimum.
Convergence, Hessian, gradient, and quadrature-comparison outputs remain necessary.
The original Stata runtime has not been executed locally. Exact handling of tied
LOWESS values and nested-estimator bootstrap sampling still require that runtime
or corresponding implementation source.

The July 29 canonical analysis retains the reviewed model specifications,
prediction calls, and IIA commands. The prediction-sample correction described
here fixes the initial R translation, not the published Stata implementation.

The final and older copies of `gllam_ll.ado`, `calc_prior.ado`, `gllapred.ado`,
and `gllamm.ado` are byte-identical, so their cited implementation lines apply
to the final release.
