# Integrate respondent likelihoods before taking logarithms.
cluster_log_likelihood <- function(log_probability, respondent_id, weights) {
  cluster_logs <- rowsum(log_probability, respondent_id, reorder = FALSE)
  maxima <- apply(cluster_logs, 1L, max)
  sum(maxima + log(drop(exp(cluster_logs - maxima) %*% weights)))
}

ordinal_probabilities <- function(linear_predictor, thresholds) {
  lower <- plogis(thresholds[1L] - linear_predictor)
  upper <- plogis(thresholds[2L] - linear_predictor)
  list(lower, upper - lower, 1 - upper)
}

multinomial_probabilities <- function(first, second) {
  maxima <- pmax(0, first, second)
  baseline <- exp(-maxima)
  first <- exp(first - maxima)
  second <- exp(second - maxima)
  denominator <- baseline + first + second
  list(baseline / denominator, first / denominator, second / denominator)
}

fit_published_model <- function(survey, outcome, predictors, family = "ordinal",
                                quadrature_points = 31L, start = NULL) {
  stopifnot(family %in% c("ordinal", "multinomial"))
  columns <- c(outcome, predictors, "caseid")
  selected <- which(complete.cases(survey[, columns]))
  sample <- as.data.frame(survey[selected, columns])
  sample[] <- lapply(sample, as.numeric)
  response <- match(sample[[outcome]], c(-1, 0, 1))
  stopifnot(!anyNA(response), length(unique(response)) == 3L)
  design <- as.matrix(sample[, predictors, drop = FALSE])
  if (family == "multinomial") design <- cbind(intercept = 1, design)
  coefficient_count <- ncol(design)
  quadrature <- statmod::gauss.quad.prob(quadrature_points, dist = "normal")
  observation_count <- nrow(design)
  choose_probability <- function(probabilities) {
    probability <- matrix(0, observation_count, quadrature_points)
    for (category in seq_len(3L)) {
      keep <- response == category
      probability[keep, ] <- probabilities[[category]][keep, , drop = FALSE]
    }
    probability
  }
  objective <- function(parameters) {
    variance <- exp(2 * tail(parameters, 1L))
    if (!is.finite(variance) || variance <= 0) {
      return(1e100)
    }
    random_effect <- sqrt(variance) * quadrature$nodes
    if (family == "ordinal") {
      thresholds <- c(
        parameters[coefficient_count + 1L],
        parameters[coefficient_count + 1L] +
          exp(parameters[coefficient_count + 2L])
      )
      predictor <- drop(design %*% parameters[seq_len(coefficient_count)])
      probabilities <- ordinal_probabilities(outer(predictor, random_effect, "+"), thresholds)
    } else {
      first <- drop(design %*% parameters[seq_len(coefficient_count)])
      second <- drop(design %*% parameters[coefficient_count + seq_len(coefficient_count)])
      probabilities <- multinomial_probabilities(
        outer(first, random_effect, "+"),
        outer(second, random_effect, "+")
      )
    }
    probability <- choose_probability(probabilities)
    if (any(!is.finite(probability))) {
      return(1e100)
    }
    log_likelihood <- cluster_log_likelihood(
      log(pmax(probability, 1e-300)),
      sample$caseid, quadrature$weights
    )
    -log_likelihood - dgamma(variance, shape = 2, scale = 10000, log = TRUE)
  }
  if (is.null(start)) {
    if (family == "ordinal") {
      initial_sample <- sample
      initial_sample$response <- ordered(response)
      initial <- MASS::polr(reformulate(predictors, "response"), data = initial_sample)
      start <- c(coef(initial), initial$zeta[1L], log(diff(initial$zeta)), log(0.5))
    } else {
      start <- c(rep(0, 2 * coefficient_count), log(0.5))
    }
  }
  fit <- optim(start, objective,
    method = "BFGS", hessian = TRUE,
    control = list(maxit = 1500L, reltol = 1e-12, ndeps = rep(1e-5, length(start)))
  )
  covariance <- tryCatch(solve(fit$hessian), error = function(error) {
    matrix(NA_real_, length(fit$par), length(fit$par))
  })
  gradient <- numDeriv::grad(objective, fit$par)
  coefficient_names <- if (family == "ordinal") {
    c(predictors, "threshold_lower", "log_threshold_gap", "log_random_sd")
  } else {
    c(
      paste0("correct_", colnames(design)), paste0("uncongenial_", colnames(design)),
      "log_random_sd"
    )
  }
  names(fit$par) <- coefficient_names
  list(
    parameters = fit$par, covariance = covariance, objective = fit$value,
    convergence = fit$convergence, max_gradient = max(abs(gradient)),
    scaled_gradient = sqrt(drop(crossprod(gradient, covariance %*% gradient))),
    positive_hessian = all(eigen(fit$hessian, symmetric = TRUE, only.values = TRUE)$values > 0),
    quadrature_points = quadrature_points, family = family, outcome = outcome,
    predictors = predictors, rows = selected, observations = nrow(sample),
    respondents = length(unique(sample$caseid))
  )
}

summarize_published_model <- function(fit, model_name) {
  standard_error <- sqrt(pmax(diag(fit$covariance), 0))
  data.frame(
    model = model_name, term = names(fit$parameters),
    estimate = unname(fit$parameters), standard_error = standard_error,
    observations = fit$observations, respondents = fit$respondents,
    convergence = fit$convergence, max_gradient = fit$max_gradient,
    positive_hessian = fit$positive_hessian,
    quadrature_points = fit$quadrature_points
  )
}

predict_published_model <- function(fit, survey, quadrature_points = 61L) {
  design <- as.matrix(as.data.frame(lapply(survey[, fit$predictors, drop = FALSE], as.numeric)))
  if (fit$family == "multinomial") design <- cbind(intercept = 1, design)
  coefficient_count <- ncol(design)
  quadrature <- statmod::gauss.quad.prob(quadrature_points, dist = "normal")
  random_effect <- exp(tail(fit$parameters, 1L)) * quadrature$nodes
  if (fit$family == "ordinal") {
    thresholds <- c(
      fit$parameters[coefficient_count + 1L],
      fit$parameters[coefficient_count + 1L] +
        exp(fit$parameters[coefficient_count + 2L])
    )
    predictor <- drop(design %*% fit$parameters[seq_len(coefficient_count)])
    probability <- ordinal_probabilities(outer(predictor, random_effect, "+"), thresholds)
  } else {
    first <- drop(design %*% fit$parameters[seq_len(coefficient_count)])
    second <- drop(design %*% fit$parameters[coefficient_count + seq_len(coefficient_count)])
    probability <- multinomial_probabilities(
      outer(first, random_effect, "+"),
      outer(second, random_effect, "+")
    )
  }
  result <- vapply(
    probability, function(probability) drop(probability %*% quadrature$weights),
    numeric(nrow(survey))
  )
  colnames(result) <- if (fit$family == "ordinal") {
    c("uncongenial", "correct", "congenial")
  } else {
    c("congenial", "correct", "uncongenial")
  }
  result
}

summarize_model_fit <- function(fit, model_name) {
  variance <- exp(2 * tail(fit$parameters, 1L))
  variance_se <- 2 * variance * sqrt(tail(diag(fit$covariance), 1L))
  data.frame(
    model = model_name, random_variance = unname(variance),
    random_variance_se = unname(variance_se),
    log_likelihood = -fit$objective - dgamma(variance, shape = 2, scale = 10000, log = TRUE),
    penalized_log_likelihood = -fit$objective,
    observations = fit$observations, respondents = fit$respondents
  )
}

compare_model_benchmarks <- function(estimates) {
  benchmark <- data.frame(
    model = c(
      "table_2_1", "table_2_2a", "table_2_2a", "table_2_2b", "table_2_3a", "table_2_3a", "table_2_3b",
      "table_3_1", "table_3_1", "table_3_1", "table_3_1", "table_3_1", "table_3_2", "table_3_2", "table_3_2",
      rep("table_4", 6)
    ),
    term = c(
      "pay", "mon", "app", "acc", "mon", "app", "acc", "mon", "app", "r_bushref", "monxbush", "appxbush",
      "acc", "r_bushref", "accxbush", "correct_acc", "correct_pk", "correct_accxpk",
      "uncongenial_acc", "uncongenial_pk", "uncongenial_accxpk"
    ),
    published_estimate = c(
      -.13, -.14, -.15, -.15, -.21, -.17, -.19, -.14, -.15, .12, .06, .09, -.15, .12, .08,
      -.20, .10, .04, -.21, -.05, .05
    ),
    published_se = c(
      .06, .09, .08, .07, .10, .10, .08, .08, .08, .09, .12, .12, .07, .09, .10,
      .17, .02, .02, .16, .02, .02
    )
  )
  comparison <- merge(benchmark, estimates[, c("model", "term", "estimate", "standard_error")],
    by = c("model", "term"), all.x = TRUE
  )
  comparison$estimate_matches <- abs(comparison$estimate - comparison$published_estimate) < .005
  comparison$se_matches <- abs(comparison$standard_error - comparison$published_se) < .005
  comparison
}

wald_model_contrast <- function(fit, contrasts) {
  contrast_matrix <- matrix(0, length(contrasts), length(fit$parameters))
  for (row in seq_along(contrasts)) {
    contrast <- contrasts[[row]]
    indices <- match(names(contrast), names(fit$parameters))
    stopifnot(!anyNA(indices))
    contrast_matrix[row, indices] <- contrast
  }
  differences <- drop(contrast_matrix %*% fit$parameters)
  covariance <- contrast_matrix %*% fit$covariance %*% t(contrast_matrix)
  statistic <- drop(crossprod(differences, solve(covariance, differences)))
  data.frame(
    statistic = statistic, degrees_freedom = nrow(contrast_matrix),
    p_value = pchisq(statistic, nrow(contrast_matrix), lower.tail = FALSE)
  )
}

write_model_wald_tests <- function() {
  model_files <- list.files("data/build/models", pattern = "[.]rds$", full.names = TRUE)
  wald_results <- list()
  for (model_file in model_files) {
    fit <- readRDS(model_file)
    model_name <- sub("[.]rds$", "", basename(model_file))
    if (all(c("mon", "app") %in% names(fit$parameters))) {
      contrasts <- list(c(mon = 1, app = -1))
      if (model_name == "table_3_1") contrasts[[2L]] <- c(monxbush = 1, appxbush = -1)
      wald_results[[model_name]] <- cbind(model = model_name, wald_model_contrast(fit, contrasts))
    }
  }
  readr::write_csv(do.call(rbind, wald_results), "tabs/model_wald_tests.csv")
}

run_model_contrasts <- function(survey) {
  write_model_wald_tests()
  neutral <- survey[which(survey$r_bushref == 0 & !is.na(survey$nohispeed)), ]
  specifications <- list(
    internet_pooled = list(
      sample = neutral,
      reduced = c("pay", paste0("seq", 1:9)),
      full = c("pay", "nohispeed", "payxnohs", paste0("seq", 1:9)),
      family = "ordinal", outcome = "cong_33"
    ),
    internet_study_two = list(
      sample = neutral,
      reduced = c("mon", "app", paste0("seq", 1:4)),
      full = c("mon", "app", "nohispeed", "monxnohs", "appxnohs", paste0("seq", 1:4)),
      family = "ordinal", outcome = "cong_33r"
    ),
    separate_incentives = list(
      sample = survey,
      reduced = c("acc", "pk", "accxpk", paste0("seq", 1:4)),
      full = c("mon", "app", "pk", "monxpk", "appxpk", paste0("seq", 1:4)),
      family = "multinomial", outcome = "cong_33r"
    )
  )
  specifications$internet_study_two$outcome <- "cong_33"
  likelihood_ratios <- list()
  for (test_name in names(specifications)) {
    specification <- specifications[[test_name]]
    message("Estimating contrast ", test_name)
    fits <- lapply(c("reduced", "full"), function(kind) {
      fit <- fit_published_model(specification$sample, specification$outcome,
        specification[[kind]],
        family = specification$family,
        quadrature_points = 61L
      )
      validate_model_fit(fit)
      saveRDS(fit, file.path("data/build/models", paste0(test_name, "_", kind, ".rds")))
      fit
    })
    reduced <- fits[[1L]]
    full <- fits[[2L]]
    stopifnot(identical(reduced$rows, full$rows))
    degrees_freedom <- length(full$parameters) - length(reduced$parameters)
    statistic <- 2 * (reduced$objective - full$objective)
    likelihood_ratios[[test_name]] <- data.frame(
      contrast = test_name, statistic = statistic, degrees_freedom = degrees_freedom,
      p_value = pchisq(statistic, degrees_freedom, lower.tail = FALSE),
      reduced_convergence = reduced$convergence, full_convergence = full$convergence,
      reduced_gradient = reduced$max_gradient, full_gradient = full$max_gradient
    )
    readr::write_csv(do.call(rbind, likelihood_ratios), "tabs/model_likelihood_ratio_tests.csv")
  }
}

fit_binary_subset <- function(survey, omitted, quadrature_points = 61L) {
  predictors <- c("acc", "pk", "accxpk", paste0("seq", 1:4))
  columns <- c("cong_33r", "caseid", predictors)
  sample <- as.data.frame(lapply(survey[, columns], as.numeric))
  sample <- sample[complete.cases(sample) & sample$cong_33r != omitted, ]
  categories <- sort(unique(sample$cong_33r))
  response <- as.numeric(sample$cong_33r == categories[2L])
  design <- cbind(intercept = 1, as.matrix(sample[, predictors]))
  quadrature <- statmod::gauss.quad.prob(quadrature_points, dist = "normal")
  objective <- function(parameters) {
    variance <- exp(2 * tail(parameters, 1L))
    if (!is.finite(variance)) {
      return(1e100)
    }
    predictor <- outer(drop(design %*% head(parameters, -1L)), sqrt(variance) * quadrature$nodes, "+")
    log_probability <- -log1p(exp(-abs(predictor))) - pmax(-predictor, 0)
    log_probability[response == 0, ] <- log_probability[response == 0, ] - predictor[response == 0, ]
    -cluster_log_likelihood(log_probability, sample$caseid, quadrature$weights) -
      dgamma(variance, shape = 2, scale = 10000, log = TRUE)
  }
  initial <- glm.fit(design, response, family = binomial())$coefficients
  fit <- optim(c(initial, log(.3)), objective,
    method = "BFGS", hessian = TRUE,
    control = list(maxit = 1500, reltol = 1e-12, ndeps = rep(1e-5, length(initial) + 1L))
  )
  covariance <- solve(fit$hessian)
  category_name <- c("congenial", "correct", "uncongenial")[categories[2L] + 2L]
  names(fit$par) <- c(paste0(category_name, "_", colnames(design)), "log_random_sd")
  list(
    parameters = fit$par, covariance = covariance, convergence = fit$convergence,
    max_gradient = max(abs(numDeriv::grad(objective, fit$par))),
    reference_category = categories[1L], omitted_category = omitted
  )
}

run_iia_diagnostics <- function(survey) {
  full <- readRDS("data/build/models/table_4.rds")
  diagnostics <- list()
  for (omitted in c(-1, 0, 1)) {
    reduced <- fit_binary_subset(survey, omitted)
    indices <- match(names(reduced$parameters), names(full$parameters))
    # GLLAMM reports a random-effect standard deviation, rather than its logarithm.
    full_parameters <- full$parameters[indices]
    reduced_parameters <- reduced$parameters
    full_jacobian <- diag(length(indices))
    reduced_jacobian <- diag(length(indices))
    last <- length(indices)
    full_jacobian[last, last] <- exp(full_parameters[last])
    reduced_jacobian[last, last] <- exp(reduced_parameters[last])
    full_parameters[last] <- exp(full_parameters[last])
    reduced_parameters[last] <- exp(reduced_parameters[last])
    full_covariance <- full_jacobian %*% full$covariance[indices, indices] %*% full_jacobian
    reduced_covariance <- reduced_jacobian %*% reduced$covariance %*% reduced_jacobian
    covariance_difference <- full_covariance - reduced_covariance
    statistic <- hausman_statistic(
      full_parameters, full_covariance,
      reduced_parameters, reduced_covariance
    )
    corrected_statistic <- hausman_statistic(
      reduced_parameters, reduced_covariance,
      full_parameters, full_covariance
    )
    diagnostics[[as.character(omitted)]] <- data.frame(
      omitted_category = omitted, reference_category = reduced$reference_category,
      statistic = statistic, corrected_order_statistic = corrected_statistic,
      degrees_freedom = length(indices),
      p_value = if (statistic >= 0) pchisq(statistic, length(indices), lower.tail = FALSE) else NA_real_,
      positive_covariance_difference = all(eigen(covariance_difference, symmetric = TRUE)$values > 0),
      corrected_positive_covariance_difference = all(eigen(-covariance_difference, symmetric = TRUE)$values > 0),
      valid_chisquare_inference = all(eigen(-covariance_difference, symmetric = TRUE)$values > 0) &&
        reduced$reference_category == -1,
      convergence = reduced$convergence, max_gradient = reduced$max_gradient,
      comparison = "full_minus_subset_matching_equations"
    )
    saveRDS(reduced, file.path("data/build/models", paste0("iia_omit_", omitted, ".rds")))
    readr::write_csv(do.call(rbind, diagnostics), "tabs/model_iia_diagnostics.csv")
  }
}


hausman_statistic <- function(consistent_parameters, consistent_covariance,
                              efficient_parameters, efficient_covariance) {
  difference <- consistent_parameters - efficient_parameters
  covariance_difference <- consistent_covariance - efficient_covariance
  drop(crossprod(difference, solve(covariance_difference, difference)))
}

compare_appendix_benchmarks <- function() {
  estimates <- readr::read_csv(show_col_types = FALSE, "tabs/model_estimates.csv")
  statistics <- readr::read_csv(show_col_types = FALSE, "tabs/model_fit_statistics.csv")
  items <- readr::read_csv(show_col_types = FALSE, "tabs/table_b3.csv")
  comparisons <- new.env(parent = emptyenv())
  comparisons$rows <- list()
  add_comparison <- function(model, term, actual, published, digits = 2L) {
    comparisons$rows[[length(comparisons$rows) + 1L]] <- data.frame(
      model = model, term = term, actual = actual, published = published,
      tolerance = 0.5 * 10^-digits, matches = abs(actual - published) < 0.5 * 10^-digits
    )
  }
  coefficient_benchmarks <- data.frame(
    model = c(
      rep(paste0("table_b1_", c(60, 45, 40, 35)), each = 2),
      paste0("table_b2_pooled_", c("po", "10", "23")),
      rep(paste0("table_b2_study_two_", c("po", "10", "23")), each = 2),
      rep(paste0("table_b2_consistent_", c("po", "10", "23")), each = 2)
    ),
    term = c(rep(c("mon", "app"), 4), rep("pay", 3), rep(c("mon", "app"), 6)),
    estimate = c(
      -.15, -.14, -.14, -.13, -.18, -.15, -.18, -.12,
      -.10, -.10, -.14, -.08, -.13, -.06, -.17, -.13, -.16,
      -.13, -.14, -.12, -.19, -.19, -.16
    ),
    standard_error = c(
      .09, .08, .09, .09, .10, .09, .10, .09,
      .06, .06, .06, .09, .08, .08, .08, .09, .08,
      .10, .10, .10, .09, .10, .09
    )
  )
  for (row in seq_len(nrow(coefficient_benchmarks))) {
    benchmark <- coefficient_benchmarks[row, ]
    actual <- estimates[estimates$model == benchmark$model & estimates$term == benchmark$term, ]
    stopifnot(nrow(actual) == 1L)
    add_comparison(benchmark$model, benchmark$term, actual$estimate, benchmark$estimate)
    add_comparison(
      benchmark$model, paste0(benchmark$term, "_se"),
      actual$standard_error, benchmark$standard_error
    )
  }
  statistics_benchmarks <- data.frame(
    model = c(
      paste0("table_b1_", c(60, 45, 40, 35)),
      paste0("table_b2_pooled_", c("po", "10", "23")),
      paste0("table_b2_study_two_", c("po", "10", "23")),
      paste0("table_b2_consistent_", c("po", "10", "23"))
    ),
    random_variance = c(.06, .06, .09, .09, .09, .08, .08, .06, .03, .06, .11, .05, .09),
    random_variance_se = c(.04, .04, .05, .05, .04, .04, .04, .04, .03, .04, .05, .04, .05),
    observations = c(3085, 2863, 2662, 2395, rep(4324, 3), rep(3276, 3), rep(2614, 3)),
    respondents = c(658, 655, 649, 636, rep(878, 3), rep(660, 3), rep(525, 3)),
    log_likelihood = c(
      -3371, -3130, -2908, -2616, -4667, -4671, -4653,
      -3575, -3537, -3552, -2804, -2770, -2787
    )
  )
  for (row in seq_len(nrow(statistics_benchmarks))) {
    benchmark <- statistics_benchmarks[row, ]
    actual <- statistics[statistics$model == benchmark$model, ]
    stopifnot(nrow(actual) == 1L)
    for (term in names(benchmark)[-1L]) {
      digits <- if (term %in% c("random_variance", "random_variance_se")) 2L else 0L
      add_comparison(benchmark$model, term, actual[[term]], benchmark[[term]], digits)
    }
  }
  item_benchmarks <- data.frame(
    item = c(
      paste(c("Unemployment", "Estate Tax", "Debt", "Uninsured", "Poverty"), "2004"),
      rep(paste(c("Unemployment", "Estate Tax", "Debt", "Uninsured", "Gas Price"), "2008"), each = 2)
    ),
    term = c(rep("pay", 5), rep(c("mon", "app"), 5)),
    estimate = c(-.22, .11, -.37, -.08, -.01, -.11, -.15, .16, .02, -.17, -.45, -.21, -.13, -.34, .004),
    standard_error = c(.17, .17, .18, .17, .17, .18, .17, .18, .18, .19, .18, .18, .17, .18, .17),
    observations = c(460, 462, 433, 451, 461, rep(c(656, 657, 654, 654, 655), each = 2))
  )
  for (row in seq_len(nrow(item_benchmarks))) {
    benchmark <- item_benchmarks[row, ]
    actual <- items[items$item == benchmark$item & items$term == benchmark$term, ]
    stopifnot(nrow(actual) == 1L)
    digits <- if (benchmark$item == "Gas Price 2008" && benchmark$term == "app") 3L else 2L
    add_comparison(benchmark$item, benchmark$term, actual$estimate, benchmark$estimate, digits)
    add_comparison(benchmark$item, paste0(benchmark$term, "_se"), actual$standard_error, benchmark$standard_error)
    add_comparison(benchmark$item, "observations", actual$observations, benchmark$observations, 0L)
  }
  result <- do.call(rbind, comparisons$rows)
  readr::write_csv(result, "tabs/appendix_model_benchmarks.csv")
  result
}


predict_estimation_sample <- function(fit, survey) {
  sample <- survey[fit$rows, , drop = FALSE]
  stopifnot(nrow(sample) == fit$observations)
  probabilities <- predict_published_model(fit, sample)
  sample[, colnames(probabilities)] <- probabilities
  sample
}

compare_model_statistics <- function() {
  comparisons <- new.env(parent = emptyenv())
  comparisons$rows <- list()
  add <- function(model, term, actual, published, digits = 2L) {
    comparisons$rows[[length(comparisons$rows) + 1L]] <- data.frame(
      model = model, term = term, actual = actual, published = published,
      tolerance = 0.5 * 10^-digits, matches = abs(actual - published) < 0.5 * 10^-digits
    )
  }
  wald <- readr::read_csv(show_col_types = FALSE, "tabs/model_wald_tests.csv")
  wald_benchmarks <- data.frame(
    model = c(
      "table_2_2a", "table_2_3a", "table_3_1", paste0("table_b1_", c(60, 45, 40, 35)),
      paste0("table_b2_study_two_", c("po", "10", "23")),
      paste0("table_b2_consistent_", c("po", "10", "23"))
    ),
    statistic = c(.02, .19, .08, .00, .02, .09, .26, .31, 1.81, .10, .01, .61, .11),
    p_value = c(.89, .66, .96, .96, .89, .76, .61, .58, .18, .75, .93, .44, .74)
  )
  for (row in seq_len(nrow(wald_benchmarks))) {
    benchmark <- wald_benchmarks[row, ]
    actual <- wald[wald$model == benchmark$model, ]
    stopifnot(nrow(actual) == 1L)
    for (term in c("statistic", "p_value")) add(benchmark$model, term, actual[[term]], benchmark[[term]])
  }
  item_statistics <- readr::read_csv(show_col_types = FALSE, "tabs/table_b3_fit_statistics.csv")
  item_wald <- readr::read_csv(show_col_types = FALSE, "tabs/table_b3_wald_tests.csv")
  item_benchmarks <- data.frame(
    item = c(
      paste(c("Unemployment", "Estate Tax", "Debt", "Uninsured", "Poverty"), "2004"),
      paste(c("Unemployment", "Estate Tax", "Debt", "Uninsured", "Gas Price"), "2008")
    ),
    log_likelihood = c(-488, -492, -467, -484, -491, -705, -688, -654, -714, -715),
    likelihood_ratio = c(1.55, .39, 4.25, .20, .00, .81, .90, 6.45, 1.40, 4.90),
    p_value = c(.21, .53, .04, .66, .97, .67, .64, .04, .50, .09)
  )
  for (row in seq_len(nrow(item_benchmarks))) {
    benchmark <- item_benchmarks[row, ]
    actual <- item_statistics[item_statistics$item == benchmark$item, ]
    for (term in c("log_likelihood", "likelihood_ratio", "p_value")) {
      add(benchmark$item, term, actual[[term]], benchmark[[term]], if (term == "log_likelihood") 0L else 2L)
    }
  }
  item_wald_benchmarks <- data.frame(
    item = paste(c("Unemployment", "Estate Tax", "Debt", "Uninsured", "Gas Price"), "2008"),
    statistic = c(.05, .61, 2.43, .21, 3.91), p_value = c(.82, .44, .12, .65, .05)
  )
  for (row in seq_len(nrow(item_wald_benchmarks))) {
    benchmark <- item_wald_benchmarks[row, ]
    actual <- item_wald[item_wald$item == benchmark$item, ]
    for (term in c("statistic", "p_value")) add(benchmark$item, term, actual[[term]], benchmark[[term]])
  }
  statistics <- readr::read_csv(show_col_types = FALSE, "tabs/model_fit_statistics.csv")
  statistics_benchmarks <- data.frame(
    model = c(
      "table_2_1", "table_2_2a", "table_2_2b", "table_2_3a", "table_2_3b",
      "table_3_1", "table_3_2", "table_4"
    ),
    random_variance = c(.07, .06, .06, .11, .11, .03, .03, .09),
    random_variance_se = c(.04, .04, .04, .05, .05, .02, .02, .04),
    observations = c(4324, 3276, 3276, 2614, 2614, 6233, 6233, 6233),
    respondents = c(878, 660, 660, 525, 525, 1260, 1260, 1260),
    log_likelihood = c(-4685, -3579, -3579, -2815, -2815, -6766, -6766, -6510)
  )
  for (row in seq_len(nrow(statistics_benchmarks))) {
    benchmark <- statistics_benchmarks[row, ]
    actual <- statistics[statistics$model == benchmark$model, ]
    for (term in names(benchmark)[-1L]) {
      add(
        benchmark$model, term, actual[[term]], benchmark[[term]],
        if (term %in% c("random_variance", "random_variance_se")) 2L else 0L
      )
    }
  }
  result <- do.call(rbind, comparisons$rows)
  readr::write_csv(result, "tabs/model_statistics_benchmarks.csv")
  result
}

validate_model_fit <- function(fit) {
  stopifnot(
    fit$convergence == 0L, isTRUE(fit$positive_hessian),
    all(is.finite(fit$parameters)), all(is.finite(fit$covariance))
  )
  score_small <- fit$max_gradient < 0.002
  if (!is.null(fit$scaled_gradient)) score_small <- score_small || fit$scaled_gradient < 0.01
  stopifnot(score_small)
  invisible(TRUE)
}

validate_model_outputs <- function() {
  quadrature <- readr::read_csv(show_col_types = FALSE, "tabs/model_quadrature.csv")
  stopifnot(
    nrow(quadrature) == 21L, !anyDuplicated(quadrature$model),
    all(quadrature$max_parameter_difference < 1e-4),
    all(abs(quadrature$objective_difference) < 1e-4)
  )
  for (model_name in c(
    quadrature$model,
    "internet_pooled_reduced", "internet_pooled_full",
    "internet_study_two_reduced", "internet_study_two_full",
    "separate_incentives_reduced", "separate_incentives_full"
  )) {
    validate_model_fit(readRDS(file.path("data/build/models", paste0(model_name, ".rds"))))
  }
  main <- readr::read_csv(show_col_types = FALSE, "tabs/model_benchmarks.csv")
  appendix <- readr::read_csv(show_col_types = FALSE, "tabs/appendix_model_benchmarks.csv")
  statistics <- readr::read_csv(show_col_types = FALSE, "tabs/model_statistics_benchmarks.csv")
  stopifnot(
    nrow(main) == 21L, all(main$estimate_matches), all(main$se_matches),
    nrow(appendix) == 156L, all(appendix$matches),
    nrow(statistics) == 106L, all(statistics$matches)
  )
  for (model_name in c("table_2_1", "table_2_2a", "table_4")) {
    fit <- readRDS(file.path("data/build/models", paste0(model_name, ".rds")))
    predictions <- readr::read_csv(show_col_types = FALSE, file.path("tabs", paste0(model_name, "_predictions.csv")))
    probabilities <- predictions[, c("uncongenial", "correct", "congenial")]
    stopifnot(
      nrow(predictions) == fit$observations,
      all(is.finite(as.matrix(probabilities))), all(probabilities > 0),
      all(probabilities < 1), all(abs(rowSums(probabilities) - 1) < 1e-10)
    )
  }
  invisible(TRUE)
}

knowledge_interaction_test <- function(fit) {
  indices <- match(c("correct_accxpk", "uncongenial_accxpk"), names(fit$parameters))
  stopifnot(!anyNA(indices))
  parameters <- fit$parameters[indices]
  statistic <- drop(crossprod(parameters, solve(fit$covariance[indices, indices], parameters)))
  data.frame(statistic = statistic, degrees_freedom = 2, p_value = pchisq(statistic, 2, lower.tail = FALSE))
}

knowledge_bias_contrasts <- function(fit, item_rows, low = 4.5, high = 9.5) {
  stopifnot(fit$family == "multinomial", nrow(item_rows) == 5L, low < high)
  quantities <- function(parameters) {
    candidate <- fit
    candidate$parameters <- parameters
    bias <- function(knowledge, incentive) {
      sample <- item_rows
      sample$pk <- knowledge
      sample$acc <- incentive
      sample$accxpk <- knowledge * incentive
      probability <- predict_published_model(candidate, sample)
      mean(probability[, "congenial"] - probability[, "uncongenial"]) * 100
    }
    control_low <- bias(low, 0)
    incentive_low <- bias(low, 1)
    control_high <- bias(high, 0)
    incentive_high <- bias(high, 1)
    c(
      control_low = control_low, incentive_low = incentive_low,
      control_high = control_high, incentive_high = incentive_high,
      treatment_low = incentive_low - control_low,
      treatment_high = incentive_high - control_high,
      moderation = (incentive_high - control_high) - (incentive_low - control_low),
      control_gradient = control_high - control_low,
      incentive_gradient = incentive_high - incentive_low
    )
  }
  estimate <- quantities(fit$parameters)
  gradient <- numDeriv::jacobian(quantities, fit$parameters)
  covariance <- gradient %*% fit$covariance %*% t(gradient)
  stopifnot(all(diag(covariance) >= 0))
  standard_error <- sqrt(diag(covariance))
  data.frame(
    contrast = names(estimate), knowledge_low = low, knowledge_high = high,
    estimate_pp = unname(estimate), standard_error_pp = standard_error,
    lower_95_pp = unname(estimate) - qnorm(.975) * standard_error,
    upper_95_pp = unname(estimate) + qnorm(.975) * standard_error,
    observations = fit$observations, respondents = fit$respondents
  )
}
