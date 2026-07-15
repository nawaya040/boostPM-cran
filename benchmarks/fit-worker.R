#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) {
  stop("Usage: fit-worker.R LIBRARY LABEL OUTPUT")
}

library_path <- normalizePath(args[[1L]], mustWork = TRUE)
label <- args[[2L]]
output <- args[[3L]]
.libPaths(c(library_path, .libPaths()))
suppressPackageStartupMessages(library(boostPM))

cases <- list(
  list(name = "n1000_d2_b8", n = 1000L, d = 2L, nbins = 8L,
       marginal = 5L, dependence = 10L, repetitions = 10L,
       inner_iterations = 50L),
  list(name = "n5000_d2_b8", n = 5000L, d = 2L, nbins = 8L,
       marginal = 5L, dependence = 10L, repetitions = 10L,
       inner_iterations = 20L),
  list(name = "n5000_d2_b100", n = 5000L, d = 2L, nbins = 100L,
       marginal = 5L, dependence = 10L, repetitions = 10L,
       inner_iterations = 10L),
  list(name = "n2000_d5_b100", n = 2000L, d = 5L, nbins = 100L,
       marginal = 3L, dependence = 10L, repetitions = 10L,
       inner_iterations = 10L)
)

fit_once <- function(case, data, seed) {
  arguments <- list(
    data = data,
    add_noise = FALSE,
    Omega = cbind(rep(0, case$d), rep(1, case$d)),
    ntree_max_marginal = case$marginal,
    ntree_max_dependence = case$dependence,
    c0 = 0.1,
    gamma = 0.1,
    max_resol = 5,
    min_obs = 5,
    early_stop = NULL,
    alpha = 0.9,
    beta = 0,
    precision = 1,
    nbins = case$nbins
  )
  if ("max_n_var" %in% names(formals(boostPM::boosting))) {
    arguments$max_n_var <- case$d
  }

  set.seed(seed)
  invisible(utils::capture.output(
    fit <- do.call(boostPM::boosting, arguments)
  ))
  fit
}

rows <- list()
row <- 0L
for (case in cases) {
  set.seed(7000L + case$n + case$d + case$nbins)
  data <- matrix(
    stats::runif(case$n * case$d, min = 0.01, max = 0.99),
    nrow = case$n,
    ncol = case$d
  )

  invisible(fit_once(case, data, 8000L))
  for (repetition in seq_len(case$repetitions)) {
    start <- proc.time()[["elapsed"]]
    checksums <- character(case$inner_iterations)
    for (iteration in seq_len(case$inner_iterations)) {
      seed <- 900000L + case$n + 1000L * repetition + iteration
      fit <- fit_once(case, data, seed)
      checksums[[iteration]] <- paste(
        sprintf("%.17g", sum(fit$residuals_boosting)),
        sprintf("%.17g", sum(fit$variable_importance)),
        length(fit$tree_list),
        sep = ":"
      )
    }
    elapsed <-
      (proc.time()[["elapsed"]] - start) / case$inner_iterations

    row <- row + 1L
    rows[[row]] <- data.frame(
      implementation = label,
      case = case$name,
      n = case$n,
      d = case$d,
      nbins = case$nbins,
      marginal_trees = case$marginal,
      dependence_trees = case$dependence,
      repetition = repetition,
      inner_iterations = case$inner_iterations,
      elapsed_seconds = elapsed,
      checksum = paste(checksums, collapse = "|"),
      stringsAsFactors = FALSE
    )
  }
}

result <- do.call(rbind, rows)
dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
utils::write.csv(result, output, row.names = FALSE)
