source("scripts/verify_sources.R")
for (stage in c(
  "00_upstream", "00_prepare", "01_descriptive", "02_models",
  "03_jags", "04_figures", "05_claims", "06_figure_one", "07_validate", "08_tables",
  "10_knowledge_audit", "09_report"
)) {
  message("Running ", stage)
  sys.source(file.path("scripts", paste0(stage, ".R")), envir = new.env(parent = globalenv()))
}
writeLines(capture.output(sessionInfo()), "docs/session_info.txt")
