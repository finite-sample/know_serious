response_statistics <- function(responses, group_column) {
  groups <- sort(unique(responses[[group_column]]))
  result <- unlist(lapply(groups, function(group) {
    selected <- responses[which(responses[[group_column]] == group), ]
    shares <- vapply(c(-1, 0, 1), function(value) {
      mean(selected$cong_33 == value, na.rm = TRUE)
    }, numeric(1))
    setNames(
      c(shares, shares[3] - shares[1]),
      paste0("group_", group, "_", c("uncongenial", "correct", "congenial", "bias"))
    )
  }))
  for (group in groups[groups != 0]) {
    for (measure in c("uncongenial", "correct", "congenial", "bias")) {
      treated <- result[paste0("group_", group, "_", measure)]
      control <- result[paste0("group_0_", measure)]
      result[paste0("contrast_", group, "_", measure)] <- unname(treated - control)
    }
  }
  result
}

bootstrap_responses <- function(responses, group_column, replicates = 1000L, seed = 123456L,
                                analysis_rows = rep(TRUE, nrow(responses))) {
  clusters <- split(seq_len(nrow(responses)), responses$caseid)
  responses$analysis_row <- analysis_rows
  estimate <- response_statistics(responses[which(responses$analysis_row), ], group_column)
  set.seed(seed)
  draws <- replicate(replicates, {
    selected <- sample.int(length(clusters), length(clusters), replace = TRUE)
    resampled <- responses[unlist(clusters[selected]), ]
    response_statistics(resampled[which(resampled$analysis_row), ], group_column)[names(estimate)]
  })
  data.frame(
    statistic = names(estimate), estimate = unname(estimate),
    standard_error = apply(draws, 1, sd), replicates = replicates,
    bootstrap_frame_respondents = length(clusters), bootstrap_frame_responses = nrow(responses)
  )
}

summarize_table_one <- function(responses, replicates = 1000L) {
  selected <- list(
    pooled = responses$r_bushref == 0 & !is.na(responses$pay),
    study_2004 = responses$pollid == 2004,
    study_2008 = responses$pollid == 2008 & responses$r_bushref == 0
  )
  do.call(rbind, lapply(names(selected), function(study) {
    selection <- selected[[study]] %in% TRUE
    group_column <- if (study == "study_2008") "rd" else "pay"
    result <- bootstrap_responses(responses, group_column,
      replicates = replicates, analysis_rows = selection
    )
    result$sampling_frame <- "full long file; rclass wrapper assumption"
    groups <- sort(unique(responses[[group_column]][selection]))
    for (group in groups) {
      frame <- responses[which(selection & responses[[group_column]] == group), ]
      clusters <- split(seq_len(nrow(frame)), frame$caseid)
      for (value in -1:1) {
        set.seed(123456L)
        draws <- replicate(replicates, {
          sampled <- sample.int(length(clusters), length(clusters), replace = TRUE)
          mean(frame$cong_33[unlist(clusters[sampled])] == value, na.rm = TRUE)
        })
        name <- paste0("group_", group, "_", c("uncongenial", "correct", "congenial")[value + 2])
        row <- match(name, result$statistic)
        result$standard_error[row] <- sd(draws)
        result$bootstrap_frame_respondents[row] <- length(clusters)
        result$bootstrap_frame_responses[row] <- nrow(frame)
        result$sampling_frame[row] <- "if-qualified arm; missing outcomes retained in frame"
      }
    }
    cbind(study = study, result)
  }))
}

cluster_delta_standard_errors <- function(responses, group_column) {
  estimates <- response_statistics(responses, group_column)
  groups <- sort(unique(responses[[group_column]]))
  clusters <- unique(responses$caseid)
  scores <- list()
  for (group in groups) {
    valid <- which(responses[[group_column]] == group & !is.na(responses$cong_33))
    stopifnot(length(valid) > 0)
    for (measure in c("uncongenial", "correct", "congenial", "bias")) {
      name <- paste0("group_", group, "_", measure)
      values <- switch(measure,
        uncongenial = responses$cong_33[valid] == -1,
        correct = responses$cong_33[valid] == 0,
        congenial = responses$cong_33[valid] == 1,
        bias = responses$cong_33[valid]
      )
      contributions <- numeric(nrow(responses))
      contributions[valid] <- (values - estimates[name]) / length(valid)
      scores[[name]] <- as.numeric(rowsum(contributions, responses$caseid))
    }
  }
  for (group in groups[groups != 0]) {
    for (measure in c("uncongenial", "correct", "congenial", "bias")) {
      scores[[paste0("contrast_", group, "_", measure)]] <-
        scores[[paste0("group_", group, "_", measure)]] - scores[[paste0("group_0_", measure)]]
    }
  }
  correction <- length(clusters) / (length(clusters) - 1)
  vapply(scores, function(score) sqrt(correction * sum(score^2)), numeric(1))
}
