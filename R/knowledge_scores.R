alternative_knowledge_scores <- function(respondents, source) {
  stopifnot(!anyDuplicated(respondents$caseid), !anyDuplicated(source$caseid))
  source <- source[match(respondents$caseid, source$caseid), ]
  stopifnot(identical(as.numeric(source$caseid), as.numeric(respondents$caseid)))
  binary_sum <- respondents$pk - respondents$kn_snmajr
  missing_senate <- is.na(source$f2)
  stopifnot(all(respondents$kn_snmajr[missing_senate] == 0))
  strict_caucus <- as.numeric(!is.na(source$f2) & source$f2 == ifelse(source$rk == 1, 51, 49))
  strict_party <- as.numeric(!is.na(source$f2) & source$f2 == 49)
  extra_columns <- c(paste0("e10_", 1:4), "e11", "e12")
  extra_keys <- c(4, 1, 1, 1, 1, 4)
  extra <- vapply(seq_along(extra_columns), function(index) {
    answer <- source[[extra_columns[index]]]
    as.numeric(!is.na(answer) & answer == extra_keys[index])
  }, numeric(nrow(source)))
  checkpoint <- as.matrix(source[c(paste0("kne10", letters[1:4]), "kne11", "kne12")])
  stopifnot(all(extra == checkpoint), all(source$rk %in% 1:2), all(!is.na(respondents$pk)))
  data.frame(
    caseid = respondents$caseid, published = respondents$pk,
    strict_caucus = binary_sum + strict_caucus,
    strict_party = binary_sum + strict_party,
    omit_senate = binary_sum * 13 / 12,
    expanded_items = (respondents$pk + rowSums(extra)) * 13 / 19
  )
}
