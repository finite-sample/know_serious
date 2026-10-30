# Local validation

Validation used R 4.6.0 on macOS with the packages in `renv.lock`. JAGS 4.3.2
was built locally because the system package-manager directory was not writable.
`rjags` was built against that installation. The temporary JAGS installation is
not bundled; reproduction requires an installed JAGS runtime.

The analysis stages were executed individually during development. This is not
a claim that a fresh container completed `make check` in one invocation.

- `make restore` verified that the local library agrees with the lockfile.
- `Rscript scripts/verify_sources.R` verified all 74 public input hashes.
- Preparation rebuilt all release-input fields and both recoded checkpoints.
- The model stage fitted the published specifications and additional diagnostics.
  `validate_model_outputs()` passed against the generated outputs.
- Preparation, descriptive estimation, Figure 2, prose checks, validation, and
  table generation were rerun after migration to `readr` CSV input and output.
- `make lint test` passed with 144 assertions, no failures, no warnings, and no skips.
- `actionlint .github/workflows/check.yml` passed.
- `make tables-pdf` built the nine-page table booklet with XeLaTeX.
- A relocated copy passed source-hash verification, model-output
  validation, and all 144 test assertions using the existing locked library.
  Saved posterior draws also reproduce their diagnostics in a fresh R process.
  These checks cover relative paths and file completeness, not dependency installation
  on a clean operating system.

The R project now lives at the Git repository root. The 377 files from the
previous surrounding project were moved into the ignored `historical/`
directory and verified byte-for-byte after the move. The repository is named
`know_serious`, following the `finite-sample/know_*` family; its R project
identifier is `serious`. `make test` reconstructs the required datasets so that
the test suite does not depend on an existing `data/build/` cache.

The MCMC stage records its parameter-level convergence results in
`tabs/jags_diagnostics.csv`. Its runner stops unless every monitored parameter
has finite R-hat below 1.01 and effective sample size at least 400. Failed
centered and short-pilot diagnostics are retained separately and do not count
as successful validation. `docs/session_info.txt` records the R environment.

No Stata executable was available to resolve exact nested-wrapper bootstrap
behavior or tied-value LOWESS ordering. The Docker daemon was unavailable and
Colima was not installed, so a local clean-container run was unavailable.
The repository includes the standard-container command and GitHub workflow for
that check. The later GitHub execution is recorded below.

## Public-only checkout validation

The public extracts reconstruct all 41 release fields and both recode checkpoints
without a value or missingness mismatch. A separate checkout containing only the
intended public files passes source verification (74 files), lint, and all 156
test assertions using the existing locked R library. It contains no full upstream
directory or historical project. This verifies input completeness without claiming
a clean operating-system dependency installation or a new full MCMC run.

The direct knowledge-contrast and scoring tests bring the local test total to 166.
The separate sensitivity family retains 1,260 respondents and 6,233 responses in
all five models. Every alternative passes the optimizer, Hessian, gradient, and
31/61-node quadrature gates. Original-score delta uncertainty is also checked
against an analytic multinomial derivative. The Table B3 render preserves small
coefficients (including 0.004), and the booklet includes counts and equality-test
and fit-statistic rows. Full GitHub container execution was pending at this stage.

## Correctness audit (October 30, 2026)

`make lint test` passes 204 assertions with no warnings or skips. All 77 public
input hashes verify. The six alternative outcome fits retain 1,260 respondents
and 6,233 responses, converge with positive Hessians, and pass gradient and
31/61-node integration gates. An independent read-only calculation reproduced
all saved descriptive treatment effects and cluster standard errors, then all
nine contrasts for seven model definitions using a separate multinomial formula,
101-node integration, and finite-difference delta uncertainty; the largest SE
difference was 1.8e-9 percentage points. The original published recode checkpoints
still reproduce exactly. The correctness report is generated from its CSV outputs.

A new public-only copy also passed preparation, the item-level correctness checks,
report regeneration, all 77 source hashes, lint, and 204 test assertions. This copy
uses the existing locked library; alternative models were fitted locally from the
same public inputs, not refitted again in this copy. Full container CI was pending at this stage.

## Completed container replication

[GitHub run 41094030573](https://github.com/finite-sample/know_serious/actions/runs/41094030573)
passed at commit `90b5d693a72ecdbec275152dfeef2cd1def247b9`. The job installed
JAGS in `rocker/verse:4.6.0` and completed `make restore check`, including the full
analysis, lint, and tests. This establishes clean-container execution for that
commit. The separately invoked correctness and knowledge-sensitivity model families
retain the local validation described above.
