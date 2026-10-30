testthat::test_that("Senate key changes are distinct from partial-credit changes", {
  source("../../R/knowledge_scores.R")
  respondents <- data.frame(caseid = 1:4, pk = c(6.5, 7, 7, 6), kn_snmajr = c(.5, 1, 1, 0))
  original <- data.frame(caseid = 1:4, rk = c(1, 1, 2, 2), f2 = c(49, 51, 49, NA))
  columns <- c(paste0("e10_", 1:4), "e11", "e12")
  keys <- c(4, 1, 1, 1, 1, 4)
  for (index in seq_along(columns)) original[[columns[index]]] <- c(rep(keys[index], 3), NA)
  for (column in c(paste0("kne10", letters[1:4]), "kne11", "kne12")) {
    original[[column]] <- c(1, 1, 1, 0)
  }
  result <- alternative_knowledge_scores(respondents, original[4:1, ])
  testthat::expect_equal(result$strict_caucus, c(6, 7, 7, 6))
  testthat::expect_equal(result$strict_party, c(7, 6, 7, 6))
  testthat::expect_equal(result$omit_senate, rep(6 * 13 / 12, 4))
  testthat::expect_equal(result$expanded_items, c(12.5, 13, 13, 6) * 13 / 19)
  testthat::expect_identical(result$caseid, respondents$caseid)
  original$kne11[1] <- 0
  testthat::expect_error(alternative_knowledge_scores(respondents, original))
})
