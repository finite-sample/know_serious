source_projection_columns <- function(study, available) {
  if (study == 2004) {
    columns <- c("caseid", "treat", "group", "ex_group", "incomp", "pid7", "inet_sp", paste0("q", 5:18))
  } else {
    columns <- c(
      "caseid", "rd", "h1c", paste0("l", 1:5), "ppnet", "cu07serv",
      paste0("t_l", 1:5), "pid7", "r_PIDloc", "r_bushref", "kn_snmaj",
      "pres_app", "inet_sp", "k3a", "m1_1", paste0("t_disp", 1:3), "f2", "t_f2", "ecomp",
      paste0("r", c("a", "b", "c", "d", "e", "f", "g", "j", "k", "l", "m", "n", "p")),
      paste0("r_blck", 1:3), paste0("eblock_ord_", 1:3)
    )
    knowledge <- grepl("^(e|t_e)([1-9]|1[0-2])($|_)", available) |
      grepl("^kne([1-9]|1[0-2])([a-d]|wDK|[a-d]wDK)?$", available)
    columns <- c(columns, available[knowledge])
  }
  available[available %in% unique(columns)]
}

project_source_columns <- function(survey, study) {
  columns <- source_projection_columns(study, names(survey))
  stopifnot("caseid" %in% columns, !anyDuplicated(survey$caseid))
  result <- as.data.frame(lapply(survey[columns], as.numeric))
  stopifnot(nrow(result) == nrow(survey), identical(result$caseid, as.numeric(survey$caseid)))
  result
}
