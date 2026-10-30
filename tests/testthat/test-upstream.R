testthat::test_that("original 2004 and checkpoint 2008 reproduce released fields", {
  source("../../R/upstream.R")
  survey_2004 <- readr::read_csv(
    "../../data/extracted/survey_2004.csv",
    col_types = readr::cols(.default = readr::col_double())
  )
  survey_2008 <- readr::read_csv(
    "../../data/extracted/survey_2008.csv",
    col_types = readr::cols(.default = readr::col_double())
  )
  released <- haven::read_dta("../../data/raw/final_bundle/psk_wide.dta")
  candidate <- reconstruct_upstream(survey_2004, survey_2008)
  comparison <- compare_upstream(candidate, released)
  testthat::expect_true(all(comparison$mismatches == 0))
  testthat::expect_identical(names(candidate), names(released))
  testthat::expect_equal(sum(candidate$pollid == 2004), 618)
  testthat::expect_equal(sum(candidate$pollid == 2008), 1633)
})
