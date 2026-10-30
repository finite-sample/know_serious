# Data

`raw/` contains immutable copies of the available source material. The July 29,
2015 replication ZIP is the canonical release; the earlier extracted working
copy is retained in `raw/historical_2015_07_15/` for provenance comparison.
The canonical files are in `raw/final_bundle/`. Input hashes are in
[`archive_manifest.csv`](../docs/archive_manifest.csv).

The pipeline uses committed column extracts from the original 2004 survey and the
earliest located 2008 checkpoint. `extracted/survey_2004.csv` and
`extracted/survey_2008.csv` preserve every respondent and the needed numeric fields.
The full upstream files stay local and ignored; `make extract` is the optional
maintainer command that creates these CSVs from hash-verified originals.
See [public data scope](../docs/public_data.md).
It reconstructs all 41 release-input columns, then applies the published recodes.
The 2008 checkpoint already contains coding whose original delivery and visual
recode script were not located. No alternative scoring or item selection is used.

`build/respondents.rds` contains 2,251 respondent rows.
`build/responses.rds` contains 11,255 respondent-item rows: five economic items per
respondent within each study. Both use descriptive snake_case names. The underlying
legacy-named reconstructions are saved separately for exact source comparisons.
Intermediate files are regenerated, not edited manually.

[`data_dictionary.csv`](../tabs/data_dictionary.csv) preserves the release's
variable descriptions and value labels and maps them to the modern names.
[`variable_crosswalk.csv`](../tabs/variable_crosswalk.csv) provides the naming map.
The source questionnaires are retained with the canonical bundle.

Negative response codes are distinct from genuine zero and from system missing
values. Published rules for refusal, unasked items, gas-price units, categorical
answer direction, and correct-answer windows are implemented in `R/recode.R`.
Knowledge components retain their original scoring, including the fractional
Senate component. See [recode notes](../docs/recode_notes.md).

Respondent counts and usable-answer counts are different quantities. Some
participants contribute no classifiable economic answer; see the generated
Table 1 count comparisons. Treatment and knowledge missingness are reported
explicitly rather than converted to zero without a published coding rule.

The separate correctness audit uses `economic_references_2008.csv` (under
`data/extracted/`): respondent IDs, a conservative date-dependent unemployment key,
and the existing respondent-linked national gas reference. It publishes no actual
calendar timestamps, state prices, or geography. Unemployment changes to 5.1 only
for interviews starting April 5, 2008 or later. Gas references follow interview
finish date and are labeled previous-day prices; the original download and exact
item timestamps are unavailable. These references are sensitivity targets, not
recovered payment rules. `scripts/extract_sources.R` produces them from pinned
local originals. Two aggregate window-provenance files are preserved under
`data/raw/window_provenance/`; their original bytes are hash-pinned in the archive
manifest. They contain historical definitions and summaries, not microdata.
