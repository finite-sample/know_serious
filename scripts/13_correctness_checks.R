source("R/recode.R")
source("R/descriptive.R")
responses <- readRDS("data/build/published_long.rds")
survey_2004 <- readr::read_csv("data/extracted/survey_2004.csv", show_col_types = FALSE)
survey_2008 <- readr::read_csv("data/extracted/survey_2008.csv", show_col_types = FALSE)
references <- readr::read_csv("data/extracted/economic_references_2008.csv", show_col_types = FALSE)
variants <- correctness_variants(responses, references)

items <- c(paste0("e", 1:8), paste0("e9_", 1:4), paste0("e10_", 1:4), "e11", "e12")
keys <- c(3, 1, 2, 1, 3, 2, 1, 1, 2, 1, 1, 1, 4, 1, 1, 1, 1, 4)
checkpoints <- c(paste0("kne", 1:8), paste0("kne9", letters[1:4]), paste0("kne10", letters[1:4]), "kne11", "kne12")
answers <- c(
  "Robert Gates", "Nancy Pelosi", "John Roberts", "Mahmoud Ahmadinejad", "Secretary of State",
  "Ben Bernanke", "Michael Mukasey", "Nicolas Sarkozy", "Democrat", rep("Republican", 3),
  "Not a US senator in 2002", rep("For the bill", 3), "Newt Gingrich", "John Kerry"
)
ledger <- do.call(rbind, lapply(seq_along(items), function(index) {
  answer <- survey_2008[[items[index]]]
  checkpoint <- survey_2008[[checkpoints[index]]]
  scored <- !is.na(checkpoint)
  expected <- as.numeric(answer %in% keys[index])
  data.frame(
    item = items[index], correct_code = keys[index], correct_answer = answers[index],
    included_in_published_score = index <= 12,
    correct_responses = sum(answer == keys[index], na.rm = TRUE),
    raw_missing = sum(is.na(answer)), explicit_refusal = sum(answer == -1, na.rm = TRUE),
    explicit_dont_know = sum(answer == 5, na.rm = TRUE),
    checkpoint_missing = sum(!scored), missing_answer_scored_zero = sum(is.na(answer) & checkpoint %in% 0),
    observed_score_mismatches = sum(expected[scored] != checkpoint[scored]),
    key_type = if (index >= 17) "ideological_ranking" else "historical_fact"
  )
}))
stopifnot(all(ledger$observed_score_mismatches == 0))
readr::write_csv(ledger, "tabs/correctness_knowledge_keys.csv")

calibration <- do.call(rbind, lapply(c(9, 10), function(item) {
  column <- if (item == 9) "q15" else "q18"
  source <- survey_2004[[column]]
  full <- source[which(source >= 0)]
  published <- responses$l[responses$seq == item & !is.na(responses$l)]
  do.call(rbind, lapply(c("full_2004_nonnegative", "published_2004_valid"), function(frame) {
    values <- if (frame == "full_2004_nonnegative") full else published
    score <- classify_responses(values, rep(item, length(values)))
    data.frame(
      item = responses$item[match(item, responses$seq)], frame = frame,
      valid_responses = length(values), correct_responses = sum(score == 1), correct_percent = 100 * mean(score == 1)
    )
  }))
}))
readr::write_csv(calibration, "tabs/correctness_calibration.csv")

comparisons <- list(
  list("uninsured_23_symmetric", 3, variants$published_23, variants$worksheet_23_symmetric),
  list("gas_auxiliary_symmetric", 5, responses$tri_pp, variants$one_point_symmetric),
  list("unemployment_dated", 2, variants$published_33, variants$dated_33),
  list("gas_dated", 5, variants$published_33, variants$dated_33)
)
changes <- do.call(rbind, lapply(comparisons, function(comparison) {
  keep <- responses$seq == comparison[[2]] & !is.na(comparison[[3]])
  before <- comparison[[3]][keep]
  after <- comparison[[4]][keep]
  data.frame(
    comparison = comparison[[1]], valid_responses = sum(keep), changed_classification = sum(before != after),
    before_correct = sum(before == 1), after_correct = sum(after == 1),
    newly_correct = sum(before != 1 & after == 1), newly_incorrect = sum(before == 1 & after != 1)
  )
}))
readr::write_csv(changes, "tabs/correctness_classification_changes.csv")

order <- as.matrix(survey_2008[paste0("e2_ord", 1:4)])
complete <- rowSums(is.na(order)) == 0
stopifnot(all(apply(order[complete, ], 1, function(row) identical(sort(as.numeric(row)), as.numeric(1:4)))))
order_check <- do.call(rbind, lapply(1:4, function(position) {
  selected <- complete & order[, position] %in% 1
  data.frame(
    pelosi_display_position = position, respondents = sum(selected),
    canonical_code_one_correct = sum(survey_2008$e2[selected] == 1, na.rm = TRUE)
  )
}))
readr::write_csv(order_check, "tabs/correctness_randomization.csv")

normalization <- data.frame(
  rule = c(
    "gas_cents_divided_100", "source_gas_above_500", "source_gas_negative", "uninsured_2004_above_100",
    "dated_unemployment_valid", "dated_unemployment_answer_5_1", "economic_recorded_minus_one",
    "six_decimal_rounding_changes"
  ),
  count = c(
    sum(responses$seq == 5 & responses$l_raw >= 100, na.rm = TRUE),
    sum(survey_2008$l5 > 500, na.rm = TRUE), sum(survey_2008$l5 < 0, na.rm = TRUE),
    sum(responses$seq == 9 & responses$l_raw > 100, na.rm = TRUE),
    sum(responses$seq == 2 & references$unemployment_reference[match(responses$caseid, references$caseid)] == 5.1 &
          !is.na(responses$l), na.rm = TRUE),
    sum(responses$seq == 2 & references$unemployment_reference[match(responses$caseid, references$caseid)] == 5.1 &
          responses$l == 5.1, na.rm = TRUE),
    sum(responses$l_raw == -1, na.rm = TRUE),
    sum(vapply(names(economic_answer_windows()), function(window) {
      sum(classify_responses(round(responses$l, 6), responses$seq, window) !=
            classify_responses(responses$l, responses$seq, window), na.rm = TRUE)
    }, numeric(1)))
  )
)
readr::write_csv(normalization, "tabs/correctness_normalization.csv")

pooled <- responses[which(responses$r_bushref == 0 & !is.na(responses$pay)), ]
no_cents <- pooled$l
no_cents[which(pooled$seq == 5 & pooled$l_raw >= 100)] <- pooled$l_raw[which(pooled$seq == 5 & pooled$l_raw >= 100)]
congeniality <- list(
  published = pooled$cong_33,
  common_direction_estate = partisan_response_code(pooled$tri_33, pooled$dem, pooled$seq, reverse_estate = FALSE),
  no_gas_unit_conversion = partisan_response_code(classify_responses(no_cents, pooled$seq), pooled$dem, pooled$seq)
)
descriptive <- do.call(rbind, lapply(names(congeniality), function(definition) {
  candidate <- pooled
  candidate$cong_33 <- congeniality[[definition]]
  statistic <- "contrast_1_bias"
  estimate <- response_statistics(candidate, "pay")[statistic] * 100
  standard_error <- cluster_delta_standard_errors(candidate, "pay")[statistic] * 100
  data.frame(definition = definition, estimate_pp = unname(estimate), standard_error_pp = unname(standard_error))
}))
descriptive$lower_95_pp <- descriptive$estimate_pp - qnorm(.975) * descriptive$standard_error_pp
descriptive$upper_95_pp <- descriptive$estimate_pp + qnorm(.975) * descriptive$standard_error_pp
readr::write_csv(descriptive, "tabs/correctness_direction_units.csv")

accuracy <- do.call(rbind, lapply(c("published_valid", "recorded_nonanswer_incorrect"), function(definition) {
  outcome <- as.numeric(pooled$tri_33 == 1)
  outcome[is.na(pooled$dem)] <- NA_real_
  if (definition == "recorded_nonanswer_incorrect") {
    outcome[which(pooled$l_raw == -1 & !is.na(pooled$dem))] <- 0
  }
  means <- vapply(0:1, function(group) mean(outcome[pooled$pay == group], na.rm = TRUE), numeric(1))
  influence <- numeric(nrow(pooled))
  for (group in 0:1) {
    selected <- pooled$pay == group & !is.na(outcome)
    influence[selected] <- (2 * group - 1) * (outcome[selected] - means[group + 1]) / sum(selected)
  }
  clusters <- length(unique(pooled$caseid))
  standard_error <- sqrt(sum(rowsum(influence, pooled$caseid)^2) * clusters / (clusters - 1)) * 100
  data.frame(
    definition = definition, usable_answers = sum(!is.na(outcome)), control_correct_percent = means[1] * 100,
    monetary_correct_percent = means[2] * 100, estimate_pp = diff(means) * 100,
    standard_error_pp = standard_error, lower_95_pp = diff(means) * 100 - qnorm(.975) * standard_error,
    upper_95_pp = diff(means) * 100 + qnorm(.975) * standard_error
  )
}))
readr::write_csv(accuracy, "tabs/correctness_nonresponse.csv")
