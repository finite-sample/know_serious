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
  "tabs/table_1_counts_display.csv" = "Table 1: participation and usable responses",
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
if (file.exists("tabs/knowledge_bias_contrasts.csv")) {
  sections <- c(sections, "tabs/knowledge_bias_contrasts.csv" = "Knowledge moderation: direct probability contrasts")
}
if (file.exists("tabs/knowledge_sensitivity_interactions.csv")) {
  sections <- c(sections,
    "tabs/knowledge_sensitivity.csv" = "Separate audit: alternative knowledge scores",
    "tabs/knowledge_sensitivity_interactions.csv" = "Separate audit: joint interaction tests",
    "tabs/knowledge_missingness_impact.csv" = "Separate audit: missing knowledge and sample eligibility",
    "tabs/economic_item_sensitivity.csv" = "Separate audit: economic-item dependence"
  )
}
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
  "<p>See <a href='exhibit_status.md'>the exhibit status</a> for exact versus approximate reproduction,",
  "and <a href='knowledge_audit.md'>the separate knowledge audit</a> for score and item sensitivities.</p>",
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

if (file.exists("tabs/knowledge_sensitivity_interactions.csv")) {
  sensitivity <- readr::read_csv("tabs/knowledge_sensitivity.csv", show_col_types = FALSE)
  interaction <- readr::read_csv("tabs/knowledge_sensitivity_interactions.csv", show_col_types = FALSE)
  missingness <- readr::read_csv("tabs/knowledge_missingness_impact.csv", show_col_types = FALSE)
  omissions <- readr::read_csv("tabs/economic_item_sensitivity.csv", show_col_types = FALSE)
  moderation <- sensitivity[sensitivity$contrast == "moderation", ]
  labels <- c(
    published = "Published score", strict_caucus = "Strict Senate, appendix key (51/49)",
    strict_party = "Strict Senate, party membership (49/49)", omit_senate = "Omit Senate item",
    expanded_items = "Add six knowledge items"
  )
  stopifnot(setequal(moderation$variant, names(labels)), nrow(moderation) == 5)
  rows <- vapply(seq_len(nrow(moderation)), function(index) {
    row <- moderation[index, ]
    test <- interaction[interaction$variant == row$variant, ]
    sprintf(
      "| %s | %.2f | [%.2f, %.2f] | %.4f |",
      labels[row$variant], row$estimate_pp, row$lower_95_pp, row$upper_95_pp, test$p_value
    )
  }, character(1))
  omitted <- omissions[omissions$omitted_item != "none", ]
  baseline_effect <- omissions$estimate_pp[omissions$omitted_item == "none"]
  crossing <- sum(omitted$lower_95_pp <= 0 & omitted$upper_95_pp >= 0)
  original <- sensitivity[sensitivity$variant == "published", ]
  describe_contrast <- function(name, label) {
    row <- original[original$contrast == name, ]
    sprintf("%s: %.2f points [%.2f, %.2f].", label, row$estimate_pp, row$lower_95_pp, row$upper_95_pp)
  }
  writeLines(c(
    "# Knowledge and item-selection audit", "",
    "The initial alternatives preserve the direction of knowledge moderation. Changing Senate",
    "credit or the Senate key barely changes the probability contrast; adding six knowledge",
    "items gives a larger estimated contrast. This is stability within the tested family,",
    "not evidence that every defensible measure would give the same result.", "",
    "## Knowledge scoring", "",
    "Every row uses the same 1,260 respondents and 6,233 item responses, the published",
    "multinomial model, and equal weights over the same five economic items. The quantity",
    "is the incentive effect on response bias at score 9.5 minus its effect at 4.5.",
    "Negative values mean a larger reduction at higher measured knowledge. Scores are",
    "rescaled to 0–13; these are fixed fractions of each scale, not identical latent",
    "knowledge levels or each alternative's own quartiles.", "",
    "| Knowledge score | Difference in effects (pp) | Pointwise 95% interval | Joint interaction p |",
    "|---|---:|---:|---:|", rows, "",
    "Intervals use the complete inverse-Hessian covariance and the delta method. The joint",
    "test addresses both model-scale interaction coefficients; it is distinct from the",
    "probability contrast. This retrospective family is exploratory and unadjusted for",
    "multiple comparisons. Differences between alternative point estimates have not been",
    "tested using their joint sampling covariance. Knowledge is not randomized.", "",
    "Original-score incentive effects and model-based 95% intervals:", "",
    paste0("- ", describe_contrast("treatment_low", "At score 4.5")),
    paste0("- ", describe_contrast("treatment_high", "At score 9.5")),
    paste0("- ", describe_contrast("incentive_gradient", "Knowledge gradient under incentives")), "",
    "The lower-score result does not establish no incentive effect. Nonrejection of",
    "the incentive-arm knowledge gradient does not establish that the association disappears.", "",
    "## What the alternatives change", "",
    "The fractional Senate component is explicitly present in the released recode script.",
    "It is an intentional published rule, not an accidental R translation. The strict",
    "appendix-key score separates the effect of partial credit from the answer key.",
    "The literal-party variant reflects the questionnaire's wording about party members:",
    "the 110th Senate had 49 Democrats, 49 Republicans, and two other senators who caucused",
    paste0("with Democrats. See the [official Senate history]",
      "(https://www.senate.gov/about/parties-leadership/party-division.shtml)."
    ),
    "The original visual-recoding script remains missing, so the upstream rationale is",
    "not fully recovered. Both keys are reported rather than selecting one by its result.", "",
    "The six added questions concern four Iraq authorization votes and two ideological",
    "orderings. Their raw-response indicators exactly match the checkpoint's binary",
    "scores. This alternative broadens political knowledge beyond the selected recognition",
    "items and treats missing extra answers as zero, as those checkpoint scores do.",
    "It is a different measurement choice, not a demonstrated correction. Knowledge",
    "screens E/F precede the incentive instructions at Screen L-Intro in the questionnaire.", "",
    "## Missing knowledge scores", "",
    sprintf(
      "All %s respondents missing the published score also lack party identification.",
      missingness$missing_knowledge_respondents
    ),
    sprintf(
      "Filling knowledge alone adds %s model rows and %s usable respondents.",
      missingness$added_model_rows_if_knowledge_filled, missingness$added_model_respondents_if_knowledge_filled
    ),
    "They also lack substantive economic answers. Thus the apparent score-missingness",
    "issue does not by itself alter Table 4's sample. Fifteen respondents already in",
    "that sample have a missing numeric Senate response and published Senate credit zero;",
    "the strict alternatives retain that zero to hold the sample fixed.", "",
    "## Economic-item selection", "",
    sprintf(
      "The pooled monetary-versus-control bias effect is %.2f points. Omitting each published",
      baseline_effect
    ),
    sprintf(
      "item in turn gives effects from %.2f to %.2f points; all remain negative.",
      min(omitted$estimate_pp), max(omitted$estimate_pp)
    ),
    sprintf(
      "%s of the ten two-sided 95%% respondent-cluster delta intervals include zero.", crossing
    ),
    paste0("These omit: ", paste(omitted$omitted_item[
      omitted$lower_95_pp <= 0 & omitted$upper_95_pp >= 0
    ], collapse = ", "), ". This interval"),
    "convention differs from the paper's one-sided tests. The result is sensitivity in",
    "magnitude and precision, not a sign reversal. Omissions also change the relative",
    "numbers of observed answers from each study; these are response-weighted pooled",
    "comparisons, not estimates standardized to a fixed study mixture.", "",
    "## Reproduce and extend", "",
    "After `make analysis`, run `make sensitivity` and `Rscript scripts/09_report.R`.",
    "`make audit` computes the original-score contrasts alone. All alternative fits",
    "pass convergence, positive-Hessian, gradient, and 31/61-node quadrature checks.",
    "The baseline coefficients, tables, and historical figures are preserved.", "",
    "- [Correctness-coding audit](correctness_audit.md): factual keys, answer windows, units, and nonresponse",
    "- [Retrospective plan](sensitivity_plan.md)",
    "- [Score comparisons and intervals](../tabs/knowledge_sensitivity.csv)",
    "- [Score changes](../tabs/knowledge_score_changes.csv)",
    "- [Fit diagnostics](../tabs/knowledge_sensitivity_diagnostics.csv)",
    "- [Economic-item comparisons](../tabs/economic_item_sensitivity.csv)",
    "- [Knowledge sensitivity figure](../figs/knowledge_sensitivity.pdf)", "",
    "The author's rationale for excluding the six knowledge items remains unresolved.",
    "Randomized-format effects, leave-one-knowledge-item-out checks, and adding the",
    "omitted 2004 tax-comparison and campaign-proposal questions require further work.",
    "Those questions need explicit construct and partisan-direction definitions before",
    "they can be treated as interchangeable economic outcomes."
  ), "docs/knowledge_audit.md")
}

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
  "Knowledge scoring and item-selection sensitivities are reported separately in the",
  "[knowledge audit](docs/knowledge_audit.md); the publication baseline is preserved."
)
readme <- readLines("README.md")
start <- match("<!-- results:start -->", readme)
end <- match("<!-- results:end -->", readme)
stopifnot(!is.na(start), !is.na(end), start < end)
writeLines(c(readme[seq_len(start)], summary, readme[end:length(readme)]), "README.md")
