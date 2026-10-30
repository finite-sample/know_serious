testthat::test_that("public source extracts preserve respondents and the allowed numeric schema", {
  source("../../R/source_projection.R")
  inventory <- readr::read_csv("../../docs/source_columns.csv", show_col_types = FALSE)
  for (study in c(2004, 2008)) {
    survey <- readr::read_csv(
      paste0("../../data/extracted/survey_", study, ".csv"),
      col_types = readr::cols(.default = readr::col_double())
    )
    fields <- inventory[inventory$study_year == study, ]
    testthat::expect_identical(names(survey), fields$source_column[fields$included])
    testthat::expect_identical(names(survey), source_projection_columns(study, fields$source_column))
    testthat::expect_equal(nrow(survey), if (study == 2004) 1550 else 1633)
    testthat::expect_false(anyDuplicated(survey$caseid) > 0)
    testthat::expect_true(all(vapply(survey, is.numeric, logical(1))))
    testthat::expect_false(any(grepl("age|state|county|date|other|email|address", names(survey))))
  }
})
