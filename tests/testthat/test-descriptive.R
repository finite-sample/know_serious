source(file.path("..", "..", "R", "descriptive.R"))
testthat::test_that("response statistics use responses as the denominator", {
  responses <- data.frame(
    caseid = c(1, 1, 2, 3, 4), rd = c(0, 0, 0, 1, 1),
    cong_33 = c(1, 1, -1, 0, 1)
  )
  actual <- response_statistics(responses, "rd")
  testthat::expect_equal(unname(actual["group_0_congenial"]), 2 / 3)
  testthat::expect_equal(unname(actual["group_0_bias"]), 1 / 3)
  testthat::expect_equal(unname(actual["contrast_1_bias"]), 1 / 6)
})
testthat::test_that("cluster bootstrap preserves repeatable respondent sampling", {
  responses <- data.frame(
    caseid = rep(1:20, each = 2), rd = rep(rep(0:1, each = 10), each = 2),
    cong_33 = rep(c(-1, 0, 1, 1), 10)
  )
  first <- bootstrap_responses(responses, "rd", replicates = 100)
  testthat::expect_identical(first, bootstrap_responses(responses, "rd", replicates = 100))
  testthat::expect_true(all(is.finite(first$standard_error)))
  testthat::expect_true(all(first$bootstrap_frame_respondents == 20))
})
testthat::test_that("cluster delta variance recovers ordinary mean variance for one row per person", {
  responses <- data.frame(caseid = 1:20, rd = 0, cong_33 = rep(c(-1, 0, 1, 1), 5))
  actual <- cluster_delta_standard_errors(responses, "rd")
  testthat::expect_equal(unname(actual["group_0_bias"]), sd(responses$cong_33) / sqrt(20))
  testthat::expect_equal(unname(actual["group_0_correct"]), sd(responses$cong_33 == 0) / sqrt(20))
})
testthat::test_that("response contrasts equal the published saturated logistic contrasts", {
  responses <- data.frame(
    caseid = seq_len(90), rd = rep(0:1, each = 45),
    cong_33 = c(rep(c(-1, 0, 1), each = 15), rep(c(-1, 0, 1), c(10, 15, 20)))
  )
  statistics <- response_statistics(responses, "rd")
  for (category in -1:1) {
    responses$outcome <- responses$cong_33 == category
    fit <- glm(outcome ~ rd, data = responses, family = binomial())
    prediction <- predict(fit, newdata = data.frame(rd = 0:1), type = "response")
    name <- paste0("contrast_1_", c("uncongenial", "correct", "congenial")[category + 2])
    testthat::expect_equal(unname(statistics[name]), unname(diff(prediction)), tolerance = 1e-9)
  }
})
