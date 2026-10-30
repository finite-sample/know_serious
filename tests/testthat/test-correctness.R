testthat::test_that("factual intervals include endpoints and preserve missing answers", {
  source("../../R/recode.R")
  testthat::expect_equal(
    classify_interval(c(3.16, 3.17, 3.27, 3.37, 3.38, NA), 3.17, 3.37),
    c(0, 1, 1, 1, 2, NA)
  )
  testthat::expect_equal(classify_interval(c(4.3, 4.3), c(4.2, 4.5), c(5.4, 5.7)), c(1, 0))
  testthat::expect_equal(partisan_response_code(rep(2, 4), c(0, 1, 0, 1), c(2, 2, 4, 4)), c(-1, 1, 1, -1))
  testthat::expect_equal(partisan_response_code(c(1, NA, 2), c(0, 1, NA), c(4, 4, 4)), c(0, NA, NA))
})

testthat::test_that("alternative outcome definitions preserve the baseline and analysis population", {
  source("../../R/recode.R")
  responses <- readRDS("../../data/build/published_long.rds")
  references <- readr::read_csv("../../data/extracted/economic_references_2008.csv", show_col_types = FALSE)
  testthat::expect_identical(names(references), c("caseid", "unemployment_reference", "gas_reference"))
  testthat::expect_equal(nrow(references), 1633)
  testthat::expect_equal(anyDuplicated(references$caseid), 0L)
  testthat::expect_setequal(references$caseid, responses$caseid[responses$pollid == 2008])
  testthat::expect_true(all(references$unemployment_reference %in% c(4.8, 5.1)))
  testthat::expect_equal(range(references$gas_reference), c(3.261, 3.339))
  variants <- correctness_variants(responses, references)
  testthat::expect_equal(variants$published_33, responses$tri_33)
  testthat::expect_equal(variants$published_23, responses$tri_23)
  testthat::expect_equal(variants$relative_10, responses$tri_10)
  testthat::expect_equal(variants$payout, responses$tri_po)
  for (variant in variants) {
    testthat::expect_identical(is.na(variant), is.na(responses$tri_33))
    closed <- responses$seq %in% c(1, 4, 6, 7, 8)
    testthat::expect_equal(variant[closed], responses$tri_33[closed])
  }
  testthat::expect_equal(sum(variants$worksheet_23_symmetric != variants$published_23, na.rm = TRUE), 8)
  gas <- responses$seq == 5
  testthat::expect_equal(sum(variants$one_point_symmetric[gas] != responses$tri_pp[gas], na.rm = TRUE), 268)
  testthat::expect_equal(sum(variants$dated_33[gas] != variants$published_33[gas], na.rm = TRUE), 38)
  unemployment <- responses$seq == 2
  testthat::expect_equal(sum(variants$dated_33[unemployment] != variants$published_33[unemployment], na.rm = TRUE), 6)
  testthat::expect_equal(correctness_variants(responses, references[rev(seq_len(nrow(references))), ]), variants)
  testthat::expect_error(correctness_variants(responses, references[-1, ]))
  testthat::expect_error(correctness_variants(responses, rbind(references, references[1, ])))
})

testthat::test_that("refusal-denominator calculation agrees with the published accuracy contrast", {
  if (!file.exists("../../tabs/correctness_nonresponse.csv")) testthat::skip("Run make correctness first")
  source("../../R/descriptive.R")
  responses <- readRDS("../../data/build/published_long.rds")
  pooled <- responses[which(responses$r_bushref == 0 & !is.na(responses$pay)), ]
  result <- readr::read_csv("../../tabs/correctness_nonresponse.csv", show_col_types = FALSE)
  testthat::expect_equal(result$estimate_pp[1], unname(response_statistics(pooled, "pay")["contrast_1_correct"]) * 100)
  testthat::expect_equal(
    result$standard_error_pp[1],
    unname(cluster_delta_standard_errors(pooled, "pay")["contrast_1_correct"]) * 100
  )
  testthat::expect_equal(diff(result$usable_answers), 79)
})
