source("R/models.R")
source("R/descriptive.R")
source("R/knowledge_scores.R")
survey <- readRDS("data/build/published_long.rds")
wide <- readRDS("data/build/published_wide.rds")
original <- readr::read_csv("data/extracted/survey_2008.csv", col_types = readr::cols(.default = readr::col_double()))
baseline <- readRDS("data/build/models/table_4.rds")
sample <- survey[baseline$rows, ]
respondents <- wide[match(unique(sample$caseid), wide$caseid), ]
scores <- alternative_knowledge_scores(respondents, original)
items <- sample[!duplicated(sample$item), ]
dir.create("data/build/sensitivity", showWarnings = FALSE, recursive = TRUE)
results <- list()
diagnostics <- list()
score_changes <- list()
coefficients <- list()
for (variant in setdiff(names(scores), "caseid")) {
  candidate <- sample
  candidate$pk <- scores[[variant]][match(candidate$caseid, scores$caseid)]
  candidate$accxpk <- candidate$acc * candidate$pk
  stopifnot(all(complete.cases(candidate[c(baseline$outcome, baseline$predictors, "caseid")])))
  if (variant == "published") {
    fit <- baseline
    parameter_difference <- 0
  } else {
    message("Estimating knowledge sensitivity: ", variant)
    initial <- fit_published_model(
      candidate, baseline$outcome, baseline$predictors, "multinomial",
      start = baseline$parameters
    )
    fit <- fit_published_model(
      candidate, baseline$outcome, baseline$predictors, "multinomial",
      quadrature_points = 61L, start = initial$parameters
    )
    parameter_difference <- max(abs(fit$parameters - initial$parameters))
    validate_model_fit(fit)
    stopifnot(parameter_difference < .005)
    saveRDS(fit, paste0("data/build/sensitivity/", variant, ".rds"))
  }
  stopifnot(fit$observations == baseline$observations, fit$respondents == baseline$respondents)
  results[[variant]] <- data.frame(variant = variant, knowledge_bias_contrasts(fit, items))
  coefficients[[variant]] <- summarize_published_model(fit, variant)
  diagnostics[[variant]] <- data.frame(
    variant = variant, convergence = fit$convergence, max_gradient = fit$max_gradient,
    scaled_gradient = fit$scaled_gradient, positive_hessian = fit$positive_hessian,
    max_quadrature_parameter_difference = parameter_difference,
    observations = fit$observations, respondents = fit$respondents
  )
  score_changes[[variant]] <- data.frame(
    variant = variant, respondents = nrow(scores),
    changed_scores = sum(abs(scores[[variant]] - scores$published) > 1e-12),
    mean_score = mean(scores[[variant]]), mean_absolute_change = mean(abs(scores[[variant]] - scores$published))
  )
  readr::write_csv(do.call(rbind, results), "tabs/knowledge_sensitivity.csv")
  readr::write_csv(do.call(rbind, coefficients), "tabs/knowledge_sensitivity_coefficients.csv")
  readr::write_csv(do.call(rbind, diagnostics), "tabs/knowledge_sensitivity_diagnostics.csv")
  readr::write_csv(do.call(rbind, score_changes), "tabs/knowledge_score_changes.csv")
}
interaction_tests <- lapply(setdiff(names(scores), "caseid"), function(variant) {
  fit <- if (variant == "published") baseline else readRDS(paste0("data/build/sensitivity/", variant, ".rds"))
  data.frame(variant = variant, knowledge_interaction_test(fit))
})
readr::write_csv(do.call(rbind, interaction_tests), "tabs/knowledge_sensitivity_interactions.csv")
missing <- wide[wide$pollid == 2008 & is.na(wide$pk), ]
candidate <- survey[survey$caseid %in% missing$caseid, ]
candidate$pk <- 0
candidate$accxpk <- 0
eligible <- complete.cases(candidate[c(baseline$outcome, baseline$predictors, "caseid")])
readr::write_csv(data.frame(
  missing_knowledge_respondents = nrow(missing), missing_party_respondents = sum(is.na(missing$pid7)),
  added_model_rows_if_knowledge_filled = sum(eligible),
  added_model_respondents_if_knowledge_filled = length(unique(candidate$caseid[eligible]))
), "tabs/knowledge_missingness_impact.csv")
pooled <- survey[which(survey$r_bushref == 0 & !is.na(survey$pay)), ]
item_results <- lapply(c("none", unique(pooled$item)), function(omitted) {
  candidate <- if (omitted == "none") pooled else pooled[pooled$item != omitted, ]
  estimate <- response_statistics(candidate, "pay")[["contrast_1_bias"]] * 100
  standard_error <- cluster_delta_standard_errors(candidate, "pay")[["contrast_1_bias"]] * 100
  data.frame(
    omitted_item = omitted, estimate_pp = estimate, standard_error_pp = standard_error,
    lower_95_pp = estimate - qnorm(.975) * standard_error,
    upper_95_pp = estimate + qnorm(.975) * standard_error,
    usable_responses = sum(!is.na(candidate$cong_33)),
    usable_respondents = length(unique(candidate$caseid[!is.na(candidate$cong_33)]))
  )
})
readr::write_csv(do.call(rbind, item_results), "tabs/economic_item_sensitivity.csv")
moderation <- readr::read_csv("tabs/knowledge_sensitivity.csv", show_col_types = FALSE)
moderation <- moderation[moderation$contrast == "moderation", ]
labels <- c(
  published = "Published score", strict_caucus = "Strict Senate: appendix key",
  strict_party = "Strict Senate: party membership", omit_senate = "Omit Senate item",
  expanded_items = "Add six knowledge items"
)
moderation$label <- factor(labels[moderation$variant], levels = rev(unname(labels)))
.data <- rlang::.data
plot <- ggplot2::ggplot(moderation, ggplot2::aes(
  x = .data$estimate_pp, y = .data$label, xmin = .data$lower_95_pp, xmax = .data$upper_95_pp
)) +
  ggplot2::geom_vline(xintercept = 0, color = "grey60", linetype = 2) +
  ggplot2::geom_pointrange(orientation = "y") +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::labs(
    x = "Incentive effect at higher minus lower knowledge (percentage points)", y = NULL,
    caption = "Scores 9.5 versus 4.5 on each 0-13 scale; same 1,260 respondents. Pointwise model-based 95% intervals."
  )
ggplot2::ggsave("figs/knowledge_sensitivity.pdf", plot, width = 9, height = 4)
