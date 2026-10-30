source("R/source_projection.R")
sources <- c(
  "2004" = "data/raw/upstream/PriorLupia2004/PriorLupia20004.surveydata.dta",
  "2008" = "data/raw/upstream/KN2008 and Gas/temp.dta"
)
private_manifest <- readr::read_csv("docs/private_source_manifest.csv", show_col_types = FALSE)
dir.create("data/extracted", recursive = TRUE, showWarnings = FALSE)
inventory <- list()
for (study in names(sources)) {
  path <- sources[[study]]
  if (!file.exists(path)) stop("Local original required for extraction: ", path)
  expected <- private_manifest$sha256[match(path, private_manifest$path)]
  stopifnot(identical(digest::digest(file = path, algo = "sha256"), expected))
  survey <- haven::read_dta(path)
  projected <- project_source_columns(survey, as.integer(study))
  output <- paste0("data/extracted/survey_", study, ".csv")
  readr::write_csv(projected, output)
  round_trip <- readr::read_csv(output, col_types = readr::cols(.default = readr::col_double()))
  stopifnot(nrow(round_trip) == nrow(survey), identical(names(round_trip), names(projected)))
  stopifnot(all(vapply(names(projected), function(column) {
    identical(is.na(round_trip[[column]]), is.na(projected[[column]])) &&
      isTRUE(all.equal(round_trip[[column]], projected[[column]], tolerance = 1e-14))
  }, logical(1))))
  inventory[[study]] <- do.call(rbind, lapply(names(survey), function(column) {
    labels <- attr(survey[[column]], "labels")
    description <- attr(survey[[column]], "label", exact = TRUE)
    data.frame(
      study_year = as.integer(study), source_column = column,
      included = column %in% names(projected),
      description = if (is.null(description)) "" else description,
      value_labels = paste(paste0(names(labels), "=", labels), collapse = " | "),
      reason = if (column %in% names(projected)) {
        "Replication, item-selection, or knowledge-measurement field"
      } else {
        "Not needed for these analyses; omitted from public projection"
      }
    )
  }))
}
readr::write_csv(do.call(rbind, inventory), "docs/source_columns.csv")
