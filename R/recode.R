# Legacy names are confined to this reconstruction boundary and its checkpoints.
# Public analysis files use modernize_columns() and the explicit crosswalk.
recode_published <- function(wide) {
  wide <- as.data.frame(lapply(wide, function(column) {
    if (is.numeric(column)) as.numeric(column) else column
  }))
  stopifnot(!anyNA(wide$caseid), !anyDuplicated(wide$caseid))
  stopifnot(all(c("dropout", "r_PIDloc", "h1c") %in% names(wide)))
  wide$complete <- NA_real_
  study_two <- wide$pollid %in% 2008
  wide$complete[study_two] <- as.numeric(!is.na(wide$l5[study_two]))
  wide$dropout[study_two] <- 0
  randomization_marker_observed <-
    (wide$r_PIDloc %in% 0 & !is.na(wide$h1c)) |
    (wide$r_PIDloc %in% 1 & !is.na(wide$pres_app))
  randomized_dropout <- wide$complete %in% 0 & randomization_marker_observed
  wide$dropout[randomized_dropout] <- 1
  wide$dem <- wide$pid7
  wide$dem[wide$pid7 %in% 1:3] <- 0
  wide$dem[wide$pid7 %in% 4] <- NA_real_
  wide$dem[wide$pid7 %in% 5:7] <- 1
  wide$approve <- wide$pres_app
  wide$approve[wide$pres_app %in% 1:2] <- 1
  wide$approve[wide$pres_app %in% 3:4] <- 0
  wide$consis <- NA_real_
  eligible <- wide$pollid == 2008 & wide$dem %in% 0:1 &
    wide$approve %in% 0:1
  wide$consis[eligible] <- as.numeric(
    wide$dem[eligible] != wide$approve[eligible]
  )
  knowledge_items <- c(paste0("e", 1:8), paste0("e9_", 1:4))
  answer_keys <- c(3, 1, 2, 1, 3, 2, 1, 1, 2, 1, 1, 1)
  for (index in seq_along(knowledge_items)) {
    response <- wide[[knowledge_items[index]]]
    score <- response
    score[response %in% c(-1, 1:5)] <- 0
    score[response %in% answer_keys[index]] <- 1
    wide[[paste0("kn", knowledge_items[index])]] <- score
  }
  wide$kn_snmajr <- wide$kn_snmaj
  scored <- wide$kn_snmaj %in% 1:4
  wide$kn_snmajr[scored] <- wide$kn_snmaj[scored] / 4
  wide$pk <- rowSums(wide[c(paste0("kn", knowledge_items), "kn_snmajr")])
  wide$nohispeed <- wide$cu07serv
  wide$nohispeed[wide$cu07serv %in% c(-2, -1)] <- NA_real_
  wide$nohispeed[wide$cu07serv %in% 2:6] <- 0
  wide$nohispeed[wide$cu07serv %in% 1] <- 1
  wide$nohispeed[wide$ppnet %in% 0 & is.na(wide$nohispeed)] <- 1
  wide$nohispeed[wide$inet_sp %in% 0:1] <- 1
  wide$nohispeed[wide$inet_sp %in% 2] <- 0

  item_labels <- c(
    "Debt 2008", "Unemployment 2008", "Uninsured 2008", "Estate Tax 2008",
    "Gas Price 2008", "Unemployment 2004", "Estate Tax 2004", "Debt 2004",
    "Uninsured 2004", "Poverty 2004"
  )
  response_columns <- c(paste0("l", 1:10), paste0("t_l", 1:5))
  long <- do.call(rbind, lapply(1:10, function(item_index) {
    rows <- wide$pollid == if (item_index <= 5) 2008 else 2004
    result <- wide[rows, setdiff(names(wide), response_columns)]
    result$l <- wide[[paste0("l", item_index)]][rows]
    result$t_l <- if (item_index <= 5) {
      wide[[paste0("t_l", item_index)]][rows]
    } else {
      NA_real_
    }
    result$item <- item_labels[item_index]
    result$seq <- item_index
    result
  }))
  long <- long[order(long$caseid, long$seq), ]
  rownames(long) <- NULL
  stopifnot(nrow(long) == 5 * nrow(wide))
  long$l_raw <- readBin(
    writeBin(long$l, raw(), size = 4), "numeric",
    n = nrow(long), size = 4
  )
  long$l[which(long$l < 0)] <- NA_real_
  gas_cents <- which(long$seq == 5 & long$l >= 100)
  long$l[gas_cents] <- long$l[gas_cents] / 100
  long$l[which(long$seq %in% c(3, 9) & long$l > 100)] <- NA_real_
  for (window in c("33", "23", "10", "po", "pp")) {
    long[[paste0("tri_", window)]] <- classify_responses(
      long$l, long$seq, window
    )
    if (window != "pp") {
      direction <- ifelse(long$seq %in% c(4, 7), -1, 1)
      long[[paste0("cong_", window)]] <-
        (long[[paste0("tri_", window)]] - 1) * (2 * long$dem - 1) * direction
    }
  }
  long$cong_33r <- -long$cong_33
  long$congenial <- as.numeric(long$cong_33 == 1)
  long$correct <- as.numeric(long$cong_33 == 0)
  long$uncongenial <- as.numeric(long$cong_33 == -1)
  long$pay <- ifelse(long$rd %in% c(0, 2), long$rd / 2, NA_real_)
  for (treatment in c("app", "mon", "acc")) {
    treated <- switch(treatment,
      app = 1,
      mon = 2,
      acc = 1:2
    )
    long[[treatment]] <- ifelse(
      long$pollid == 2008 & long$rd %in% 0:2,
      as.numeric(long$rd %in% treated), NA_real_
    )
  }
  for (item_index in 1:9) {
    long[[paste0("seq", item_index)]] <- as.numeric(long$seq == item_index)
  }
  interactions <- list(
    monxbush = c("mon", "r_bushref"), appxbush = c("app", "r_bushref"),
    accxbush = c("acc", "r_bushref"), payxnohs = c("pay", "nohispeed"),
    monxnohs = c("mon", "nohispeed"), appxnohs = c("app", "nohispeed"),
    monxpk = c("mon", "pk"), appxpk = c("app", "pk"), accxpk = c("acc", "pk"),
    bushxpk = c("r_bushref", "pk"), accxbushxpk = c("acc", "r_bushref", "pk")
  )
  for (interaction in names(interactions)) {
    long[[interaction]] <- Reduce(`*`, long[interactions[[interaction]]])
  }
  list(wide = wide, long = long)
}

classify_responses <- function(response, item_index, window = "33") {
  windows <- list(
    "33" = c(4.2, 5.4, 12.6, 19, 3.22, 3.32, 2, 29.2, 4.5, 20.5),
    "23" = c(4.6, 5, 13.59, 17, 3.25, 3.29, 6.6, 24.6, 6.5, 18.5),
    "10" = c(4.32, 5.28, 14.22, 17.38, 2.943, 3.597, 14.04, 17.16, 11.25, 13.75),
    "po" = c(3.8, 5.8, 14.8, 16.8, 3.17, 3.37, 12.6, 18.6, 9.5, 15.5),
    "pp" = c(3.8, 5.8, 14.8, 16.8, 3.17, 3.27, 14.6, 16.6, 11.5, 13.5)
  )
  stopifnot(window %in% names(windows), length(response) == length(item_index))
  score <- rep(NA_real_, length(response))
  debt <- item_index %in% c(1, 8)
  estate <- item_index %in% c(4, 7)
  unemployment <- item_index == 6
  score[which(debt & response <= 4)] <- 0
  score[which(debt & response == 5)] <- 1
  score[which(debt & response >= 6)] <- 2
  score[which(estate & response == 1)] <- 1
  score[which(estate & response >= 2)] <- 2
  score[which(unemployment & response == 1)] <- 0
  score[which(unemployment & response == 2)] <- 1
  score[which(unemployment & response >= 3)] <- 2
  continuous_items <- c(2, 3, 5, 9, 10)
  bounds <- matrix(windows[[window]], ncol = 2, byrow = TRUE)
  for (index in seq_along(continuous_items)) {
    selected <- item_index == continuous_items[index]
    score[which(selected & response < bounds[index, 1])] <- 0
    in_window <- selected & response >= bounds[index, 1] &
      response <= bounds[index, 2]
    score[which(in_window)] <- 1
    score[which(selected & response > bounds[index, 2])] <- 2
  }
  score
}

recode_name_crosswalk <- function() {
  mapping <- c(
    caseid = "respondent_id", pollid = "study_year", rd = "treatment_arm",
    pid7 = "party_identification", pres_app = "presidential_approval_raw",
    dem = "is_democrat", approve = "approves_president", consis = "is_consistent_partisan",
    pk = "knowledge_score", kn_snmaj = "senate_majority_raw",
    kn_snmajr = "senate_majority_score", nohispeed = "has_no_high_speed_internet",
    r_bushref = "has_bush_reference", l = "response", l_raw = "response_raw",
    t_l = "response_time_seconds", seq = "item_id", item = "item_label",
    pay = "monetary_pooled", app = "accuracy_appeal", mon = "monetary_incentive",
    acc = "accuracy_incentive", congenial = "is_congenial", correct = "is_correct",
    uncongenial = "is_uncongenial", cong_33r = "congeniality_33_reversed",
    t_disp = "screen_time_seconds", dropout = "dropped_out_after_randomization",
    r_PIDloc = "party_identification_before_items", h1c = "numeracy_disease_response",
    complete = "is_complete", ppnet = "household_internet_access_raw",
    cu07serv = "household_internet_service_raw", inet_sp = "internet_speed_raw",
    monxbush = "monetary_by_bush", appxbush = "appeal_by_bush",
    accxbush = "accuracy_by_bush", payxnohs = "monetary_pooled_by_internet",
    monxnohs = "monetary_by_internet", appxnohs = "appeal_by_internet",
    monxpk = "monetary_by_knowledge", appxpk = "appeal_by_knowledge",
    accxpk = "accuracy_by_knowledge", bushxpk = "bush_by_knowledge",
    accxbushxpk = "accuracy_by_bush_by_knowledge"
  )
  for (window in c("33", "23", "10", "po", "pp")) {
    mapping[paste0("tri_", window)] <- paste0("response_category_", window)
    if (window != "pp") {
      mapping[paste0("cong_", window)] <- paste0("congeniality_", window)
    }
  }
  for (index in 1:9) mapping[paste0("seq", index)] <- paste0("is_item_", index)
  knowledge_items <- c(paste0("e", 1:8), paste0("e9_", 1:4))
  for (index in seq_along(knowledge_items)) {
    mapping[knowledge_items[index]] <- paste0("knowledge_response_", index)
    mapping[paste0("kn", knowledge_items[index])] <- paste0("knowledge_score_", index)
  }
  for (index in 1:10) mapping[paste0("l", index)] <- paste0("response_", index)
  for (index in 1:5) {
    mapping[paste0("t_l", index)] <- paste0("response_time_seconds_", index)
  }
  data.frame(legacy_name = names(mapping), modern_name = unname(mapping))
}

modernize_columns <- function(responses) {
  crosswalk <- recode_name_crosswalk()
  position <- match(names(responses), crosswalk$legacy_name)
  renamed <- !is.na(position)
  names(responses)[renamed] <- crosswalk$modern_name[position[renamed]]
  stopifnot(!anyDuplicated(names(responses)))
  responses
}

compare_recode_checkpoint <- function(reconstructed, released, keys) {
  stopifnot(setequal(names(reconstructed), names(released)))
  reconstructed <- reconstructed[do.call(order, reconstructed[keys]), ]
  released <- released[do.call(order, released[keys]), ]
  stopifnot(nrow(reconstructed) == nrow(released))
  stopifnot(identical(
    unname(as.matrix(reconstructed[keys])), unname(as.matrix(released[keys]))
  ))
  do.call(rbind, lapply(names(released), function(column) {
    expected <- released[[column]]
    observed <- reconstructed[[column]]
    if (is.null(observed)) {
      return(data.frame(
        column = column, missing_mismatches = nrow(released),
        value_mismatches = NA_integer_, max_difference = NA_real_
      ))
    }
    missing_mismatches <- sum(is.na(expected) != is.na(observed))
    present <- !is.na(expected) & !is.na(observed)
    value_mismatches <- sum(expected[present] != observed[present])
    difference <- if (is.numeric(expected) && any(present)) {
      max(abs(expected[present] - observed[present]))
    } else {
      NA_real_
    }
    data.frame(
      column = column, missing_mismatches = missing_mismatches,
      value_mismatches = value_mismatches, max_difference = difference
    )
  }))
}
