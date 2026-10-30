assemble_jags_inputs <- function(responses, study = c("pooled", "study_2")) {
  study <- match.arg(study)
  if (study == "pooled") {
    selected <- (is.na(responses$r_bushref) | responses$r_bushref == 0) &
      !is.na(responses$cong_33) & !is.na(responses$pay)
    predictors <- c("pay", paste0("seq", 1:9))
    conditions <- c("control", "monetary")
    condition_codes <- c(0, 2)
  } else {
    selected <- responses$pollid == 2008 & responses$r_bushref %in% 0 &
      !is.na(responses$cong_33) & responses$seq %in% 1:5
    predictors <- c("app", "mon", paste0("seq", 1:4))
    conditions <- c("control", "accuracy_appeal", "monetary")
    condition_codes <- 0:2
  }
  sample <- responses[which(selected), , drop = FALSE]
  design <- as.matrix(sample[predictors])
  stopifnot(nrow(sample) > 0, !anyNA(design), !anyNA(sample$caseid))
  stopifnot(all(sample$cong_33 %in% -1:1))
  stopifnot(all(sample$rd %in% condition_codes))
  respondent_ids <- unique(sample$caseid)
  inputs <- list(
    y = as.integer(sample$cong_33 + 2), x = design,
    N = nrow(sample), NID = length(respondent_ids),
    b0 = rep(0, ncol(design)), B0 = diag(1e-8, ncol(design)),
    id = match(sample$caseid, respondent_ids)
  )
  for (index in seq_along(conditions)) {
    membership <- as.numeric(sample$rd == condition_codes[index])
    stopifnot(sum(membership) > 0)
    inputs[[paste0("weight_", conditions[index])]] <- membership / sum(membership)
  }
  list(
    data = inputs, sample = sample, predictors = predictors,
    conditions = conditions, study = study
  )
}

build_jags_model <- function(model_path, conditions, noncentered = TRUE) {
  model_text <- paste(readLines(model_path, warn = FALSE), collapse = "\n")
  stopifnot(grepl("}\\s*$", model_text))
  if (noncentered) {
    centered_prior <- "eta[k] ~ dnorm(0.0,eta.tau)"
    stopifnot(grepl(centered_prior, model_text, fixed = TRUE))
    model_text <- sub(
      centered_prior, "z[k] ~ dnorm(0, 1)\n          eta[k] <- sigma * z[k]",
      model_text,
      fixed = TRUE
    )
  }
  summaries <- unlist(lapply(conditions, function(condition) {
    vapply(seq_along(c("uncongenial", "correct", "congenial")), function(index) {
      outcome <- c("uncongenial", "correct", "congenial")[index]
      sprintf(
        "  probability_%s_%s <- inprod(p[1:N,%d], weight_%s[1:N])",
        condition, outcome, index, condition
      )
    }, character(1))
  }))
  sub("}\\s*$", paste0(paste(summaries, collapse = "\n"), "\n}"), model_text)
}

fit_jags_replication <- function(assembled, model_path, seed = 123456L,
                                 chains = 4L, adaptation = 5000L,
                                 burn_in = 10000L, iterations = 12500L,
                                 thin = 10L, checkpoint_dir = NULL,
                                 noncentered = TRUE) {
  stopifnot(chains >= 2, adaptation > 0, burn_in > 0, iterations >= thin)
  model_text <- build_jags_model(model_path, assembled$conditions, noncentered)
  initial_beta <- stats::lm.fit(
    cbind(1, assembled$data$x), assembled$data$y
  )$coefficients[-1]
  stopifnot(all(is.finite(initial_beta)))
  probability_nodes <- unlist(lapply(assembled$conditions, function(condition) {
    paste0("probability_", condition, "_", c("uncongenial", "correct", "congenial"))
  }))
  if (!is.null(checkpoint_dir)) {
    dir.create(checkpoint_dir, recursive = TRUE, showWarnings = FALSE)
  }
  run_chain <- function(chain) {
    connection <- textConnection(model_text)
    on.exit(close(connection))
    initial_values <- list(
      beta = unname(initial_beta) + (chain - (chains + 1) / 2) * 0.1,
      tau0 = c(2, 3) + (chain - (chains + 1) / 2) * 0.1,
      sigma = 0.2 + chain * 1.5 / (chains + 1),
      .RNG.name = "base::Mersenne-Twister", .RNG.seed = seed + chain
    )
    model <- rjags::jags.model(
      connection,
      data = assembled$data, inits = initial_values,
      n.chains = 1, n.adapt = 0, quiet = TRUE
    )
    label <- paste(assembled$study, "chain", chain)
    message(label, ": adapting for ", adaptation, " iterations")
    adapted <- rjags::adapt(model, n.iter = adaptation, end.adaptation = TRUE)
    if (!adapted) stop("JAGS adaptation incomplete; increase adaptation iterations.")
    message(label, ": discarding ", burn_in, " burn-in iterations")
    stats::update(model, n.iter = burn_in, progress.bar = "none")
    message(label, ": sampling ", iterations, " iterations")
    draws <- rjags::coda.samples(
      model,
      variable.names = c("beta", "tau", "sigma", probability_nodes),
      n.iter = iterations, thin = thin, progress.bar = "none"
    )[[1]]
    state <- model$state(internal = TRUE)[[1]]
    result <- list(draws = draws, state = state)
    if (!is.null(checkpoint_dir)) {
      saveRDS(result, file.path(checkpoint_dir, paste0("chain_", chain, ".rds")))
    }
    message(label, ": completed")
    result
  }
  cores <- if (.Platform$OS.type == "windows") 1L else chains
  chain_draws <- parallel::mclapply(
    seq_len(chains), run_chain,
    mc.cores = cores, mc.set.seed = FALSE
  )
  valid <- vapply(chain_draws, function(chain) {
    is.list(chain) && inherits(chain$draws, "mcmc")
  }, logical(1))
  if (!all(valid)) stop("One or more JAGS chains failed: ", paste(which(!valid), collapse = ", "))
  states <- lapply(chain_draws, `[[`, "state")
  draws <- coda::mcmc.list(lapply(chain_draws, `[[`, "draws"))
  summary <- summarize_jags_draws(draws)
  list(
    draws = draws, states = states, summary = summary, study = assembled$study,
    input_digest = digest::digest(assembled$data, algo = "sha256"),
    predictors = assembled$predictors, conditions = assembled$conditions,
    observations = assembled$data$N, respondents = assembled$data$NID,
    settings = list(
      seed = seed, chains = chains, adaptation = adaptation,
      burn_in = burn_in, iterations = iterations, total_iterations = iterations * chains,
      thin = thin, cores = cores,
      parameterization = if (noncentered) "noncentered" else "centered"
    ),
    model_text = model_text
  )
}

check_jags_convergence <- function(summary) {
  all(is.finite(summary$r_hat)) && all(summary$r_hat < 1.01) &&
    all(is.finite(summary$effective_size)) && all(summary$effective_size >= 400)
}

summarize_jags_draws <- function(draws) {
  samples <- as.matrix(coda::as.mcmc.list(draws))
  diagnostics <- coda::gelman.diag(
    draws,
    autoburnin = FALSE, multivariate = FALSE
  )$psrf
  effective_size <- coda::effectiveSize(draws)
  quantiles <- t(apply(samples, 2, stats::quantile, c(0.025, 0.05, 0.95, 0.975)))
  standard_deviation <- apply(samples, 2, stats::sd)
  data.frame(
    parameter = colnames(samples), mean = colMeans(samples),
    standard_deviation = standard_deviation,
    lower_95 = quantiles[, 1], lower_90 = quantiles[, 2],
    upper_90 = quantiles[, 3], upper_95 = quantiles[, 4],
    effective_size = unname(effective_size[colnames(samples)]),
    monte_carlo_se = standard_deviation / sqrt(effective_size[colnames(samples)]),
    r_hat = diagnostics[colnames(samples), 1],
    r_hat_upper = diagnostics[colnames(samples), 2], row.names = NULL
  )
}

extract_jags_probabilities <- function(fit) {
  do.call(rbind, lapply(fit$conditions, function(condition) {
    do.call(rbind, lapply(c("uncongenial", "correct", "congenial"), function(outcome) {
      node <- paste0("probability_", condition, "_", outcome)
      result <- fit$summary[match(node, fit$summary$parameter), , drop = FALSE]
      stopifnot(nrow(result) == 1, !is.na(result$parameter))
      result$study <- fit$study
      result$condition <- condition
      result$outcome <- outcome
      result$observations <- fit$observations
      result$respondents <- fit$respondents
      result
    }))
  }))
}

compare_jags_probabilities <- function(probabilities, published, study) {
  old_conditions <- c(control = "control", acc = "accuracy_appeal", monetary = "monetary")
  do.call(rbind, lapply(seq_len(nrow(published)), function(index) {
    condition <- unname(old_conditions[published$cond[index]])
    do.call(rbind, lapply(c("uncongenial", "congenial"), function(outcome) {
      row <- probabilities[
        probabilities$study == study & probabilities$condition == condition &
          probabilities$outcome == outcome, ,
        drop = FALSE
      ]
      stopifnot(nrow(row) == 1)
      prefix <- if (outcome == "uncongenial") "c" else "u"
      old_mean <- published[[if (outcome == "uncongenial") "mean.uncong" else "mean.cong"]][index]
      data.frame(
        study = study, condition = condition, outcome = outcome,
        released_mean = old_mean, reproduced_mean = row$mean,
        difference = row$mean - old_mean,
        reproduced_monte_carlo_se = row$monte_carlo_se,
        released_lower_95 = published[[paste0(prefix, "q025")]][index],
        reproduced_lower_95 = row$lower_95,
        released_upper_95 = published[[paste0(prefix, "q975")]][index],
        reproduced_upper_95 = row$upper_95
      )
    }))
  }))
}

concatenate_jags_chain <- function(previous, extension) {
  stopifnot(setequal(colnames(previous), colnames(extension)))
  extension <- extension[, colnames(previous), drop = FALSE]
  stopifnot(coda::thin(previous) == coda::thin(extension))
  coda::mcmc(
    rbind(as.matrix(previous), as.matrix(extension)),
    start = stats::start(previous), thin = coda::thin(previous)
  )
}

continue_jags_replication <- function(fit, assembled, iterations = 5000L) {
  stopifnot(identical(fit$input_digest, digest::digest(assembled$data, algo = "sha256")))
  stopifnot(fit$study == assembled$study, fit$observations == assembled$data$N)
  stopifnot(fit$respondents == assembled$data$NID)
  stopifnot(identical(fit$predictors, assembled$predictors))
  stopifnot(length(fit$states) == fit$settings$chains)
  run_extension <- function(chain) {
    connection <- textConnection(fit$model_text)
    on.exit(close(connection))
    model <- rjags::jags.model(
      connection,
      data = assembled$data, inits = fit$states[[chain]],
      n.chains = 1, n.adapt = 0, quiet = TRUE
    )
    label <- paste(fit$study, "chain", chain, "extension")
    message(label, ": restoring state and adapting")
    adaptation <- 0L
    repeat {
      adapted <- rjags::adapt(model, n.iter = 1000L, end.adaptation = FALSE)
      adaptation <- adaptation + 1000L
      if (adapted) break
      if (adaptation >= 5000L) stop("Continuation adaptation failed for ", label)
    }
    rjags::adapt(model, n.iter = 1L, end.adaptation = TRUE)
    adaptation <- adaptation + 1L
    message(label, ": sampling ", iterations, " additional iterations")
    draws <- rjags::coda.samples(
      model,
      variable.names = unique(sub("\\[.*$", "", colnames(fit$draws[[chain]]))),
      n.iter = iterations, thin = fit$settings$thin, progress.bar = "none"
    )[[1]]
    result <- list(draws = draws, state = model$state(internal = TRUE)[[1]], adaptation = adaptation)
    checkpoint_dir <- file.path(
      "data/build", paste0("jags_", fit$study, "_extensions"),
      paste0("iterations_", fit$settings$iterations + iterations)
    )
    dir.create(checkpoint_dir, recursive = TRUE, showWarnings = FALSE)
    saveRDS(result, file.path(checkpoint_dir, paste0("chain_", chain, ".rds")))
    result
  }
  extensions <- parallel::mclapply(
    seq_len(fit$settings$chains), run_extension,
    mc.cores = if (.Platform$OS.type == "windows") 1L else fit$settings$chains,
    mc.set.seed = FALSE
  )
  valid <- vapply(extensions, function(extension) {
    is.list(extension) && inherits(extension$draws, "mcmc")
  }, logical(1))
  if (!all(valid)) stop("JAGS extension failed in chains ", paste(which(!valid), collapse = ", "))
  fit$draws <- coda::mcmc.list(lapply(seq_along(extensions), function(chain) {
    concatenate_jags_chain(fit$draws[[chain]], extensions[[chain]]$draws)
  }))
  fit$states <- lapply(extensions, `[[`, "state")
  fit$summary <- summarize_jags_draws(fit$draws)
  fit$settings$extensions <- c(fit$settings$extensions, list(list(
    iterations = iterations, adaptation = vapply(extensions, `[[`, integer(1), "adaptation")
  )))
  fit$settings$iterations <- fit$settings$iterations + iterations
  fit$settings$total_iterations <- fit$settings$iterations * fit$settings$chains
  fit
}

run_jags_study <- function(assembled, model_path, fit = NULL) {
  study <- assembled$study
  if (!is.null(fit)) {
    stopifnot(identical(fit$input_digest, digest::digest(assembled$data, algo = "sha256")))
  }
  if (is.null(fit)) {
    fit <- fit_jags_replication(
      assembled, model_path,
      checkpoint_dir = file.path("data/build", paste0("jags_", study, "_chains"))
    )
  }
  repeat {
    saveRDS(fit, file.path("data/build", paste0("jags_", study, ".rds")))
    readr::write_csv(fit$summary, paste0("tabs/jags_diagnostics_", study, ".csv"))
    if (check_jags_convergence(fit$summary)) {
      return(fit)
    }
    if (fit$settings$iterations >= 100000L) stop("JAGS convergence gate failed for ", study)
    additional_iterations <- min(5000L, 100000L - fit$settings$iterations)
    message(study, ": extending saved chains by ", additional_iterations, " iterations each")
    fit <- continue_jags_replication(fit, assembled, iterations = additional_iterations)
  }
}

write_jags_outputs <- function(fits, published_path = "data/raw/final_bundle") {
  stopifnot(all(vapply(fits, function(fit) check_jags_convergence(fit$summary), logical(1))))
  probabilities <- lapply(fits, extract_jags_probabilities)
  comparisons <- lapply(names(fits), function(study) {
    source_study <- if (study == "pooled") "study12" else "study2"
    published <- readr::read_csv(file.path(
      published_path, paste0(source_study, "jagsresults.csv")
    ), show_col_types = FALSE)
    compare_jags_probabilities(probabilities[[study]], published, study)
  })
  diagnostics <- lapply(fits, function(fit) {
    result <- fit$summary
    result$study <- fit$study
    result
  })
  readr::write_csv(do.call(rbind, probabilities), "tabs/figure_1_jags_probabilities.csv")
  readr::write_csv(do.call(rbind, comparisons), "tabs/jags_released_comparison.csv")
  readr::write_csv(do.call(rbind, diagnostics), "tabs/jags_diagnostics.csv")
  settings <- lapply(fits, function(fit) {
    extension_details <- vapply(fit$settings$extensions, function(extension) {
      paste0(
        extension$iterations, " sampling iterations per chain; adaptation: ",
        paste(extension$adaptation, collapse = ",")
      )
    }, character(1))
    data.frame(
      study = fit$study, chains = fit$settings$chains,
      adaptation = fit$settings$adaptation, burn_in = fit$settings$burn_in,
      sampling_iterations_per_chain = fit$settings$iterations,
      total_sampling_iterations = fit$settings$total_iterations,
      thin = fit$settings$thin, parameterization = fit$settings$parameterization,
      seed = fit$settings$seed, input_digest = fit$input_digest,
      continuation_count = length(extension_details),
      continuation_details = paste(extension_details, collapse = "; ")
    )
  })
  readr::write_csv(do.call(rbind, settings), "tabs/jags_run_settings.csv")
}
