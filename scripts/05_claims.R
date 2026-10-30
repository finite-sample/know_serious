wide <- readRDS("data/build/published_wide.rds")
long <- readRDS("data/build/published_long.rds")
survey_2004 <- readr::read_csv(
  "data/extracted/survey_2004.csv",
  col_types = readr::cols(.default = readr::col_double())
)
claims <- new.env(parent = emptyenv())
claims$rows <- list()
record_claim <- function(claim_id, estimate, published, tolerance, unit, producer, comparison = "equal") {
  matches <- switch(comparison,
    equal = abs(estimate - published) <= tolerance,
    less = estimate < published,
    greater = estimate > published
  )
  claims$rows[[length(claims$rows) + 1L]] <- data.frame(
    claim_id = claim_id, estimate = estimate, published = published,
    tolerance = tolerance, unit = unit, producer = producer, comparison = comparison,
    status = ifelse(matches, "matches", "differs")
  )
}
for (study in c(2004, 2008)) {
  record_claim(
    paste0("assigned_", study),
    if (study == 2004) sum(survey_2004$treat == 1) else sum(wide$pollid == study),
    if (study == 2004) 775 else 1633, 0, "respondents",
    if (study == 2004) "original survey treat==1 (60 seconds)" else "released wide"
  )
}
record_claim(
  "reached_last_item_2004", sum(wide$pollid == 2004 & !is.na(wide$l10) & wide$l10 != -2), 618, 0,
  "respondents", "released wide l10 nonmissing and not not-asked (-2)"
)
record_claim(
  "reached_last_item_2008", sum(!is.na(wide$l5[wide$pollid == 2008])),
  1511, 0, "respondents", "released wide l5"
)
for (arm in 0:2) {
  record_claim(
    paste0("instruction_median_", arm),
    median(wide$t_disp[wide$pollid == 2008 & wide$rd %in% arm], na.rm = TRUE),
    c(9, 22, 30)[arm + 1], 0, "seconds", "released wide t_disp"
  )
}
for (specification in list(
  list("unemployment_above_30", "Unemployment 2008", 30, 9.97, FALSE),
  list("uninsured_at_least_50", "Uninsured 2008", 50, 9.78, TRUE),
  list("gas_at_least_10", "Gas Price 2008", 10, 9.46, TRUE)
)) {
  response <- long$l_raw[long$item == specification[[2]] & !is.na(long$l_raw)]
  above <- if (specification[[5]]) response >= specification[[3]] else response > specification[[3]]
  record_claim(
    specification[[1]], mean(above) * 100, specification[[4]], .005,
    "percent of nonmissing raw responses", "legacy main-text rule including negative codes"
  )
}
for (study in c(2004, 2008)) {
  item <- paste("Estate Tax", study)
  response <- long$tri_pp[long$item == item]
  record_claim(
    paste0("estate_correct_", study), mean(response == 1, na.rm = TRUE) * 100,
    if (study == 2004) 42 else 45, .5, "percent", "released long tri_pp"
  )
}
for (study in c(2004, 2008)) {
  columns <- paste0("l", if (study == 2004) 6:10 else 1:5)
  sample <- wide[wide$pollid == study, columns]
  refusal <- mean(vapply(sample, function(response) mean(response == -1, na.rm = TRUE), numeric(1))) * 100
  record_claim(
    paste0("refusal_", study), refusal,
    if (study == 2004) 3.2 else 1.7, .05,
    "mean item refusal percent", "released wide"
  )
}

for (study in c(2004, 2008)) {
  record_claim(
    paste0("independents_", study),
    mean(wide$pid7[wide$pollid == study] == 4, na.rm = TRUE) * 100,
    if (study == 2004) 24 else 16, .5, "percent of observed party IDs", "released wide pid7"
  )
}
completed_two <- wide[wide$pollid == 2008 & !is.na(wide$l5), ]
record_claim(
  "disapproving_republicans_2008",
  sum(completed_two$dem == 0 & completed_two$approve == 0, na.rm = TRUE) / nrow(completed_two) * 100,
  15, .5, "percent of respondents reaching final economic item", "released wide dem/approve"
)
record_claim(
  "approving_democrats_2008",
  sum(completed_two$dem == 1 & completed_two$approve == 1, na.rm = TRUE) / nrow(completed_two) * 100,
  2, .5, "percent of respondents reaching final economic item", "released wide dem/approve"
)
control <- long[which(long$rd == 0 & long$r_bushref == 0), ]
record_claim(
  "consistent_partisan_control_bias",
  mean(control$cong_33[which(control$consis == 1)], na.rm = TRUE) * 100,
  14.6, .05, "percentage points", "Study 2 consistent partisans only"
)
record_claim(
  "whole_sample_control_bias", mean(control$cong_33, na.rm = TRUE) * 100,
  11.5, .05, "percentage points", "Studies 1 and 2 pooled control"
)
record_claim("poverty_correct_within_one_point",
  mean(long$tri_pp[long$item == "Poverty 2004"] == 1, na.rm = TRUE) * 100,
  3, 0, "percent", "published one-point window",
  comparison = "less"
)
table_one <- readr::read_csv("tabs/table_1.csv", show_col_types = FALSE)
for (study in c("pooled", "study_2008")) {
  block <- table_one[table_one$study == study, ]
  statistics <- setNames(block$estimate, block$statistic)
  for (arm in if (study == "pooled") 1 else 1:2) {
    reduction <- -statistics[paste0("contrast_", arm, "_bias")] / statistics["group_0_bias"] * 100
    record_claim(paste0(study, "_bias_reduction_", arm), unname(reduction),
      if (study == "pooled") 40 else 60, 0, "percent reduction in bias",
      "Table 1 observed responses; verifies directional magnitude",
      comparison = "greater"
    )
  }
}
for (model in c("table_2_1", "table_2_2a")) {
  prediction <- readr::read_csv(paste0("tabs/", model, "_predictions.csv"), show_col_types = FALSE)
  stopifnot(!anyDuplicated(names(prediction)), all(prediction$congenial > 0 & prediction$congenial < 1))
  groups <- if (model == "table_2_1") prediction$pay else prediction$rd
  bias <- tapply(prediction$congenial - prediction$uncongenial, groups, mean) * 100
  if (model == "table_2_1") {
    record_claim(
      "pooled_predicted_bias_control", unname(bias["0"]), 11.8, .05,
      "percentage points", "Table 2 column1 estimation-sample marginal predictions"
    )
    record_claim(
      "pooled_predicted_bias_monetary", unname(bias["1"]), 6.3, .05,
      "percentage points", "Table 2 column1 estimation-sample marginal predictions"
    )
  } else {
    for (arm in 1:2) {
      record_claim(paste0("study2_predicted_bias_reduction_", arm),
        unname((bias["0"] - bias[as.character(arm)]) / bias["0"] * 100), 60, 0,
        "percent reduction in bias", "Table 2 column2a estimation-sample marginal predictions",
        comparison = "greater"
      )
    }
  }
}

result <- do.call(rbind, claims$rows)
result$reference_source <- ifelse(grepl("above_30|at_least_50|at_least_10", result$claim_id),
  "July 29 final script comment; manuscript says about ten percent",
  "final manuscript"
)
dir.create("tabs", showWarnings = FALSE)
readr::write_csv(result, "tabs/prose_claims.csv")

source("R/descriptive.R")
significance <- do.call(rbind, lapply(c("pooled", "study_2008"), function(study) {
  selected <- table_one[table_one$study == study & table_one$statistic == "contrast_1_congenial", ]
  rows <- long$r_bushref == 0 & if (study == "pooled") !is.na(long$pay) else long$pollid == 2008
  delta <- cluster_delta_standard_errors(long[which(rows), ], if (study == "pooled") "pay" else "rd")
  reported_se <- if (study == "pooled") .016 else .021
  claimed_threshold <- if (study == "pooled") .001 else .05
  data.frame(
    claim_id = paste0(study, "_congenial_significance"),
    exact_effect = selected$estimate,
    bootstrap_standard_error = selected$standard_error,
    bootstrap_p_one_sided = pnorm(-abs(selected$estimate / selected$standard_error)),
    delta_standard_error = unname(delta["contrast_1_congenial"]),
    delta_p_one_sided = pnorm(-abs(selected$estimate / delta["contrast_1_congenial"])),
    prose_p_threshold = claimed_threshold,
    table_standard_error = reported_se,
    table_significance_marker = if (study == "pooled") "**" else "+",
    minimum_p_from_rounded_table_se = pnorm(-abs(selected$estimate / (reported_se - .0005))),
    maximum_p_from_rounded_table_se = pnorm(-abs(selected$estimate / (reported_se + .0005))),
    sampling_frame = selected$sampling_frame,
    interpretation = "One-sided normal test; reconstructed bootstrap draws differ from original Stata draws"
  )
}))
significance$table_rounding_incompatible_with_prose <-
  significance$minimum_p_from_rounded_table_se >= significance$prose_p_threshold
readr::write_csv(significance, "tabs/prose_significance.csv")
