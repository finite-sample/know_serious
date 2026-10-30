escape_html <- function(value) {
  value <- gsub("&", "&amp;", as.character(value), fixed = TRUE)
  value <- gsub("<", "&lt;", value, fixed = TRUE)
  gsub(">", "&gt;", value, fixed = TRUE)
}
render_table <- function(path, title) {
  table <- readr::read_csv(path, name_repair = "minimal", show_col_types = FALSE)
  for (column in names(table)) {
    if (is.numeric(table[[column]])) table[[column]] <- signif(table[[column]], 5)
  }
  header <- paste0("<th>", escape_html(names(table)), "</th>", collapse = "")
  rows <- apply(table, 1, function(row) {
    paste0("<tr>", paste0("<td>", escape_html(row), "</td>", collapse = ""), "</tr>")
  })
  paste0(
    "<h2>", title, "</h2><p><a href='../", path, "'>Download CSV</a></p>",
    "<div class='scroll'><table><thead><tr>", header, "</tr></thead><tbody>",
    paste(rows, collapse = "\n"), "</tbody></table></div>"
  )
}
sections <- c(
  "tabs/table_1_display.csv" = "Table 1: response shares and incentive contrasts",
  "tabs/table_2_display.csv" = "Table 2: incentive effects",
  "tabs/table_3_display.csv" = "Table 3: partisan reference",
  "tabs/table_4_display.csv" = "Table 4: knowledge moderation",
  "tabs/table_b1_display.csv" = "Table B1: completion time restrictions",
  "tabs/table_b2_display.csv" = "Table B2: published coding windows",
  "tabs/table_b3_display.csv" = "Table B3: item-specific estimates",
  "tabs/model_benchmarks.csv" = "Model benchmarks",
  "tabs/appendix_model_benchmarks.csv" = "Appendix model benchmarks",
  "tabs/model_statistics_benchmarks.csv" = "Fit-statistic benchmarks",
  "tabs/bootstrap_validation.csv" = "Bootstrap uncertainty checks",
  "tabs/model_iia_diagnostics.csv" = "IIA diagnostics and test-order correction",
  "tabs/figure_1_interval_provenance.csv" = "Historical interval provenance",
  "tabs/model_fit_statistics.csv" = "Model fits",
  "tabs/prose_claims.csv" = "Numerical prose checks",
  "tabs/prose_significance.csv" = "Significance claims and reported precision",
  "tabs/corrections.csv" = "Verified code corrections",
  "tabs/model_quadrature.csv" = "Integration accuracy",
  "tabs/jags_diagnostics.csv" = "MCMC diagnostics",
  "tabs/jags_released_comparison.csv" = "Bayesian estimates and archived summaries",
  "tabs/figure_1_rerun.csv" = "Figure 1 prediction-target comparison",
  "tabs/jags_run_settings.csv" = "MCMC run settings"
)
stopifnot(all(file.exists(names(sections))))
figures <- c(
  "figure_2a" = "Figure 2a: knowledge and response categories",
  "figure_2b" = "Figure 2b: modeled response probabilities",
  "figure_2c" = "Figure 2c: knowledge and partisan bias",
  "figure_2d" = "Figure 2d: modeled partisan bias",
  "figure_a1" = "Figure A1: knowledge distributions"
)
stopifnot(file.exists("figs/figure_1_rerun.png"))
stopifnot(all(file.exists(file.path("figs", paste0(names(figures), ".pdf")))))
html <- c(
  "<!doctype html><html lang='en'><meta charset='utf-8'>",
  "<meta name='viewport' content='width=device-width,initial-scale=1'>",
  "<title>Accuracy incentives: replication and audit</title>",
  "<style>body{font:16px/1.5 system-ui;max-width:1100px;margin:3rem auto;padding:0 1rem;color:#243447}",
  "table{border-collapse:collapse;font-size:13px}td,th{padding:7px;border-bottom:1px solid #ddd;text-align:left}",
  ".scroll{overflow:auto}h2{margin-top:2.5rem}th{background:#eef2f5}img{max-width:100%}</style>",
  "<h1>Accuracy incentives: replication and audit</h1>",
  "<p>Prior, Sood, and Khanna (2015). Published coding and item selection are retained.</p>",
  "<p>This report shows numerical reproduction and diagnostics. See <a href='source_audit.md'>",
  "the source audit</a> for missing upstream inputs and interpretation limits. Different random streams",
  "produce different bootstrap and MCMC draws; deterministic counts are compared exactly.</p>",
  unlist(Map(render_table, names(sections), unname(sections))),
  "<h2>Figure 1: historical construction</h2><img src='../figs/figure_1_historical.png' alt='Historical Figure 1'>",
  "<p>Points are reestimated; intervals are literal historical endpoints. Their provenance is audited separately.</p>",
  "<h2>Figure 1: conditional posterior estimates</h2>",
  "<img src='../figs/figure_1_rerun.png' alt='Conditional posterior Figure 1'>",
  "<p>Posterior means and intervals refer to the same conditional probabilities.",
  "These differ from the historical marginal points.</p>",
  "<h2>Additional figures</h2><ul>",
  paste0("<li><a href='../figs/", names(figures), ".pdf'>", figures, "</a></li>"),
  "</ul>",
  "</html>"
)
writeLines(html, "docs/report.html")

observed <- readr::read_csv("tabs/table_1.csv", show_col_types = FALSE)
pooled <- observed[observed$study == "pooled", ]
value <- function(statistic) 100 * pooled$estimate[match(statistic, pooled$statistic)]
benchmark_count <- 2 * nrow(readr::read_csv("tabs/model_benchmarks.csv", show_col_types = FALSE)) +
  nrow(readr::read_csv("tabs/appendix_model_benchmarks.csv", show_col_types = FALSE)) +
  nrow(readr::read_csv("tabs/model_statistics_benchmarks.csv", show_col_types = FALSE))
summary <- c(
  sprintf(
    paste0(
      "Monetary incentives reduce congenial answers from %.1f%% to %.1f%% across the two studies ",
      "(%.1f percentage points). The congenial-minus-uncongenial gap falls from %.1f to %.1f points."
    ),
    value("group_0_congenial"), value("group_1_congenial"), -value("contrast_1_congenial"),
    value("group_0_bias"), value("group_1_bias")
  ),
  "",
  sprintf(
    "All %s checked model benchmarks reproduce at published precision. The audit identifies a prose p-value threshold",
    benchmark_count
  ),
  "inconsistent with Table 1, a small completion-definition discrepancy, and invalid IIA diagnostic inference.",
  "These findings do not establish a change in the reproduced treatment coefficients. See the",
  "[published-article verification](docs/publication_verification.md) and [model audit](docs/model_audit.md).",
  "",
  "The original 2008 delivery is absent; preparation starts from its earliest available checkpoint.",
  "Exact Stata bootstrap-wrapper behavior and clean-container execution remain unverified.",
  "Knowledge scoring and item-selection alternatives are reserved for the separate follow-up."
)
readme <- readLines("README.md")
start <- match("<!-- results:start -->", readme)
end <- match("<!-- results:end -->", readme)
stopifnot(!is.na(start), !is.na(end), start < end)
writeLines(c(readme[seq_len(start)], summary, readme[end:length(readme)]), "README.md")
