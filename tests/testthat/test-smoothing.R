source("../../R/smoothing.R")
testthat::test_that("Stata local linear smoother reproduces lines including edges", {
  x <- c(0, .2, 1, 3, 9, 10, 15, 20)
  fit <- smooth_stata_lowess(x, 2 + 3 * x, bandwidth = .8)
  testthat::expect_equal(fit$y, 2 + 3 * x, tolerance = 1e-10)
})

testthat::test_that("Stata truncates the window at each boundary", {
  x <- 1:9
  y <- c(0, 1, 0, 0, 10, 0, 0, 1, 0)
  fit <- smooth_stata_lowess(x, y, bandwidth = .6)
  # The first regression uses observations 1:3, not five nearest neighbors.
  distance <- x[1:3] - x[1]
  weights <- (1 - (distance / (1.0001 * max(distance)))^3)^3
  expected <- stats::coef(stats::lm(y[1:3] ~ distance, weights = weights))[1]
  testthat::expect_equal(fit$y[1], unname(expected), tolerance = 1e-10)
  testthat::expect_gt(abs(fit$y[1] - stats::lowess(x, y, f = .6, iter = 0, delta = 0)$y[1]), .001)
})

testthat::test_that("ties and missing observations are handled explicitly", {
  fit <- smooth_stata_lowess(c(1, 1, 1, NA), c(0, 1, 2, 100), bandwidth = 1)
  testthat::expect_equal(fit$x, rep(1, 3))
  testthat::expect_equal(fit$y, c(.5, 1, 1.5))
  testthat::expect_error(smooth_stata_lowess(NA_real_, NA_real_), "No finite")
})
