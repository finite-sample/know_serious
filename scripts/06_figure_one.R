source("R/jags.R")
figure_points <- do.call(rbind, lapply(c("pooled", "study_2"), function(study) {
  model <- if (study == "pooled") "table_2_1" else "table_2_2a"
  predictions <- readr::read_csv(file.path("tabs", paste0(model, "_predictions.csv")))
  probability_columns <- c("uncongenial", "correct", "congenial")
  probability_values <- as.matrix(predictions[probability_columns])
  stopifnot(all(is.finite(probability_values)))
  stopifnot(all(probability_values > 0 & probability_values < 1))
  stopifnot(max(abs(rowSums(probability_values) - 1)) < 1e-10)
  conditions <- if (study == "pooled") c(0, 2) else 0:2
  do.call(rbind, lapply(conditions, function(arm) {
    selected <- if (study == "pooled") predictions$pay %in% (arm / 2) else predictions$rd %in% arm
    do.call(rbind, lapply(c("uncongenial", "congenial"), function(outcome) {
      data.frame(
        study = study, condition = c("control", "accuracy_appeal", "monetary")[arm + 1],
        outcome = outcome, estimate_pct = mean(predictions[[outcome]][selected], na.rm = TRUE) * 100
      )
    }))
  }))
}))
historical_intervals <- data.frame(
  study = c(rep("pooled", 4), rep("study_2", 6)),
  condition = c(rep(c("control", "monetary"), 2), rep(c("control", "accuracy_appeal", "monetary"), 2)),
  outcome = c(rep(c("uncongenial", "congenial"), each = 2), rep(c("uncongenial", "congenial"), each = 3)),
  lower_pct = c(25.35, 27.85, 36.92, 33.95, 25.98, 29.06, 28.50, 35.45, 32.30, 32.30),
  upper_pct = c(28.74, 31.33, 40.73, 37.92, 30.60, 33.47, 33.43, 40.56, 37.03, 37.86)
)
keys <- c("study", "condition", "outcome")
historical <- merge(figure_points, historical_intervals, by = keys)
stopifnot(nrow(historical) == 10, all(is.finite(historical$estimate_pct)))
readr::write_csv(historical, "tabs/figure_1_historical.csv")
plot_figure_one <- function(probabilities, stem, caption) {
  probabilities$study <- factor(
    probabilities$study,
    levels = c("pooled", "study_2"),
    labels = c("A. Studies 1 and 2", "B. Study 2")
  )
  probabilities$condition <- factor(
    probabilities$condition,
    levels = c("control", "accuracy_appeal", "monetary"),
    labels = c("Control", "Accuracy appeal", "Monetary incentive")
  )
  probabilities$outcome <- factor(
    probabilities$outcome,
    levels = c("uncongenial", "congenial"),
    labels = c("Uncongenial", "Congenial")
  )
  .data <- rlang::.data
  plot <- ggplot2::ggplot(
    probabilities,
    ggplot2::aes(
      x = .data[["outcome"]], y = .data[["estimate_pct"]],
      ymin = .data[["lower_pct"]], ymax = .data[["upper_pct"]]
    )
  ) +
    ggplot2::geom_col(fill = "white", color = "black", width = 0.65) +
    ggplot2::geom_errorbar(width = 0.15) +
    ggplot2::facet_grid(study ~ condition) +
    ggplot2::scale_y_continuous(breaks = seq(0, 60, 10)) +
    ggplot2::coord_cartesian(ylim = c(0, 60)) +
    ggplot2::theme_bw(base_size = 10) +
    ggplot2::theme(panel.grid = ggplot2::element_blank()) +
    ggplot2::labs(x = NULL, y = "Predicted responses (%)", caption = caption)
  ggplot2::ggsave(paste0("figs/", stem, ".pdf"), plot, width = 9, height = 6)
  ggplot2::ggsave(paste0("figs/", stem, ".png"), plot, width = 9, height = 6, dpi = 300)
}
plot_figure_one(
  historical, "figure_1_historical",
  "Recomputed marginal model points; literal interval endpoints from the published Stata script."
)
released_intervals <- do.call(rbind, lapply(c("pooled", "study_2"), function(study) {
  source_study <- if (study == "pooled") "study12" else "study2"
  released <- readr::read_csv(file.path("data/raw/final_bundle", paste0(source_study, "jagsresults.csv")))
  do.call(rbind, lapply(c("uncongenial", "congenial"), function(outcome) {
    prefix <- if (outcome == "uncongenial") "c" else "u"
    data.frame(
      study = study,
      condition = unname(c(control = "control", acc = "accuracy_appeal", monetary = "monetary")[released$cond]),
      outcome = outcome, released_lower_pct = 100 * released[[paste0(prefix, "q025")]],
      released_upper_pct = 100 * released[[paste0(prefix, "q975")]]
    )
  }))
}))
interval_audit <- merge(historical_intervals, released_intervals, by = keys)
interval_audit$lower_difference_pp <- interval_audit$lower_pct - interval_audit$released_lower_pct
interval_audit$upper_difference_pp <- interval_audit$upper_pct - interval_audit$released_upper_pct
readr::write_csv(interval_audit, "tabs/figure_1_interval_provenance.csv")
stopifnot(all(abs(interval_audit$lower_difference_pp) <= 0.005))
stopifnot(all(abs(interval_audit$upper_difference_pp) <= 0.005))
rerun <- readr::read_csv("tabs/figure_1_jags_probabilities.csv")
rerun <- subset(rerun, outcome %in% c("uncongenial", "congenial"))
rerun$lower_pct <- rerun$lower_95 * 100
rerun$upper_pct <- rerun$upper_95 * 100
rerun$conditional_mean_pct <- rerun$mean * 100
comparison <- merge(figure_points, rerun, by = keys)
comparison$conditional_minus_marginal_pp <- comparison$conditional_mean_pct - comparison$estimate_pct
comparison$marginal_mean_pct <- comparison$estimate_pct
comparison$estimate_pct <- comparison$conditional_mean_pct
readr::write_csv(comparison, "tabs/figure_1_rerun.csv")
plot_figure_one(
  comparison, "figure_1_rerun",
  "Conditional posterior mean probabilities and matching JAGS 95% credible intervals."
)
