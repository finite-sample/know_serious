jags_root <- normalizePath(testthat::test_path("..", ".."))
source(file.path(jags_root, "R", "jags.R"))
source(file.path(jags_root, "R", "recode.R"))
jags_responses <- recode_published(haven::read_dta(file.path(
  jags_root, "data/raw/final_bundle/psk_wide.dta"
)))$long

testthat::test_that("JAGS samples and category order match published input assembly", {
  pooled <- assemble_jags_inputs(jags_responses, "pooled")
  study_2 <- assemble_jags_inputs(jags_responses, "study_2")
  testthat::expect_equal(pooled$data$N, 4324L)
  testthat::expect_equal(study_2$data$N, 3276L)
  testthat::expect_equal(ncol(pooled$data$x), 10L)
  testthat::expect_equal(ncol(study_2$data$x), 6L)
  for (assembled in list(pooled, study_2)) {
    testthat::expect_identical(assembled$data$y, as.integer(assembled$sample$cong_33 + 2))
    testthat::expect_equal(length(unique(assembled$data$id)), assembled$data$NID)
    testthat::expect_equal(range(assembled$data$id), c(1, assembled$data$NID))
    testthat::expect_false(anyNA(assembled$data$x))
    testthat::expect_equal(diag(assembled$data$B0), rep(1e-8, ncol(assembled$data$x)))
    for (condition in assembled$conditions) {
      testthat::expect_equal(sum(assembled$data[[paste0("weight_", condition)]]), 1)
    }
  }
  testthat::expect_equal(colnames(study_2$data$x), c("app", "mon", paste0("seq", 1:4)))
})

testthat::test_that("group summaries preserve original priors and named probabilities", {
  model_path <- file.path(jags_root, "data/raw/final_bundle/study12hologit.jag")
  model <- build_jags_model(model_path, c("control", "monetary"))
  testthat::expect_match(model, "sigma ~ dunif(0,2)", fixed = TRUE)
  testthat::expect_match(model, "tau0[j] ~ dnorm(0,.01)", fixed = TRUE)
  testthat::expect_match(model, "beta[1:10] ~ dmnorm(b0[], B0[,])", fixed = TRUE)
  testthat::expect_match(
    model, "probability_control_uncongenial <- inprod(p[1:N,1], weight_control[1:N])",
    fixed = TRUE
  )
  testthat::expect_match(
    model, "probability_monetary_congenial <- inprod(p[1:N,3], weight_monetary[1:N])",
    fixed = TRUE
  )
})

testthat::test_that("sample alignment follows row order and respondent identity", {
  reversed <- jags_responses[rev(seq_len(nrow(jags_responses))), ]
  assembled <- assemble_jags_inputs(reversed, "pooled")
  testthat::expect_equal(assembled$data$y, assembled$sample$cong_33 + 2)
  ids <- unique(assembled$sample$caseid)
  testthat::expect_equal(ids[assembled$data$id], assembled$sample$caseid)
  testthat::expect_equal(
    assembled$data$weight_monetary > 0, assembled$sample$rd == 2
  )
})

testthat::test_that("probability extraction uses node names regardless of column order", {
  summary <- data.frame(
    parameter = c(
      "probability_control_correct", "probability_control_congenial",
      "probability_control_uncongenial", "beta[1]"
    ),
    mean = c(0.3, 0.45, 0.25, -0.1)
  )
  fit <- list(
    summary = summary, conditions = "control", study = "pooled",
    observations = 10, respondents = 2
  )
  probabilities <- extract_jags_probabilities(fit)
  testthat::expect_equal(probabilities$outcome, c("uncongenial", "correct", "congenial"))
  testthat::expect_equal(probabilities$mean, c(0.25, 0.3, 0.45))
})

testthat::test_that("convergence gates require finite Rhat and sufficient effective samples", {
  testthat::expect_true(check_jags_convergence(data.frame(r_hat = c(1, 1.005), effective_size = c(500, 800))))
  testthat::expect_false(check_jags_convergence(data.frame(r_hat = 1.02, effective_size = 800)))
  testthat::expect_false(check_jags_convergence(data.frame(r_hat = 1.005, effective_size = 399)))
  testthat::expect_false(check_jags_convergence(data.frame(r_hat = NA_real_, effective_size = 800)))
})

testthat::test_that("noncentered random effects retain the Gaussian prior", {
  centered <- build_jags_model(
    file.path(jags_root, "data/raw/final_bundle/study12hologit.jag"), "control",
    noncentered = FALSE
  )
  testthat::expect_match(centered, "eta[k] ~ dnorm(0.0,eta.tau)", fixed = TRUE)
  model <- build_jags_model(file.path(jags_root, "data/raw/final_bundle/study12hologit.jag"), "control")
  testthat::expect_match(model, "z[k] ~ dnorm(0, 1)", fixed = TRUE)
  testthat::expect_match(model, "eta[k] <- sigma * z[k]", fixed = TRUE)
  testthat::expect_false(grepl("eta[k] ~ dnorm", model, fixed = TRUE))
  sigma <- c(0.01, 0.1, 0.5, 1.5)
  eta <- c(-0.02, 0, 0.4, 1.8)
  testthat::expect_equal(
    stats::dnorm(eta, sd = sigma), stats::dnorm(eta / sigma) / sigma
  )
  thresholds <- c(-1, 0.5)
  linear_predictor <- c(-0.4, 0.1, 0.3, 0.5)
  original_probability <- stats::plogis(thresholds[1] - linear_predictor - eta)
  transformed_probability <- stats::plogis(thresholds[1] - linear_predictor - sigma * (eta / sigma))
  testthat::expect_equal(original_probability, transformed_probability)
})

testthat::test_that("continuation concatenates within chain using parameter names", {
  previous <- coda::mcmc(matrix(1:6, ncol = 2, dimnames = list(NULL, c("beta[1]", "beta[10]"))),
    start = 110, thin = 10
  )
  extension <- coda::mcmc(matrix(7:10, ncol = 2, dimnames = list(NULL, c("beta[10]", "beta[1]"))),
    start = 1010, thin = 10
  )
  combined <- concatenate_jags_chain(previous, extension)
  testthat::expect_equal(nrow(combined), 5)
  testthat::expect_equal(as.numeric(combined[, "beta[1]"]), c(1, 2, 3, 9, 10))
  testthat::expect_equal(as.numeric(combined[, "beta[10]"]), c(4, 5, 6, 7, 8))
  testthat::expect_equal(coda::thin(combined), 10)
  testthat::expect_error(concatenate_jags_chain(previous, extension[, 1, drop = FALSE]))
})

testthat::test_that("continuation refuses changed assembled input values", {
  assembled <- list(data = list(y = 1:3), study = "pooled")
  fit <- list(input_digest = digest::digest(list(y = 2:4), algo = "sha256"))
  testthat::expect_error(continue_jags_replication(fit, assembled))
  testthat::expect_error(run_jags_study(assembled, "unused", fit))
})

testthat::test_that("saved draws can be summarized in a fresh R process", {
  set.seed(901)
  draws <- coda::mcmc.list(lapply(1:2, function(chain) {
    coda::mcmc(matrix(rnorm(4000), ncol = 2, dimnames = list(NULL, c("a", "b"))))
  }))
  result <- callr::r(function(root, draws) {
    preloaded <- "coda" %in% loadedNamespaces()
    source(file.path(root, "R/jags.R"))
    list(preloaded = preloaded, summary = summarize_jags_draws(draws))
  }, args = list(root = jags_root, draws = draws), user_profile = FALSE)
  testthat::expect_false(result$preloaded)
  expected <- colMeans(do.call(rbind, lapply(draws, as.matrix)))
  testthat::expect_equal(result$summary$mean, unname(expected))
  testthat::expect_true(all(is.finite(result$summary$r_hat) & is.finite(result$summary$effective_size)))
})
