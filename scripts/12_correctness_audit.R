source("R/recode.R")
source("R/descriptive.R")
source("R/models.R")
responses <- readRDS("data/build/published_long.rds")
references <- readr::read_csv(
  "data/extracted/economic_references_2008.csv",
  col_types = readr::cols(.default = readr::col_double())
)
variants <- correctness_variants(responses, references)
stopifnot(identical(as.numeric(variants$published_33), as.numeric(responses$tri_33)))
continuous_items <- c(2, 3, 5, 9, 10)
targets <- c(4.8, 15.8, 3.27, 15.6, 12.5)
windows <- economic_answer_windows()
ledger <- do.call(rbind, lapply(names(windows), function(window) {
  bounds <- matrix(windows[[window]], ncol = 2, byrow = TRUE)
  data.frame(
    window = window, item_id = continuous_items,
    item = responses$item[match(continuous_items, responses$seq)], factual_key = targets,
    unit = c("percent", "percent", "dollars_per_gallon", "percent", "percent"),
    lower_inclusive = bounds[, 1], upper_inclusive = bounds[, 2],
    center_offset_from_key = rowMeans(bounds) - targets
  )
}))
readr::write_csv(ledger, "tabs/correctness_windows.csv")
rates <- list()
effects <- list()
for (variant in names(variants)) {
  classification <- variants[[variant]]
  candidate <- responses
  candidate$cong_33 <- partisan_response_code(classification, candidate$dem, candidate$seq)
  rates[[variant]] <- do.call(rbind, lapply(1:10, function(item) {
    keep <- candidate$seq == item
    valid <- keep & !is.na(classification)
    data.frame(
      variant = variant, item = candidate$item[match(item, candidate$seq)],
      valid_responses = sum(valid), correct_responses = sum(classification[valid] == 1),
      correct_percent = 100 * mean(classification[valid] == 1),
      changed_from_main = sum(classification[valid] != variants$published_33[valid])
    )
  }))
  for (study in c("pooled", "study_2004", "study_2008")) {
    keep <- switch(study,
      pooled = candidate$r_bushref == 0 & !is.na(candidate$pay),
      study_2004 = candidate$pollid == 2004,
      study_2008 = candidate$pollid == 2008 & candidate$r_bushref == 0
    )
    sample <- candidate[which(keep), ]
    group <- if (study == "study_2008") "rd" else "pay"
    estimate <- response_statistics(sample, group)
    standard_error <- cluster_delta_standard_errors(sample, group)
    selected <- grepl("^contrast_.*_(bias|correct|congenial)$", names(estimate))
    effects[[paste(variant, study)]] <- data.frame(
      variant = variant, study = study, statistic = names(estimate)[selected],
      estimate_pp = unname(estimate[selected]) * 100,
      standard_error_pp = unname(standard_error[names(estimate)[selected]]) * 100
    )
  }
}
effects <- do.call(rbind, effects)
effects$lower_95_pp <- effects$estimate_pp - qnorm(.975) * effects$standard_error_pp
effects$upper_95_pp <- effects$estimate_pp + qnorm(.975) * effects$standard_error_pp
readr::write_csv(do.call(rbind, rates), "tabs/correctness_item_rates.csv")
readr::write_csv(effects, "tabs/correctness_effects.csv")
baseline <- readRDS("data/build/models/table_4.rds")
sample <- responses[baseline$rows, ]
items <- sample[!duplicated(sample$item), ]
dir.create("data/build/correctness", recursive = TRUE, showWarnings = FALSE)
contrasts <- list()
diagnostics <- list()
for (variant in names(variants)) {
  candidate <- sample
  candidate$cong_33r <- -partisan_response_code(
    variants[[variant]][baseline$rows], candidate$dem, candidate$seq
  )
  stopifnot(!anyNA(candidate$cong_33r))
  if (variant == "published_33") {
    fit <- baseline
    parameter_difference <- 0
  } else {
    message("Estimating correctness definition: ", variant)
    initial <- fit_published_model(
      candidate, baseline$outcome, baseline$predictors, "multinomial",
      start = baseline$parameters
    )
    fit <- fit_published_model(
      candidate, baseline$outcome, baseline$predictors, "multinomial",
      quadrature_points = 61L, start = initial$parameters
    )
    validate_model_fit(fit)
    parameter_difference <- max(abs(fit$parameters - initial$parameters))
    stopifnot(parameter_difference < .005)
    saveRDS(fit, paste0("data/build/correctness/", variant, ".rds"))
  }
  stopifnot(fit$observations == baseline$observations, fit$respondents == baseline$respondents)
  contrasts[[variant]] <- data.frame(variant = variant, knowledge_bias_contrasts(fit, items))
  diagnostics[[variant]] <- data.frame(
    variant = variant, observations = fit$observations, respondents = fit$respondents,
    convergence = fit$convergence, positive_hessian = fit$positive_hessian,
    max_gradient = fit$max_gradient, scaled_gradient = fit$scaled_gradient,
    max_quadrature_parameter_difference = parameter_difference,
    knowledge_interaction_test(fit)
  )
  readr::write_csv(do.call(rbind, contrasts), "tabs/correctness_knowledge_contrasts.csv")
  readr::write_csv(do.call(rbind, diagnostics), "tabs/correctness_model_diagnostics.csv")
}
