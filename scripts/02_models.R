source("R/models.R")
survey <- readRDS("data/build/published_long.rds")
survey <- as.data.frame(lapply(survey, function(column) {
  if (is.numeric(column)) as.numeric(column) else column
}))
item_predictors <- paste0("seq", seq_len(4L))
pooled_predictors <- paste0("seq", seq_len(9L))
neutral <- subset(survey, r_bushref == 0)
study_two <- subset(neutral, pollid == 2008)
consistent <- subset(study_two, consis == 1)
model_specs <- new.env(parent = emptyenv())
add_spec <- function(name, sample, predictors, outcome = "cong_33", family = "ordinal") {
  model_specs[[name]] <- list(
    sample = sample, predictors = predictors,
    outcome = outcome, family = family
  )
}
add_spec("table_2_1", neutral, c("pay", pooled_predictors))
add_spec("table_2_2a", study_two, c("mon", "app", item_predictors))
add_spec("table_2_2b", study_two, c("acc", item_predictors))
add_spec("table_2_3a", consistent, c("mon", "app", item_predictors))
add_spec("table_2_3b", consistent, c("acc", item_predictors))
add_spec("table_3_1", survey, c("mon", "app", "r_bushref", "monxbush", "appxbush", item_predictors))
add_spec("table_3_2", survey, c("acc", "r_bushref", "accxbush", item_predictors))
add_spec("table_4", survey, c("acc", "pk", "accxpk", item_predictors), "cong_33r", "multinomial")
for (seconds in c(60, 45, 40, 35)) {
  add_spec(
    paste0("table_b1_", seconds), subset(study_two, t_l <= seconds),
    c("mon", "app", item_predictors)
  )
}
for (window in c("po", "10", "23")) {
  add_spec(paste0("table_b2_pooled_", window), neutral, c("pay", pooled_predictors), paste0("cong_", window))
  add_spec(paste0("table_b2_study_two_", window), study_two, c("mon", "app", item_predictors), paste0("cong_", window))
  add_spec(
    paste0("table_b2_consistent_", window), consistent,
    c("mon", "app", item_predictors), paste0("cong_", window)
  )
}
dir.create("data/build/models", recursive = TRUE, showWarnings = FALSE)
dir.create("tabs", showWarnings = FALSE)
model_results <- list()
quadrature_results <- list()
for (model_name in names(model_specs)) {
  message("Estimating ", model_name)
  specification <- model_specs[[model_name]]
  fitted <- fit_published_model(
    specification$sample, specification$outcome,
    specification$predictors, specification$family
  )
  refined <- fit_published_model(specification$sample, specification$outcome,
    specification$predictors, specification$family,
    quadrature_points = 61L, start = fitted$parameters
  )
  quadrature_results[[model_name]] <- data.frame(
    model = model_name, max_parameter_difference = max(abs(fitted$parameters - refined$parameters)),
    objective_difference = refined$objective - fitted$objective
  )
  validate_model_fit(refined)
  saveRDS(refined, file.path("data/build/models", paste0(model_name, ".rds")))
  model_results[[model_name]] <- summarize_published_model(refined, model_name)
  readr::write_csv(do.call(rbind, model_results), "tabs/model_estimates.csv")
  readr::write_csv(do.call(rbind, quadrature_results), "tabs/model_quadrature.csv")
  if (model_name %in% c("table_2_1", "table_2_2a", "table_4")) {
    predictions <- predict_estimation_sample(refined, specification$sample)
    readr::write_csv(
      predictions[, c("caseid", "item", "pay", "rd", "acc", "pk", "uncongenial", "correct", "congenial")],
      file.path("tabs", paste0(model_name, "_predictions.csv"))
    )
  }
}
item_results <- list()
item_wald_results <- list()
item_fit_statistics <- list()
for (item_name in unique(survey$item)) {
  sample <- subset(survey, item == item_name & r_bushref == 0)
  predictors <- if (all(sample$pollid == 2004)) "pay" else c("mon", "app")
  sample$response <- ordered(sample$cong_33, levels = c(-1, 0, 1))
  fit <- MASS::polr(reformulate(predictors, "response"), data = sample, Hess = TRUE)
  coefficients <- coef(summary(fit))
  estimation_sample <- model.frame(fit)
  null_fit <- MASS::polr(response ~ 1, data = estimation_sample)
  likelihood_ratio <- 2 * (as.numeric(logLik(fit)) - as.numeric(logLik(null_fit)))
  item_fit_statistics[[item_name]] <- data.frame(
    item = item_name, log_likelihood = as.numeric(logLik(fit)),
    likelihood_ratio = likelihood_ratio, degrees_freedom = length(predictors),
    p_value = pchisq(likelihood_ratio, length(predictors), lower.tail = FALSE)
  )
  if (all(c("mon", "app") %in% names(coef(fit)))) {
    coefficient_names <- names(coef(fit))
    fit_for_contrast <- list(
      parameters = coef(fit),
      covariance = vcov(fit)[coefficient_names, coefficient_names]
    )
    item_wald_results[[item_name]] <- cbind(
      item = item_name,
      wald_model_contrast(fit_for_contrast, list(c(mon = 1, app = -1)))
    )
  }
  item_results[[item_name]] <- data.frame(
    item = item_name, term = rownames(coefficients),
    estimate = coefficients[, 1], standard_error = coefficients[, 2],
    observations = nobs(fit)
  )
}
readr::write_csv(do.call(rbind, item_results), "tabs/table_b3.csv")
readr::write_csv(do.call(rbind, item_wald_results), "tabs/table_b3_wald_tests.csv")
readr::write_csv(do.call(rbind, item_fit_statistics), "tabs/table_b3_fit_statistics.csv")
fit_summaries <- lapply(names(model_specs), function(model_name) {
  summarize_model_fit(readRDS(file.path("data/build/models", paste0(model_name, ".rds"))), model_name)
})
readr::write_csv(do.call(rbind, fit_summaries), "tabs/model_fit_statistics.csv")
readr::write_csv(compare_model_benchmarks(do.call(rbind, model_results)), "tabs/model_benchmarks.csv")
run_model_contrasts(survey)
run_iia_diagnostics(survey)
compare_appendix_benchmarks()
compare_model_statistics()
validate_model_outputs()
