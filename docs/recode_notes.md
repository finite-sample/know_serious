# Published data recodes

`R/recode.R` reconstructs the July 29, 2015 `PSK_Recodes.do` in the final root ZIP bundle from the released
`psk_wide.dta`. The checkpoint comparison is distinct from the upstream
reconstruction documented in [the source audit](source_audit.md); the original
2008 survey delivery remains unavailable.

All 135,060 values in the final wide checkpoint (2,251 respondents × 60
columns) and all 979,185 values in the final long checkpoint (11,255 responses
× 87 columns) match exactly after sorting by respondent and item. Missingness
also matches in every column. Each respondent contributes five item rows before
analytical exclusions. The generated `tabs/recode_checkpoints.csv` records the
column-level comparison. These comparisons validate the translation against the
released data; they do not independently validate the original coding decisions.

`data/build/published_wide.rds` and `published_long.rds` preserve legacy names at
the comparison boundary. `respondents.rds` and `responses.rds` expose descriptive
names; `tabs/variable_crosswalk.csv` maps them. The item index identifies the ten
published item/study combinations, not ten items administered to each person.

## Source version

The final July 29 bundle includes `h1c`, `r_PIDloc`, and `dropout`; it omits the
older `incomp` column and constructs `complete` during recoding. The earlier
July 15 folder is retained only as a historical comparison. A complete-column-set
assertion prevents silently comparing against a partial or obsolete schema.

## Semantics retained

- In 2008, completion means the fifth economic response is nonmissing, including
  a refusal code. Dropout begins at zero and becomes one for an incomplete
  respondent who reached the placement-dependent randomization marker (`h1c`
  when party identification is asked later; presidential approval when asked
  earlier). Nonmissing negative codes count as observed markers, matching Stata.
  Study 1 dropout values are retained from the input; completion remains missing.


- Stata `recode` leaves unlisted values unchanged. The R reconstruction retains
  this behavior for the knowledge questions and all other recodes. No observed
  scored knowledge component is negative in these data.
- The knowledge score adds 12 binary components and a senate-majority component
  scored in quarters. Ordinary addition propagates missingness; it does not
  count missing components as zero. The score is missing for all 618 respondents
  in 2004 and 103 of 1,633 respondents in 2008. The 1,530 observed scores range
  from 0 to 13. `tabs/knowledge_components.csv` reports the entire component and
  score distributions by study, including missing values.
- The source comment says consistent partisans include all partisans in 2004,
  but its actual commands assign consistency only in 2008. The released data
  likewise have missing consistency for every 2004 respondent. This is a
  comment/implementation discrepancy; the translation follows the commands.
- Negative economic responses become missing. Gas prices of at least 100 are
  divided by 100, including exactly 100 despite the source comment saying
  “greater than.” Uninsured responses above 100 become missing. These are
  preserved published choices, not newly adopted repairs.
- Estate-tax overestimates are congenial for Republicans and uncongenial for
  Democrats, reversing the direction used for the other items.
- The one-percentage-point gas-price window is 3.17–3.27, unlike the payout
  window of 3.17–3.37. The reconstruction preserves these distinct bounds.
- `l_raw` was created by Stata `generate` as a single-precision float, while the
  response variable retains greater precision. An explicit float32 round-trip
  reproduces its 1,542 storage-rounding differences (maximum approximately
  0.0000061). These are storage differences, not changed substantive responses.
- Long-format response times are missing for 2004 because the released input
  contains timing columns only for the five 2008 items.

The boundary tests cover inclusive continuous windows, estate-tax direction,
missing score components, unlisted negative codes, all checkpoint columns, and
five-row-per-respondent conservation. The separate knowledge and item-selection
review should assess substantive choices after replication is complete.

Data import uses `haven::read_dta`; variable labels remain in immutable source
files, while the reconstruction operates on numeric codes. See the official
[haven import documentation](https://haven.tidyverse.org/reference/read_dta.html).
