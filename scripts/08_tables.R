estimates <- readr::read_csv("tabs/model_estimates.csv", show_col_types = FALSE)
fits <- readr::read_csv("tabs/model_fit_statistics.csv", show_col_types = FALSE)
wald <- readr::read_csv("tabs/model_wald_tests.csv", show_col_types = FALSE)
format_cell <- function(estimate, standard_error) {
  digits <- ifelse(abs(estimate) > 0 & abs(estimate) < 0.01, 3L, 2L)
  sprintf("%.*f (%.*f)", digits, estimate, digits, standard_error)
}
write_display <- function(table, name) {
  readr::write_csv(table, paste0("tabs/", name, "_display.csv"))
  escape_tex <- function(value) {
    for (character in c("_", "%", "&", "#")) {
      value <- gsub(character, paste0("\\", character), value, fixed = TRUE)
    }
    value
  }
  rows <- apply(table, 1, function(row) paste(escape_tex(row), collapse = " & "))
  writeLines(c(
    paste0("\\begin{tabular}{l", paste(rep("r", ncol(table) - 1), collapse = ""), "}"),
    "\\toprule", paste0(paste(escape_tex(names(table)), collapse = " & "), " \\\\"),
    "\\midrule", paste0(rows, " \\\\"), "\\bottomrule", "\\end{tabular}"
  ), paste0("tabs/", name, ".tex"))
}
format_regression <- function(models, terms, labels, columns = models) {
  table <- data.frame(quantity = c(labels, "Random-intercept variance", "Responses", "Respondents", "Log likelihood"))
  for (index in seq_along(models)) {
    model <- models[index]
    cells <- vapply(terms, function(term) {
      row <- estimates[estimates$model == model & estimates$term == term, ]
      if (nrow(row) == 0) {
        return("—")
      }
      stopifnot(nrow(row) == 1)
      format_cell(row$estimate, row$standard_error)
    }, character(1))
    fit <- fits[fits$model == model, ]
    stopifnot(nrow(fit) == 1)
    table[[columns[index]]] <- c(
      cells, format_cell(fit$random_variance, fit$random_variance_se),
      fit$observations, fit$respondents, sprintf("%.0f", fit$log_likelihood)
    )
  }
  if (any(models %in% wald$model)) {
    diagnostics <- data.frame(quantity = c("Incentive equality: chi-square", "Degrees of freedom", "Equality-test p"))
    for (index in seq_along(models)) {
      row <- wald[wald$model == models[index], ]
      diagnostics[[columns[index]]] <- if (nrow(row) == 0) {
        rep("—", 3)
      } else {
        c(sprintf("%.2f", row$statistic), row$degrees_freedom, sprintf("%.3f", row$p_value))
      }
    }
    table <- rbind(table, diagnostics)
  }
  table
}
terms <- c("pay", "mon", "app", "acc")
labels <- c("Monetary incentive (pooled studies)", "Monetary incentive", "Accuracy appeal", "Accuracy incentive")
write_display(format_regression(
  c("table_2_1", "table_2_2a", "table_2_2b", "table_2_3a", "table_2_3b"),
  terms, labels, c("1", "2a", "2b", "3a", "3b")
), "table_2")
write_display(format_regression(
  c("table_3_1", "table_3_2"), c("mon", "app", "acc", "r_bushref", "monxbush", "appxbush", "accxbush"),
  c(
    "Monetary incentive", "Accuracy appeal", "Accuracy incentive", "Bush reference",
    "Monetary x Bush", "Appeal x Bush", "Incentive x Bush"
  ), c("1", "2")
), "table_3")
nominal <- data.frame(quantity = c("Accuracy incentive", "Political knowledge", "Incentive x knowledge"))
for (category in c("correct", "uncongenial")) {
  nominal[[category]] <- vapply(c("acc", "pk", "accxpk"), function(term) {
    row <- estimates[estimates$model == "table_4" & estimates$term == paste0(category, "_", term), ]
    stopifnot(nrow(row) == 1)
    format_cell(row$estimate, row$standard_error)
  }, character(1))
}
shared_fit <- fits[fits$model == "table_4", ]
nominal <- rbind(nominal, data.frame(
  quantity = c("Shared random-intercept variance", "Responses", "Respondents", "Log likelihood"),
  correct = c(
    format_cell(shared_fit$random_variance, shared_fit$random_variance_se),
    shared_fit$observations, shared_fit$respondents, sprintf("%.0f", shared_fit$log_likelihood)
  ),
  uncongenial = "—"
))
iia <- readr::read_csv("tabs/model_iia_diagnostics.csv", show_col_types = FALSE)
nominal <- rbind(nominal, data.frame(
  quantity = paste0("IIA statistic (omit category ", iia$omitted_category, "; invalid chi-square inference)"),
  correct = sprintf("%.3f", iia$statistic), uncongenial = "—"
))
write_display(nominal, "table_4")
write_display(format_regression(
  c("table_2_2a", paste0("table_b1_", c(60, 45, 40, 35))), c("mon", "app"),
  c("Monetary incentive", "Accuracy appeal"), c("Unrestricted", paste0(c(60, 45, 40, 35), " seconds"))
), "table_b1")
models <- unlist(lapply(c("pooled", "study_two", "consistent"), function(sample) {
  paste0("table_b2_", sample, "_", c("po", "10", "23"))
}))
write_display(format_regression(models, terms[1:3], labels[1:3], as.character(1:9)), "table_b2")
items <- readr::read_csv("tabs/table_b3.csv", show_col_types = FALSE)
items <- items[items$term %in% c("pay", "mon", "app"), ]
items$coefficient_se <- format_cell(items$estimate, items$standard_error)
item_fits <- readr::read_csv("tabs/table_b3_fit_statistics.csv", show_col_types = FALSE)
item_wald <- readr::read_csv("tabs/table_b3_wald_tests.csv", show_col_types = FALSE)
matched_fit <- item_fits[match(items$item, item_fits$item), ]
matched_wald <- item_wald[match(items$item, item_wald$item), ]
items$log_likelihood <- sprintf("%.2f", matched_fit$log_likelihood)
items$model_lr <- sprintf("%.2f", matched_fit$likelihood_ratio)
items$model_df <- matched_fit$degrees_freedom
items$model_p <- sprintf("%.3f", matched_fit$p_value)
items$equality_chisq <- ifelse(is.na(matched_wald$statistic), "—", sprintf("%.2f", matched_wald$statistic))
items$equality_p <- ifelse(is.na(matched_wald$p_value), "—", sprintf("%.3f", matched_wald$p_value))
write_display(as.data.frame(items[c(
  "item", "term", "coefficient_se", "observations", "log_likelihood", "model_lr", "model_df",
  "model_p", "equality_chisq", "equality_p"
)]), "table_b3")
observed <- readr::read_csv("tabs/table_1.csv", show_col_types = FALSE)
observed$estimate_se_pct <- sprintf("%.1f (%.1f)", 100 * observed$estimate, 100 * observed$standard_error)
write_display(as.data.frame(observed[c("study", "statistic", "estimate_se_pct")]), "table_1")
counts <- readr::read_csv("tabs/table_1_count_benchmarks.csv", show_col_types = FALSE)
write_display(as.data.frame(counts[c(
  "study", "treatment", "reproduced_respondents", "usable_respondents", "reproduced_responses"
)]), "table_1_counts")
writeLines(c(
  "\\documentclass[10pt]{article}", "\\usepackage[landscape,margin=1.5cm]{geometry}",
  "\\usepackage{booktabs,graphicx,fontspec,adjustbox}", "\\begin{document}",
  "\\section*{Published-specification replication tables}",
  "Coefficients and standard errors are regenerated. Table 1 shares are percentages; contrasts are percentage points.",
  "See the audit report for bootstrap sampling-frame limits. Significance symbols are omitted.",
  "Equality tests are Wald tests. IIA statistics are historical diagnostics with invalid chi-square inference.",
  "The Table 1 count supplement distinguishes published participation counts from usable respondents.",
  unlist(lapply(c(
    "table_1", "table_1_counts", "table_2", "table_3", "table_4", "table_b1", "table_b2", "table_b3"
  ), function(name) {
    c(
      "\\clearpage", paste0("\\section*{", paste("Table", toupper(gsub("_", " ", sub("table_", "", name)))), "}"),
      paste0(
        "\\begin{adjustbox}{max width=\\textwidth,max totalheight=\\dimexpr\\textheight-3cm\\relax}",
        "\\input{tabs/", name, ".tex}\\end{adjustbox}"
      )
    )
  })), "\\end{document}"
), "docs/tables.tex")
