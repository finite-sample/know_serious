# Public data scope

The public repository includes the published replication bundles and numeric column
extracts from the 2004 survey and the earliest available 2008 checkpoint. All 1,550
and 1,633 respondents, respectively, remain in these extracts. Selection is by
column, not by respondent, treatment, answer, or statistical result.

The extracts retain the fields needed for release reconstruction and the separate
knowledge and item-selection audit: assignments, answers, scoring components,
party identification, internet measures, and elapsed item times. Unused household
demographics, geographic details, calendar timestamps, and free-text responses are
omitted. Original column names are preserved for provenance; analysis datasets
provide snake_case names.

`scripts/extract_sources.R` verifies original file hashes, writes the CSVs with
`readr::write_csv()`, and checks numeric round trips to a tolerance of 1e-14 and
identical missingness. Decimal serialization can introduce machine-level rounding.
Reconstruction from the extracts still matches every released input value exactly;
the original wide and long recode checkpoint comparisons also pass.

`docs/source_columns.csv` records every source column, its labels, and whether it is
included. `docs/private_source_manifest.csv` records hashes of excluded local source
files. `docs/archive_manifest.csv` pins the public inputs. Reproduction uses only
the committed extracts and published bundle; `make extract` is optional and requires
the local originals.

The complete upstream directory and surrounding historical project are ignored.
One older questionnaire contains embedded vendor login credentials and is excluded.
The clean released `data/raw/final_bundle/Study2Questionnaire.doc` supplies the
questionnaire needed for the audit. No login values are included in this repository.

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
