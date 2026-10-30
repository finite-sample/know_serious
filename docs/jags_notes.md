# JAGS probability replication

The two hierarchical models preserve the archived likelihood and priors,
including coefficient precision 1e-8, threshold precision 0.01, sorted thresholds,
and a uniform 0–2 prior on the respondent-intercept standard deviation. The
random effects use the equivalent noncentered form `z ~ normal(0, 1)` and
`eta = sigma * z` rather than directly sampling `eta ~ normal(0, sigma)`.
The induced density is `phi(eta / sigma) / sigma`, identical to the archived
Gaussian random-effect density for every positive sigma. This changes sampling
coordinates, not the posterior target. Boundary and probability-invariance tests
verify the transformation. Added deterministic nodes compute group means of
conditional probabilities. Group weights sum to one over observed
responses in each treatment arm, matching the original R probability summaries.

The pooled sample contains 4,324 item responses and uses monetary treatment plus
nine item indicators. The study 2 sample contains 3,276 responses and uses appeal,
monetary treatment, and four item indicators. Category indices are explicitly
1 = uncongenial, 2 = correct, 3 = congenial. Respondent indexing is constructed
from precisely the rows used in the design matrix.

`03_jags.R` uses four chains with explicit seeds 123457–123460, dispersed initial
values, 5,000 adaptation iterations, 10,000 discarded burn-in iterations, and
12,500 sampling iterations per chain (50,000 total), retaining every tenth draw.
On Unix, four independent chains run in separate processes via standard
`parallel::mclapply`; Windows uses a serial fallback with the same explicit
seeds. Each completed chain and its internal RNG/model state are checkpointed. Adaptation
must succeed. All monitored coefficients, thresholds, standard deviation, and
arm-specific probabilities must have coda potential scale reduction below 1.01
and effective sample size at least 400. If these checks fail, the runner continues each chain from its saved latent
variables and internal RNG state in blocks of 5,000 sampling iterations, up to
100,000 sampling iterations per chain; failure at that limit stops execution. Diagnostics are written before the gate
so a failed run can be investigated; failure is not a passing replication.

The original script used one chain without an explicit seed or separate
burn-in. It sampled 50,000 iterations for the pooled model and 5,000 for the
study 2 hierarchical model, thinning by ten. Modern sampling therefore improves
diagnostics and Monte Carlo precision without changing model specification.
Numerical equality with a single unseeded historical realization is not expected.
The released CSVs do not supply chain draws or Monte Carlo standard errors, so
new-run MCSE alone cannot establish a formal test of agreement with them.

These are posterior probabilities conditional on estimated respondent random
effects, averaged over each arm's observed responses. They are distinct from
GLLAMM probabilities integrated over the random-effects distribution. The paper's
use of GLLAMM points and JAGS intervals should be assessed with that distinction
visible; the JAGS summaries are not silently substituted for marginal points.

References: official [rjags manual](https://cran.r-project.org/web/packages/rjags/rjags.pdf)
and [coda manual](https://cran.r-project.org/web/packages/coda/coda.pdf).

## Figure interval provenance

The canonical July 29 replication ZIP, preserved in `data/raw/final_bundle`,
contains literal Figure 1 interval endpoints that agree with the archived JAGS
95% endpoints after rounding to two decimal places. The pipeline checks all 20
endpoints to within 0.005 percentage points and writes the comparison to
`tabs/figure_1_interval_provenance.csv`.

An earlier extracted July 15 working copy contained different literals. That
initial concern was resolved by checking the final ZIP; it is not a defect in
the published replication bundle. The JAGS model definitions and released data
are identical between these copies.

`06_figure_one.R` reconstructs the final bundle's display in
`figure_1_historical`: marginal model points with the literal JAGS intervals.
`figure_1_rerun` pairs conditional posterior means with their matching JAGS 95%
credible intervals. Its source CSV separately retains marginal-model points and
conditional-minus-marginal differences for comparison. It does not combine
points and intervals from different estimands in the corrected plot.

## Centered sampler diagnostic

The initial centered parameterization was run for 5,000 adaptation, 10,000
burn-in, and 12,500 sampling iterations per chain across four chains. It failed
the convergence gate: sigma had R-hat 1.42858 and effective sample size 56.87.
Arm-specific probabilities already had R-hat at most 1.00254 and effective sample
sizes 2,177–4,745, but this does not justify accepting an unconverged variance
parameter. The centered diagnostic is retained in
`tabs/jags_centered_diagnostics.csv`. A centered retry was stopped and the
mathematically equivalent noncentered form was implemented to address the
poor mixing near zero variance. Pilot diagnostics and full-run diagnostics are
kept separately; pilot success is not counted as full-run validation.

A noncentered pilot used four chains with 2,000 adaptation, 2,000 burn-in, and
2,500 sampling iterations per chain. Sigma improved to R-hat 1.00648 and
effective sample size 337.82 despite one fifth as many sampling iterations as
the centered run. The short pilot still failed the full gate for some item
coefficients and thresholds (maximum R-hat 1.09397; minimum effective sample
size 68.01). This motivated a full run with the specified longer adaptation,
burn-in, and sampling schedule; pilot output is kept in
`tabs/jags_noncentered_pilot_diagnostics.csv` and is not used in figures.

The retained centered benchmark is reproducible by calling
`fit_jags_replication(assembled, model_path, noncentered = FALSE)` with the
default four-chain schedule. The default `noncentered = TRUE` selects the
equivalent parameterization used by the analysis pipeline. The saved fit's
`settings$parameterization` records which form was actually sampled.

## Continuation and retained chain indexing

The full noncentered pooled run with 12,500 sampling iterations per chain passed
all R-hat checks (maximum 1.005876). Only the threshold effective sample sizes,
372.43 and 364.05, were below the required 400. Sigma had R-hat 1.003536 and
effective sample size 1,283.09. Further sampling therefore continues the saved
chains rather than replaying their original adaptation and burn-in.

Continuation verifies a SHA-256 digest of the complete assembled JAGS inputs,
restores each chain's stochastic nodes and internal RNG state, and re-establishes
sampler tuning with 1,000-iteration adaptation blocks (maximum 5,000), followed
by one iteration that ends adaptation. These tuning iterations are discarded;
no original 10,000-iteration burn-in is repeated. Additional samples are joined
within their originating chain after matching parameter names. Chain identities
are never pooled before diagnostics. The retained-chain index excludes the
restart adaptation gap; each gap is recorded separately in fit metadata.

Individual extension results are saved before concatenation. The saved fit
retains all draws and current states; `tabs/jags_run_settings.csv` records the
actual schedule, input digest, and per-chain continuation adaptation counts in a
plain-text artifact. The original centered failure and short noncentered pilot
remain separate from the accepted full-run outputs.

## Completed full-run validation

Both models passed the retained convergence gates. All runs used four chains,
5,000 initial adaptation iterations, 10,000 initial burn-in iterations, and
thinning by ten. The pooled model required one continuation; study 2 required
none.

| Model | Sampling iterations per chain | Retained draws, all chains | Maximum R-hat | Minimum effective sample size |
|---|---:|---:|---:|---:|
| Studies 1 and 2 | 17,500 | 7,000 | 1.009946 | 485.75 |
| Study 2 | 12,500 | 5,000 | 1.005432 | 683.06 |

The pooled continuation restored each chain's saved state and RNG and discarded
1,001 adaptation iterations per chain before collecting its additional 5,000
sampling iterations. `tabs/jags_run_settings.csv` records these settings and the
input digests; `tabs/jags_diagnostics.csv` contains every monitored parameter.

Across plotted cells, the maximum absolute differences between conditional
posterior means and reproduced marginal GLLAMM points are **0.025817 percentage
points** for the pooled panel and **0.056521 percentage points** for study 2.
These are small numerical differences. They reflect both different prediction
targets and different original scale priors: JAGS uses a uniform(0, 2) prior on
the random-effect standard deviation, whereas GLLAMM applies a gamma(shape 2,
scale 10,000) penalty to the variance. The observed differences cannot be
attributed to conditioning versus integration alone.

Maximum absolute differences from the archived JAGS posterior means are
0.032154 percentage points in the pooled panel and 0.079889 percentage points
in study 2. This describes close numerical agreement; missing historical chain
draws and Monte Carlo standard errors preclude a formal simulation-error test.

Both Figure 1 variants were regenerated. The rerun figure uses conditional
posterior means with their matching 95% credible intervals; its PNG was visually
inspected, and all ten plotted means and interval mappings were checked against
the generated CSV. The final bundle's historical interval endpoints agree with
the archived CSVs within two-decimal rounding (maximum 0.004469 percentage
points).
