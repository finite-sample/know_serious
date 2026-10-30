recode_root <- normalizePath(testthat::test_path("..", ".."))
source(file.path(recode_root, "R", "recode.R"))
recode_inputs <- file.path(recode_root, "data", "raw", "final_bundle")


testthat::test_that("published recodes match every released value and missingness", {
  responses <- haven::read_dta(file.path(recode_inputs, "psk_wide.dta"))
  reconstructed <- recode_published(responses)
  testthat::expect_equal(nrow(reconstructed$wide), 2251L)
  testthat::expect_equal(nrow(reconstructed$long), 11255L)
  for (shape in c("wide", "long")) {
    released <- haven::read_dta(file.path(
      recode_inputs, paste0("psk_", shape, "_recode.dta")
    ))
    keys <- if (shape == "wide") "caseid" else c("caseid", "seq")
    comparisons <- compare_recode_checkpoint(reconstructed[[shape]], released, keys)
    testthat::expect_true(all(comparisons$missing_mismatches == 0))
    testthat::expect_true(all(comparisons$value_mismatches == 0))
    testthat::expect_equal(
      names(reconstructed[[shape]]) |> sort(), names(released) |> sort()
    )
  }
})

testthat::test_that("continuous response windows include endpoints and exclude missing", {
  testthat::expect_equal(
    classify_responses(c(4.19, 4.2, 5.4, 5.41, NA), rep(2, 5)),
    c(0, 1, 1, 2, NA)
  )
  testthat::expect_equal(
    classify_responses(c(3.16, 3.17, 3.27, 3.28, NA), rep(5, 5), "pp"),
    c(0, 1, 1, 2, NA)
  )
  testthat::expect_equal(
    classify_responses(c(1, 2, 0, NA), rep(4, 4)), c(1, 2, NA, NA)
  )
})

testthat::test_that("missingness is preserved and estate tax direction is reversed", {
  responses <- haven::read_dta(file.path(recode_inputs, "psk_wide.dta"))
  reconstructed <- recode_published(responses)
  long <- reconstructed$long
  testthat::expect_true(all(is.na(long$consis[long$pollid == 2004])))
  testthat::expect_true(all(is.na(long$cong_33[is.na(long$dem)])))
  testthat::expect_true(all(is.na(long$cong_33[is.na(long$l)])))
  estate_republicans <- with(long, seq %in% c(4, 7) & dem %in% 0 & tri_33 %in% 2)
  testthat::expect_true(all(long$cong_33[estate_republicans] == 1))
  testthat::expect_equal(
    long$congenial + long$correct + long$uncongenial,
    ifelse(is.na(long$cong_33), NA_real_, 1)
  )
  testthat::expect_true(all(table(long$caseid) == 5))
  testthat::expect_false(anyDuplicated(long[c("caseid", "seq")]) > 0)
  testthat::expect_true(all(is.na(long$t_l[long$pollid == 2004])))
})

testthat::test_that("knowledge sums propagate missingness and retain unlisted codes", {
  responses <- haven::read_dta(file.path(recode_inputs, "psk_wide.dta"))
  responses$e1 <- as.numeric(responses$e1)
  responses$e1[1:3] <- c(NA, -2, -1)
  reconstructed <- recode_published(responses)$wide
  testthat::expect_true(is.na(reconstructed$pk[1]))
  testthat::expect_equal(reconstructed$kne1[2:3], c(-2, 0))
})

testthat::test_that("modern column names remain unique and preserve values", {
  responses <- haven::read_dta(file.path(recode_inputs, "psk_wide.dta"))
  reconstructed <- recode_published(responses)$long
  modern <- modernize_columns(reconstructed)
  testthat::expect_equal(modern$respondent_id, reconstructed$caseid)
  testthat::expect_equal(modern$knowledge_score, reconstructed$pk)
  testthat::expect_false(anyDuplicated(names(modern)) > 0)
  testthat::expect_true(all(grepl("^[a-z][a-z0-9_]*$", names(modern))))
})


testthat::test_that("final completion and dropout recodes follow randomization placement", {
  respondents <- haven::read_dta(file.path(recode_inputs, "psk_wide.dta"))
  rows <- which(respondents$pollid == 2008)[1:5]
  respondents$l5[rows] <- c(NA, NA, NA, -1, NA)
  respondents$r_PIDloc[rows] <- c(0, 1, 0, 0, 1)
  respondents$h1c[rows] <- c(-2, NA, NA, 1, NA)
  respondents$pres_app[rows] <- c(NA, -1, NA, NA, NA)
  reconstructed <- recode_published(respondents)$wide
  testthat::expect_equal(reconstructed$complete[rows], c(0, 0, 0, 1, 0))
  testthat::expect_equal(reconstructed$dropout[rows], c(1, 1, 0, 0, 0))
  study_one <- respondents$pollid == 2004
  testthat::expect_true(all(is.na(reconstructed$complete[study_one])))
  testthat::expect_equal(reconstructed$dropout[study_one], as.numeric(respondents$dropout[study_one]))
})
