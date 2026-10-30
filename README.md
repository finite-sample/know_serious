# You Cannot Be Serious

Replication and audit of Markus Prior, Gaurav Sood, and Kabir Khanna (2015),
*The Impact of Accuracy Incentives on Partisan Bias in Reports of Economic Perceptions*,
[Quarterly Journal of Political Science, 10(4), 489–518](https://doi.org/10.1561/100.00014127).

Repository name: `know_serious`, in the `finite-sample` political-knowledge family
alongside `know_hidden` and `know_motivated`.

The experiments ask whether accuracy incentives change partisan reports of economic
conditions. This repository reconstructs the published definitions and item selection;
a separate sensitivity audit revisits knowledge measurement and item inclusion.

## Results and audit

<!-- results:start -->
Monetary incentives reduce congenial answers from 39.6% to 34.8% across the two studies (4.8 percentage points). The congenial-minus-uncongenial gap falls from 11.5 to 6.1 points.

All 304 checked model benchmarks reproduce at published precision. The audit identifies a prose p-value threshold
inconsistent with Table 1, a small completion-definition discrepancy, and invalid IIA diagnostic inference.
These findings do not establish a change in the reproduced treatment coefficients. See the
[published-article verification](docs/publication_verification.md) and [model audit](docs/model_audit.md).

The original 2008 delivery is absent; preparation starts from its earliest available checkpoint.
Exact Stata bootstrap-wrapper behavior and clean-container execution remain unverified.
Knowledge scoring and item-selection sensitivities are reported separately in the
[knowledge audit](docs/knowledge_audit.md); the publication baseline is preserved.
<!-- results:end -->

See the [table-by-table and figure-by-figure status](docs/exhibit_status.md) for
exact matches, approximate reproductions, and interpretation limits.

Open the [generated report](docs/report.html), [table booklet](docs/tables.pdf),
or [audit findings](docs/audit_findings.md).

## Reproduce

Use R 4.6.0 and JAGS 4.3.2. From this directory:

```
make restore
make check
```

`make check` runs the analysis, lints the R code, and runs substantive tests.
`make test` rebuilds the analysis datasets and runs the tests without rerunning
the full model estimation and MCMC. `make prepare` rebuilds those datasets alone.
`make audit` computes direct knowledge contrasts from fitted models.
`make sensitivity` fits the separate scoring alternatives and economic-item checks
after model estimation. `make ci-docker` uses the standard Rocker image and installs JAGS. The full analysis
includes repeated numerical optimization and four-chain MCMC, so it is not a smoke test.
`make tables-pdf` builds a standalone table booklet when XeLaTeX and latexmk are installed.
Generated estimates, comparisons, and diagnostics are CSV files in `tabs/`; figures
are in `figs/`. Intermediate datasets and fitted models are in `data/build/`.
Git tracks the source inputs, R code, tests, documentation, tables, and figures.
Installed packages and intermediate datasets and model objects are ignored;
the analysis commands regenerate them from the preserved inputs.

The lockfile restores packages into `.library/`, which `.Rprofile` adds to R’s library path.
The Docker target uses a separate package library for Linux.

## Sources and scope

The canonical source is the July 29, 2015 bundle, preserved as extracted files in
`data/raw/final_bundle/`. The extracted July 15 working copy is retained in
`data/raw/historical_2015_07_15/`
for historical comparison; its superseded code is not the publication baseline.

Published source copies are in `data/raw/final_bundle/`; the additional survey
columns used in reconstruction and sensitivity analysis are in `data/extracted/`.
`docs/archive_manifest.csv` pins the copied inputs by SHA-256;
`Rscript scripts/verify_sources.R` checks them. `docs/source_manifest.csv` inventories
the larger historical project. Its original files, including `PSK_Replication.zip`,
are preserved byte-for-byte in the local, ignored `historical/` directory. Paths
in that inventory are relative to `historical/`. All inputs required to reproduce
the analysis are tracked under `data/raw/`, `data/extracted/`, and `docs/published/`.
The full upstream files remain local and ignored. The public extracts omit unused
demographics and free text; see [public data scope](docs/public_data.md).
The final manuscript and appendix are preserved in `docs/published/`.

The 2004 source reconstruction agrees with the released wide data. The earliest
available 2008 checkpoint already contains some recodes; the original survey delivery
and visual-recoding script are absent. The July 29 release supplies the completion and dropout rules. See [source audit](docs/source_audit.md).

The executable preparation reconstructs all 41 released input columns.
The subsequent recodes are compared against both released recoded files
(2,251 respondents and 11,255 respondent-item rows).
Descriptive public datasets use snake_case names, with a [crosswalk](tabs/variable_crosswalk.csv).
Legacy identifiers are retained internally for exact source comparisons.

## Pipeline

Reusable functions are in `R/`; scripts execute preparation, descriptive estimates,
models, JAGS sampling, figures, and claim comparisons. The Makefile supplies the
entrypoints. Source files never serve as output destinations.

The GLLAMM translation explicitly integrates respondent random effects and applies
the original gamma penalty to their variance. It checks numerical gradients,
curvature, and quadrature refinement. Matching an ordinal model's name is insufficient
because an unpenalized mixed model would estimate a different objective.

Bootstrap estimates use respondent resampling and 1,000 replications. R and Stata
have different random streams; seed equality does not imply identical simulated
standard errors. JAGS retains the original priors, with explicit seeds and multiple
chains added for reproducibility and convergence assessment.

## Audit and follow-up

- [Audit findings](docs/audit_findings.md)
- [Source and claim audit](docs/source_audit.md)
- [Published article verification](docs/publication_verification.md)
- [Recode verification](docs/recode_notes.md)
- [Model implementation and limitations](docs/model_notes.md)
- [Independent model review](docs/model_audit.md)
- [Descriptive estimates and bootstrap limits](docs/descriptive_audit.md)
- [Figure 1 interval provenance](docs/jags_notes.md)
- [Audit check matrix](docs/audit_checks.csv)
- [Local validation and execution limits](docs/local_validation.md)
- [Exhibit and claim inventory](docs/exhibits.csv)
- [Verified code corrections](tabs/corrections.csv)
- [Knowledge and item-selection audit](docs/knowledge_audit.md)
- [Retrospective sensitivity plan](docs/sensitivity_plan.md)

Numerical reproduction, implementation corrections, and alternative analytical
choices are separate. Corrections do not overwrite the historical specification.
Missing validation is reported explicitly; a successful execution alone does not
certify the paper's conclusions. Original materials retain their existing rights.
