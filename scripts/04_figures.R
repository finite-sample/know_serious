library(ggplot2)
source("R/smoothing.R")
.data <- rlang::.data
responses <- readRDS("data/build/published_long.rds")
respondents <- readRDS("data/build/published_wide.rds")
knowledge <- respondents[!is.na(respondents$pk) & !is.na(respondents$dem), ]
knowledge$party <- factor(knowledge$dem, 0:1, c("Republican", "Democrat"))
knowledge$weight <- 100 / ave(knowledge$pk, knowledge$party, FUN = length)
figure <- ggplot(knowledge, aes(x = pk, weight = weight)) +
  geom_histogram(binwidth = 1, boundary = -0.5, fill = "#40566E", color = "white") +
  facet_wrap(~party, ncol = 1) +
  theme_minimal(base_size = 12) +
  labs(x = "General political knowledge", y = "Percent")
ggsave("figs/figure_a1.pdf", figure, width = 6, height = 5)
for (model in c("table_2_1", "table_2_2a")) {
  prediction_path <- file.path("tabs", paste0(model, "_predictions.csv"))
  if (!file.exists(prediction_path)) stop("Missing predictions: ", prediction_path)
}
model_predictions <- readr::read_csv("tabs/table_4_predictions.csv", show_col_types = FALSE)
plot_curves <- function(survey, smoother, predicted = FALSE) {
  survey <- survey[complete.cases(survey[, c("acc", "pk")]), ]
  if (!predicted) {
    survey$uncongenial <- ifelse(is.na(survey$cong_33), NA, survey$cong_33 == -1)
    survey$correct <- ifelse(is.na(survey$cong_33), NA, survey$cong_33 == 0)
    survey$congenial <- ifelse(is.na(survey$cong_33), NA, survey$cong_33 == 1)
  }
  survey$cumulative <- survey$uncongenial + survey$correct
  survey$bias <- survey$congenial - survey$uncongenial
  curves <- do.call(rbind, lapply(0:1, function(treatment) {
    do.call(rbind, lapply(c("uncongenial", "cumulative", "bias"), function(measure) {
      selected <- survey[survey$acc == treatment & !is.na(survey[[measure]]), ]
      bandwidth <- if (!predicted && measure == "bias") 1 else 0.6
      curve <- smoother(selected$pk, selected[[measure]], bandwidth = bandwidth)
      data.frame(
        knowledge = curve$x, probability = curve$y, measure = measure,
        condition = c("Control", "Accuracy incentive")[treatment + 1]
      )
    }))
  }))
  list(
    probabilities = ggplot(
      curves[curves$measure != "bias", ],
      aes(.data$knowledge, .data$probability, color = .data$condition, linetype = .data$measure)
    ) +
      geom_line() +
      theme_minimal(base_size = 12) +
      labs(x = "General political knowledge", y = "Probability", color = NULL, linetype = NULL),
    bias = ggplot(
      curves[curves$measure == "bias", ],
      aes(.data$knowledge, .data$probability, color = .data$condition)
    ) +
      geom_line() +
      theme_minimal(base_size = 12) +
      labs(x = "General political knowledge", y = "Congenial minus uncongenial", color = NULL)
  )
}
observed <- plot_curves(responses, smooth_stata_lowess)
predicted <- plot_curves(model_predictions, smooth_stata_lowess, predicted = TRUE)
for (panel in c("a", "b", "c", "d")) {
  figure <- switch(panel,
    a = observed$probabilities,
    b = predicted$probabilities,
    c = observed$bias,
    d = predicted$bias
  )
  ggsave(paste0("figs/figure_2", panel, ".pdf"), figure, width = 7, height = 4)
}
