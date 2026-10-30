compare_upstream <- function(candidate, reference) {
  stopifnot(!anyDuplicated(candidate$caseid), !anyDuplicated(reference$caseid))
  stopifnot(setequal(candidate$caseid, reference$caseid))
  candidate <- candidate[match(reference$caseid, candidate$caseid), ]
  do.call(rbind, lapply(names(reference), function(column) {
    actual <- candidate[[column]]
    expected <- reference[[column]]
    equal <- (is.na(actual) & is.na(expected)) |
      (!is.na(actual) & !is.na(expected) & actual == expected)
    data.frame(
      variable = column, observations = length(equal),
      mismatches = sum(!equal)
    )
  }))
}

reconstruct_upstream <- function(survey_2004, survey_2008) {
  columns <- c(
    "caseid", "rd", paste0("e", 1:8), paste0("e9_", 1:4),
    "h1c", paste0("l", 1:5), "ppnet", "cu07serv", "t_l3", "t_l1", "t_l2", "t_l4",
    "t_l5", "pid7", "r_PIDloc", "r_bushref", "kn_snmaj", "pollid", "t_disp",
    "pres_app", "inet_sp", "dropout", paste0("l", 6:10)
  )
  empty_frame <- function(rows) {
    as.data.frame(setNames(rep(list(rep(NA_real_, rows)), length(columns)), columns))
  }
  selected <- survey_2004[survey_2004$ex_group %in% c(1, 3), ]
  first <- empty_frame(nrow(selected))
  for (column in c("caseid", "pid7", "inet_sp")) {
    first[[column]] <- as.numeric(selected[[column]])
  }
  first$dropout <- as.numeric(selected$incomp)
  first$caseid <- first$caseid + 10000
  first$pollid <- 2004
  first$rd <- ifelse(selected$ex_group == 3, 2, 0)
  first$r_bushref <- 0
  reverse_options <- function(response) ifelse(response > 0, 6 - response, response)
  first$l6 <- reverse_options(as.numeric(selected$q13))
  first$l7 <- reverse_options(as.numeric(selected$q14))
  first$l8 <- as.numeric(selected$q16)
  first$l9 <- as.numeric(selected$q15)
  first$l10 <- as.numeric(selected$q18)

  second <- empty_frame(nrow(survey_2008))
  for (column in intersect(columns, names(survey_2008))) {
    second[[column]] <- as.numeric(survey_2008[[column]])
  }
  second$pollid <- 2008
  outside_gas_range <- !is.na(second$l5) & (second$l5 < 0 | second$l5 > 500)
  second$l5[outside_gas_range] <- NA_real_
  for (column in c(paste0("e", 1:8), paste0("e9_", 1:4), paste0("l", 1:5))) {
    timer <- if (grepl("^e9_", column)) "t_e9" else paste0("t_", column)
    observed <- !is.na(survey_2008[[timer]])
    if (grepl("^e9_", column)) observed <- observed & survey_2008[[timer]] > 0
    second[[column]][is.na(second[[column]]) & observed] <- -1
  }
  second$pres_app <- as.numeric(survey_2008$k3a)
  missing_approval <- is.na(second$pres_app)
  second$pres_app[missing_approval] <- as.numeric(survey_2008$m1_1[missing_approval])
  timers <- as.data.frame(survey_2008[c("t_disp1", "t_disp2", "t_disp3")])
  second$t_disp <- rowSums(timers, na.rm = TRUE)
  second$t_disp[rowSums(!is.na(timers)) == 0] <- NA_real_
  second$dropout <- NA_real_
  rbind(first, second)
}
