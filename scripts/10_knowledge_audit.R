source("R/models.R")
survey <- readRDS("data/build/published_long.rds")
fit <- readRDS("data/build/models/table_4.rds")
sample <- survey[fit$rows, ]
stopifnot(nrow(sample) == fit$observations, length(unique(sample$caseid)) == fit$respondents)
items <- sample[!duplicated(sample$item), ]
respondents <- sample[!duplicated(sample$caseid), ]
quartiles <- unname(quantile(respondents$pk, c(.25, .75)))
contrasts <- rbind(
  data.frame(range = "interquartile", knowledge_bias_contrasts(fit, items, quartiles[1], quartiles[2])),
  data.frame(range = "endpoints", knowledge_bias_contrasts(fit, items, 0, 13))
)
readr::write_csv(contrasts, "tabs/knowledge_bias_contrasts.csv")
support <- as.data.frame(table(respondents$pk), stringsAsFactors = FALSE)
names(support) <- c("knowledge", "respondents")
support$knowledge <- as.numeric(support$knowledge)
readr::write_csv(support, "tabs/knowledge_score_support.csv")
readr::write_csv(knowledge_interaction_test(fit), "tabs/knowledge_interaction_test.csv")
selected <- contrasts[contrasts$contrast %in% c("treatment_low", "treatment_high", "moderation"), ]
selected$label <- paste(
  ifelse(selected$range == "interquartile", "Scores 4.5 to 9.5", "Scores 0 to 13"),
  c(
    treatment_low = "effect at lower score", treatment_high = "effect at higher score",
    moderation = "higher minus lower effect"
  )[selected$contrast],
  sep = ": "
)
.data <- rlang::.data
figure <- ggplot2::ggplot(selected, ggplot2::aes(
  x = .data$estimate_pp, y = .data$label, xmin = .data$lower_95_pp, xmax = .data$upper_95_pp
)) +
  ggplot2::geom_vline(xintercept = 0, color = "grey60", linetype = 2) +
  ggplot2::geom_pointrange(orientation = "y") +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::labs(
    x = "Change in congenial minus uncongenial probability (percentage points)", y = NULL,
    caption = "Published knowledge score and Table 4 model; equal weights over five items. Model-based 95% intervals."
  )
ggplot2::ggsave("figs/knowledge_bias_contrasts.pdf", figure, width = 10, height = 4)
print(selected[c("range", "contrast", "estimate_pp", "lower_95_pp", "upper_95_pp")])
