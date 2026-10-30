source("R/upstream.R")
survey_2004 <- readr::read_csv(
  "data/extracted/survey_2004.csv",
  col_types = readr::cols(.default = readr::col_double())
)
survey_2008 <- readr::read_csv(
  "data/extracted/survey_2008.csv",
  col_types = readr::cols(.default = readr::col_double())
)
released <- haven::read_dta("data/raw/final_bundle/psk_wide.dta")
upstream <- reconstruct_upstream(survey_2004, survey_2008)
comparison <- compare_upstream(upstream, released)
stopifnot(all(comparison$mismatches == 0))
dir.create("tabs", showWarnings = FALSE)
readr::write_csv(comparison, "tabs/upstream_comparison.csv")
dir.create("data/build", recursive = TRUE, showWarnings = FALSE)
saveRDS(upstream, "data/build/upstream_wide.rds")
