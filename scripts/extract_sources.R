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
gas_path <- "data/raw/upstream/KN2008 and Gas/gasprice2.dta"
expected <- private_manifest$sha256[match(gas_path, private_manifest$path)]
stopifnot(identical(digest::digest(file = gas_path, algo = "sha256"), expected))
gas <- haven::read_dta(gas_path)
survey <- haven::read_dta(sources[["2008"]])
stopifnot(!anyDuplicated(gas$caseid), setequal(gas$caseid, survey$caseid))
gas <- gas[match(survey$caseid, gas$caseid), ]
after_release <- !is.na(survey$tm_start) & as.Date(survey$tm_start, tz = "UTC") >= as.Date("2008-04-05")
references <- data.frame(
  caseid = as.numeric(survey$caseid),
  unemployment_reference = ifelse(after_release, 5.1, 4.8),
  gas_reference = as.numeric(gas$avgprice)
)
stopifnot(all(references$gas_reference > 3 & references$gas_reference < 4))
readr::write_csv(references, "data/extracted/economic_references_2008.csv")
