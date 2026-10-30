source(file.path("..", "..", "R", "models.R"))

testthat::test_that("normal quadrature and integration preserve probability identities", {
  quadrature <- statmod::gauss.quad.prob(31L, dist = "normal")
  testthat::expect_equal(sum(quadrature$weights), 1)
  testthat::expect_equal(sum(quadrature$weights * quadrature$nodes^2), 1)
  probability <- ordinal_probabilities(matrix(c(-100, 0, 100), ncol = 1L), c(-1, 1))
  testthat::expect_equal(Reduce(`+`, probability), matrix(1, 3, 1))
  probability <- multinomial_probabilities(
    matrix(c(-1000, 0, 1000), ncol = 1L),
    matrix(c(1000, 0, -1000), ncol = 1L)
  )
  testthat::expect_equal(Reduce(`+`, probability), matrix(1, 3, 1))
})

testthat::test_that("cluster integration differs from integrating individual responses", {
  probability <- matrix(c(0.1, 0.2, 0.8, 0.9), nrow = 2L)
  actual <- cluster_log_likelihood(log(probability), c(1, 1), c(0.5, 0.5))
  testthat::expect_equal(actual, log(0.5 * 0.1 * 0.2 + 0.5 * 0.8 * 0.9))
  testthat::expect_false(isTRUE(all.equal(actual, sum(log(rowMeans(probability))))))
})

testthat::test_that("published ordinal estimator gives normalized marginal predictions", {
  set.seed(418)
  sample <- data.frame(caseid = rep(seq_len(80), each = 3), treatment = rep(rep(0:1, 40), each = 3))
  latent <- 0.7 * sample$treatment + rep(rnorm(80, sd = 0.6), each = 3) + rlogis(240)
  sample$outcome <- as.numeric(cut(latent, c(-Inf, -0.6, 0.8, Inf))) - 2
  fit <- fit_published_model(sample, "outcome", "treatment", quadrature_points = 21L)
  testthat::expect_identical(fit$convergence, 0L)
  testthat::expect_true(fit$positive_hessian)
  testthat::expect_lt(fit$max_gradient, 0.02)
  probability <- predict_published_model(fit, sample)
  testthat::expect_equal(rowSums(probability), rep(1, nrow(sample)))
  testthat::expect_true(all(probability >= 0 & probability <= 1))
})

testthat::test_that("quadrature agrees with adaptive integration of a respondent likelihood", {
  quadrature <- statmod::gauss.quad.prob(61L, dist = "normal")
  predictor <- outer(c(-0.2, 0.4), 0.7 * quadrature$nodes, "+")
  probability <- ordinal_probabilities(predictor, c(-0.8, 0.9))
  numerical <- cluster_log_likelihood(log(rbind(
    probability[[1L]][1L, ],
    probability[[3L]][2L, ]
  )), c(1, 1), quadrature$weights)
  reference <- integrate(function(random_effect) {
    plogis(-0.8 - (-0.2 + random_effect)) *
      (1 - plogis(0.9 - (0.4 + random_effect))) * dnorm(random_effect, sd = 0.7)
  }, -Inf, Inf, rel.tol = 1e-10)$value
  testthat::expect_equal(exp(numerical), reference, tolerance = 1e-9)
})

testthat::test_that("Hausman comparison places the consistent subset estimator first", {
  subset_parameters <- c(treatment = 0.5)
  full_parameters <- c(treatment = 0)
  subset_covariance <- matrix(2)
  full_covariance <- matrix(1)
  corrected <- hausman_statistic(
    subset_parameters, subset_covariance,
    full_parameters, full_covariance
  )
  literal <- hausman_statistic(
    full_parameters, full_covariance,
    subset_parameters, subset_covariance
  )
  testthat::expect_equal(corrected, 0.25)
  testthat::expect_equal(literal, -0.25)
})

testthat::test_that("figure predictions retain only the estimation sample", {
  sample <- data.frame(
    treatment = c(0, 0, 1), outcome = c(-1, NA, 1),
    congenial = c(0, NA, 1), correct = c(0, NA, 0), uncongenial = c(1, NA, 0)
  )
  fit <- list(
    parameters = c(
      treatment = 0.2, threshold_lower = -0.5,
      log_threshold_gap = log(1.1), log_random_sd = log(0.3)
    ),
    predictors = "treatment", family = "ordinal", rows = c(1L, 3L), observations = 2L
  )
  predicted <- predict_estimation_sample(fit, sample)
  testthat::expect_equal(nrow(predicted), 2L)
  testthat::expect_equal(predicted$outcome, c(-1, 1))
  testthat::expect_false(anyNA(predicted$outcome))
  testthat::expect_true(all(predicted$congenial > 0 & predicted$congenial < 1))
  testthat::expect_equal(unname(rowSums(predicted[, c("uncongenial", "correct", "congenial")])), c(1, 1))
})
