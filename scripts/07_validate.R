source("R/descriptive.R")
responses <- readRDS("data/build/published_long.rds")
respondents <- readRDS("data/build/published_wide.rds")
estimates <- readr::read_csv("tabs/table_1.csv", show_col_types = FALSE)
measures <- c("congenial", "correct", "uncongenial", "bias")
benchmark_block <- function(study, prefix, values, errors) {
  data.frame(
    study = study, statistic = paste0(prefix, "_", measures),
    published = values, published_standard_error = errors
  )
}
benchmarks <- do.call(rbind, list(
  benchmark_block("pooled", "group_0", c(39.6, 32.3, 28.1, 11.5), c(1.1, 1.2, 1.0, 1.7)),
  benchmark_block("pooled", "group_1", c(34.8, 36.5, 28.7, 6.1), c(1.2, 1.3, 1.0, 1.7)),
  benchmark_block("pooled", "contrast_1", c(-4.8, 4.2, .6, -5.4), c(1.6, 1.7, 1.4, 2.6)),
  benchmark_block("study_2004", "group_0", c(40.7, 31.5, 27.8, 12.9), c(1.6, 1.8, 1.3, 2.2)),
  benchmark_block("study_2004", "group_1", c(35.4, 37.2, 27.3, 8.1), c(1.7, 1.7, 1.4, 2.5)),
  benchmark_block("study_2004", "contrast_1", c(-5.2, 5.7, -.5, -4.8), c(2.3, 2.3, 1.9, 3.4)),
  benchmark_block("study_2008", "group_0", c(38.3, 33.2, 28.4, 9.9), c(1.5, 1.5, 1.4, 2.6)),
  benchmark_block("study_2008", "group_1", c(34.9, 33.5, 31.6, 3.4), c(1.4, 1.5, 1.4, 2.3)),
  benchmark_block("study_2008", "group_2", c(34.1, 35.7, 30.3, 3.8), c(1.6, 1.8, 1.4, 2.6)),
  benchmark_block("study_2008", "contrast_1", c(-3.4, .2, 3.2, -6.6), c(2.1, 2.2, 2.1, 3.5)),
  benchmark_block("study_2008", "contrast_2", c(-4.3, 2.4, 1.8, -6.1), c(2.3, 2.3, 2.2, 3.8))
))
comparison <- merge(benchmarks, estimates, by = c("study", "statistic"), all.x = TRUE)
comparison$estimate <- comparison$estimate * 100
comparison$standard_error <- comparison$standard_error * 100
comparison$difference <- comparison$estimate - comparison$published
comparison$matches_reported_precision <- abs(comparison$difference) <= .05 + 1e-10
comparison$standard_error_difference <- comparison$standard_error - comparison$published_standard_error
comparison$standard_error_status <- "sampling-frame and Monte Carlo validation required"
readr::write_csv(comparison, "tabs/table_1_benchmarks.csv")

count_benchmarks <- data.frame(
  study = c(rep("pooled", 2), rep("study_2004", 2), rep("study_2008", 3)),
  treatment = c(0, 2, 0, 2, 0, 1, 2),
  published_respondents = c(455, 430, 242, 229, 213, 246, 201),
  published_responses = c(2217, 2107, 1158, 1109, 1059, 1219, 998)
)
counts <- do.call(rbind, lapply(seq_len(nrow(count_benchmarks)), function(index) {
  row <- count_benchmarks[index, ]
  survey_year <- switch(row$study,
    pooled = c(2004, 2008),
    study_2004 = 2004,
    study_2008 = 2008
  )
  raw_rows <- respondents[which(
    respondents$pollid %in% survey_year & respondents$rd == row$treatment &
      respondents$r_bushref == 0 & !is.na(respondents$dem)
  ), ]
  has_response <- rowSums(!is.na(raw_rows[paste0("l", 1:10)])) > 0
  usable <- responses[which(
    responses$pollid %in% survey_year & responses$rd == row$treatment &
      responses$r_bushref == 0 & !is.na(responses$cong_33)
  ), ]
  row$reproduced_respondents <- sum(has_response)
  row$usable_respondents <- length(unique(usable$caseid))
  row$reproduced_responses <- nrow(usable)
  row$respondents_match <- row$reproduced_respondents == row$published_respondents
  row$responses_match <- row$reproduced_responses == row$published_responses
  row
}))
readr::write_csv(counts, "tabs/table_1_count_benchmarks.csv")
stopifnot(nrow(comparison) == 44, all(comparison$matches_reported_precision))
stopifnot(all(counts$respondents_match), all(counts$responses_match))
validation <- do.call(rbind, lapply(unique(estimates$study), function(study) {
  rows <- switch(study,
    pooled = responses$r_bushref == 0 & !is.na(responses$pay),
    study_2004 = responses$pollid == 2004,
    study_2008 = responses$pollid == 2008 & responses$r_bushref == 0
  )
  sample <- responses[which(rows), ]
  group_column <- if (study == "study_2008") "rd" else "pay"
  delta <- cluster_delta_standard_errors(sample, group_column)
  selected <- estimates[estimates$study == study, ]
  selected$delta_standard_error <- unname(delta[selected$statistic])
  selected$approximate_mc_error <- selected$standard_error / sqrt(2 * (selected$replicates - 1))
  selected$bootstrap_minus_delta <- selected$standard_error - selected$delta_standard_error
  selected$within_three_mc_errors <- abs(selected$bootstrap_minus_delta) <= 3 * selected$approximate_mc_error
  selected
}))
readr::write_csv(validation, "tabs/bootstrap_validation.csv")

prose <- readr::read_csv("tabs/prose_claims.csv", show_col_types = FALSE)
completion <- prose[prose$claim_id == "reached_last_item_2004", ]
iia <- readr::read_csv("tabs/model_iia_diagnostics.csv", show_col_types = FALSE)
corrections <- rbind(
  data.frame(
    finding = "study_2004_completion_definition",
    quantity = "Respondents reaching the last economic item",
    original_value = completion$published, comparison_value = completion$estimate,
    interpretation = "Four retained records code the final item as not asked; estimation sample remains unchanged"
  ),
  data.frame(
    finding = "iia_test_order", quantity = paste0("Omitted response category ", iia$omitted_category),
    original_value = iia$statistic, comparison_value = iia$corrected_order_statistic,
    interpretation = "Reversed model order; neither covariance difference supports chi-square inference"
  )
)
significance <- readr::read_csv("tabs/prose_significance.csv", show_col_types = FALSE)
pooled_significance <- significance[significance$claim_id == "pooled_congenial_significance", ]
corrections <- rbind(corrections, data.frame(
  finding = "pooled_significance_threshold",
  quantity = "Claimed p-value threshold versus minimum p-value allowed by SE rounding",
  original_value = pooled_significance$prose_p_threshold,
  comparison_value = pooled_significance$minimum_p_from_rounded_table_se,
  interpretation = "Prose p < .001 is incompatible with exact effect and published SE; evidence remains below .01"
))
readr::write_csv(corrections, "tabs/corrections.csv")
