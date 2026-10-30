testthat::test_that("all Table 1 point estimates reproduce published precision", {
  source("../../R/descriptive.R")
  responses <- readRDS("../../data/build/published_long.rds")
  benchmarks <- readr::read_csv("../../tabs/table_1_benchmarks.csv", show_col_types = FALSE)
  for (study in unique(benchmarks$study)) {
    selected <- switch(study,
      pooled = responses[which(responses$r_bushref == 0 & !is.na(responses$pay)), ],
      study_2004 = responses[which(responses$pollid == 2004), ],
      study_2008 = responses[which(responses$pollid == 2008 & responses$r_bushref == 0), ]
    )
    actual <- response_statistics(selected, if (study == "study_2008") "rd" else "pay")
    reference <- benchmarks[benchmarks$study == study, ]
    testthat::expect_true(all(abs(unname(actual[reference$statistic]) * 100 - reference$published) <= .05))
  }
  testthat::expect_equal(nrow(benchmarks), 44)
})

testthat::test_that("Table 1 distinguishes participation and usable response counts", {
  counts <- readr::read_csv("../../tabs/table_1_count_benchmarks.csv", show_col_types = FALSE)
  testthat::expect_true(all(counts$respondents_match))
  testthat::expect_true(all(counts$responses_match))
  study_one <- counts[counts$study == "study_2004", ]
  testthat::expect_equal(study_one$reproduced_respondents - study_one$usable_respondents, c(5, 2))
})

testthat::test_that("completion audit distinguishes assignment, entry, and last-item response", {
  original <- readr::read_csv(
    "../../data/extracted/survey_2004.csv",
    col_types = readr::cols(.default = readr::col_double())
  )
  released <- readRDS("../../data/build/published_wide.rds")
  study_one <- released[released$pollid == 2004, ]
  testthat::expect_equal(sum(original$treat == 1), 775)
  testthat::expect_equal(nrow(study_one), 618)
  testthat::expect_equal(sum(study_one$l10 != -2 & !is.na(study_one$l10)), 614)
  testthat::expect_true(all(study_one$dropout[study_one$l10 == -2] == 1))
})

testthat::test_that("final post-randomization dropout counts reproduce both appendices", {
  respondents <- readRDS("../../data/build/published_wide.rds")
  first <- respondents[respondents$pollid == 2004 & respondents$dropout == 1, ]
  second <- respondents[respondents$pollid == 2008 & respondents$dropout == 1, ]
  testthat::expect_equal(as.integer(table(factor(first$rd, levels = c(0, 2)))), c(3L, 4L))
  testthat::expect_equal(as.integer(table(factor(second$rd, levels = 0:2))), c(2L, 5L, 1L))
  testthat::expect_true(all(is.na(second$l5)))
  testthat::expect_equal(sum(respondents$complete == 1, na.rm = TRUE), 1511)
})

testthat::test_that("prose comparison does not silently clear known discrepancies", {
  claims <- readr::read_csv("../../tabs/prose_claims.csv", show_col_types = FALSE)
  completion <- claims[claims$claim_id == "reached_last_item_2004", ]
  testthat::expect_equal(completion$status, "differs")
  testthat::expect_equal(completion$estimate, 614)
  prediction <- claims[grepl("predicted_bias", claims$claim_id), ]
  testthat::expect_equal(nrow(prediction), 4)
  testthat::expect_true(all(prediction$status == "matches"))
  final_comments <- claims[grepl("July 29 final script comment", claims$reference_source), ]
  testthat::expect_equal(nrow(final_comments), 3)
})

testthat::test_that("published significance wording is checked against exact effects and SE rounding", {
  source("../../R/descriptive.R")
  responses <- readRDS("../../data/build/published_long.rds")
  pooled <- responses[which(responses$r_bushref == 0 & !is.na(responses$pay)), ]
  effect <- unname(response_statistics(pooled, "pay")["contrast_1_congenial"])
  lower_p <- pnorm(-abs(effect / .0155))
  testthat::expect_gt(lower_p, .001)
  delta <- unname(cluster_delta_standard_errors(pooled, "pay")["contrast_1_congenial"])
  testthat::expect_gt(pnorm(-abs(effect / delta)), .001)
  testthat::expect_lt(pnorm(-abs(effect / delta)), .01)
  claims <- readr::read_csv("../../tabs/prose_significance.csv", show_col_types = FALSE)
  testthat::expect_equal(claims$exact_effect[claims$claim_id == "pooled_congenial_significance"], effect)
  testthat::expect_equal(claims$table_rounding_incompatible_with_prose, c(TRUE, FALSE))
})
