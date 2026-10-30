source("R/recode.R")
dir.create("data/build", recursive = TRUE, showWarnings = FALSE)
dir.create("tabs", recursive = TRUE, showWarnings = FALSE)
released_path <- "data/raw/final_bundle"
released_wide <- haven::read_dta(file.path(released_path, "psk_wide.dta"))
upstream <- readRDS("data/build/upstream_wide.rds")
upstream <- upstream[match(released_wide$caseid, upstream$caseid), ]
stopifnot(identical(upstream$caseid, as.numeric(released_wide$caseid)))
reconstructed <- recode_published(upstream)
checkpoints <- lapply(c("wide", "long"), function(shape) {
  released <- haven::read_dta(file.path(
    released_path, paste0("psk_", shape, "_recode.dta")
  ))
  keys <- if (shape == "wide") "caseid" else c("caseid", "seq")
  comparison <- compare_recode_checkpoint(reconstructed[[shape]], released, keys)
  comparison$dataset <- shape
  saveRDS(reconstructed[[shape]], file.path(
    "data/build", paste0("published_", shape, ".rds")
  ))
  comparison
})
checkpoints <- do.call(rbind, checkpoints)
readr::write_csv(checkpoints, "tabs/recode_checkpoints.csv")
stopifnot(all(checkpoints$missing_mismatches == 0))
stopifnot(all(checkpoints$value_mismatches == 0))
saveRDS(modernize_columns(reconstructed$wide), "data/build/respondents.rds")
saveRDS(modernize_columns(reconstructed$long), "data/build/responses.rds")
readr::write_csv(recode_name_crosswalk(), "tabs/variable_crosswalk.csv")
knowledge_columns <- c(paste0("kne", 1:8), paste0("kne9_", 1:4), "kn_snmajr", "pk")
knowledge_distribution <- do.call(rbind, lapply(knowledge_columns, function(column) {
  do.call(rbind, lapply(c(2004, 2008), function(year) {
    values <- reconstructed$wide[[column]][reconstructed$wide$pollid == year]
    frequencies <- table(values, useNA = "always")
    data.frame(
      component = column, study_year = year,
      value = names(frequencies), respondents = as.integer(frequencies)
    )
  }))
}))
readr::write_csv(knowledge_distribution, "tabs/knowledge_components.csv")
completion_groups <- split(
  reconstructed$wide,
  interaction(reconstructed$wide$pollid, reconstructed$wide$rd, drop = TRUE)
)
completion_counts <- do.call(rbind, lapply(completion_groups, function(respondents) {
  data.frame(
    study_year = respondents$pollid[1L], treatment_arm = respondents$rd[1L],
    respondents = nrow(respondents),
    completed = if (all(is.na(respondents$complete))) NA_integer_ else sum(respondents$complete == 1, na.rm = TRUE),
    dropped_out_after_randomization = sum(respondents$dropout == 1, na.rm = TRUE)
  )
}))
readr::write_csv(completion_counts, "tabs/completion_counts.csv")
dictionary <- do.call(rbind, lapply(c("wide", "long"), function(shape) {
  reference <- haven::read_dta(file.path(released_path, paste0("psk_", shape, "_recode.dta")))
  crosswalk <- recode_name_crosswalk()
  do.call(rbind, lapply(names(reference), function(variable) {
    values <- reference[[variable]]
    label <- attr(values, "label")
    codes <- attr(values, "labels")
    data.frame(
      dataset = shape, legacy_name = variable,
      modern_name = crosswalk$modern_name[match(variable, crosswalk$legacy_name)],
      description = if (is.null(label)) "" else label,
      value_labels = if (is.null(codes)) "" else paste(paste(names(codes), codes, sep = "="), collapse = "; "),
      missing_count = sum(is.na(values)), observed_count = sum(!is.na(values))
    )
  }))
}))
readr::write_csv(dictionary, "tabs/data_dictionary.csv")
