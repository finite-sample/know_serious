if (dir.exists(".library")) .libPaths(c(normalizePath(".library"), .libPaths()))
source("R/jags.R")
responses <- readRDS("data/build/published_long.rds")
fits <- list()
for (study in c("pooled", "study_2")) {
  message("Sampling JAGS model: ", study)
  assembled <- assemble_jags_inputs(responses, study)
  source_study <- if (study == "pooled") "study12" else "study2"
  fits[[study]] <- run_jags_study(
    assembled, file.path("data/raw/final_bundle", paste0(source_study, "hologit.jag"))
  )
}
write_jags_outputs(fits)
