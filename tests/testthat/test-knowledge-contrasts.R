testthat::test_that("bias uncertainty agrees with an analytic multinomial derivative", {
  source("../../R/models.R")
  covariance <- matrix(0, 9, 9)
  covariance[2, 2] <- .04
  fit <- list(
    family = "multinomial", predictors = c("acc", "pk", "accxpk"),
    parameters = c(0, .2, .1, .01, 0, -.1, -.05, .02, -30), covariance = covariance,
    observations = 100, respondents = 20
  )
  items <- data.frame(acc = rep(0, 5), pk = 0, accxpk = 0)
  result <- knowledge_bias_contrasts(fit, items, 4.5, 9.5)
  first <- exp(.2 + .1 * 4.5 + .01 * 4.5)
  second <- exp(-.1 - .05 * 4.5 + .02 * 4.5)
  denominator <- 1 + first + second
  bias <- (1 - second) / denominator
  derivative <- -bias * first / denominator * 100
  row <- result[result$contrast == "incentive_low", ]
  testthat::expect_equal(row$estimate_pp, 100 * bias, tolerance = 1e-10)
  testthat::expect_equal(row$standard_error_pp, abs(derivative) * .2, tolerance = 1e-7)
  treatment <- result[result$contrast == "treatment_low", ]
  testthat::expect_equal(treatment$standard_error_pp, row$standard_error_pp, tolerance = 1e-7)
  testthat::expect_equal(row$upper_95_pp - row$estimate_pp, qnorm(.975) * row$standard_error_pp)
})
