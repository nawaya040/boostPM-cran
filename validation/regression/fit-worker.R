#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) {
  stop("Usage: fit-worker.R <library> <original|package> <output.rds>")
}

library_path <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
implementation <- match.arg(args[[2L]], c("original", "package"))
output <- args[[3L]]

.libPaths(c(library_path, .libPaths()))
library("boostPM", character.only = TRUE, lib.loc = library_path)

fixtures <- list(
  univariate = list(
    data = matrix(c(0.10, 0.20, 0.40, 0.60, 0.80, 0.90), ncol = 1L),
    Omega = matrix(c(0, 1), nrow = 1L),
    fit_seed = 314L,
    simulation_seed = 9314L,
    eval_points = matrix(c(0.15, 0.35, 0.55, 0.85), ncol = 1L),
    ntree_max_marginal = 1L,
    ntree_max_dependence = 0L,
    max_resol = 1L,
    min_obs = 2L,
    nbins = 4L
  ),
  two_dimensional = list(
    data = matrix(c(
      0.10, 0.80,
      0.20, 0.70,
      0.30, 0.60,
      0.40, 0.90
    ), ncol = 2L, byrow = TRUE),
    Omega = cbind(c(0, 0), c(1, 1)),
    fit_seed = 20240714L,
    simulation_seed = 920714L,
    eval_points = matrix(c(
      0.15, 0.75,
      0.25, 0.65,
      0.35, 0.85
    ), ncol = 2L, byrow = TRUE),
    ntree_max_marginal = 1L,
    ntree_max_dependence = 1L,
    max_resol = 1L,
    min_obs = 2L,
    nbins = 4L
  ),
  two_dimensional_grid8 = list(
    data = matrix(c(
      0.08, 0.82,
      0.16, 0.71,
      0.27, 0.63,
      0.39, 0.54,
      0.58, 0.35,
      0.69, 0.26,
      0.81, 0.18,
      0.91, 0.09
    ), ncol = 2L, byrow = TRUE),
    Omega = cbind(c(0, 0), c(1, 1)),
    fit_seed = 271828L,
    simulation_seed = 9271828L,
    eval_points = matrix(c(
      0.12, 0.78,
      0.33, 0.57,
      0.61, 0.32,
      0.87, 0.13
    ), ncol = 2L, byrow = TRUE),
    ntree_max_marginal = 2L,
    ntree_max_dependence = 2L,
    max_resol = 2L,
    min_obs = 2L,
    nbins = 8L
  )
)

fit_fixture <- function(fixture) {
  fit_arguments <- list(
    data = fixture$data,
    add_noise = FALSE,
    Omega = fixture$Omega,
    ntree_max_marginal = fixture$ntree_max_marginal,
    ntree_max_dependence = fixture$ntree_max_dependence,
    c0 = 0.1,
    gamma = 0,
    max_resol = fixture$max_resol,
    min_obs = fixture$min_obs,
    early_stop = NULL,
    alpha = 0.9,
    beta = 0,
    nbins = fixture$nbins
  )
  if (implementation == "original") {
    fit_arguments$max_n_var <- 100L
  }

  set.seed(fixture$fit_seed)
  fit_function <- if (implementation == "package") fit_boostpm else boosting
  invisible(capture.output(fit <- do.call(fit_function, fit_arguments)))
  fit_rng <- .Random.seed

  density <- if (implementation == "package") {
    stats::predict(fit, fixture$eval_points, type = "details")
  } else {
    eval_density_b(fit, fixture$eval_points)
  }
  set.seed(fixture$simulation_seed)
  simulation <- if (implementation == "package") {
    stats::simulate(fit, nsim = 11L)
  } else {
    simulation_b(fit, 11L)
  }
  simulation_rng <- .Random.seed

  list(
    fit = fit[c(
      "residuals_boosting", "tree_size_store", "max_depth_store",
      "variable_importance", "tree_list", "Omega"
    )],
    density = density,
    simulation = simulation,
    fit_rng = fit_rng,
    simulation_rng = simulation_rng
  )
}

result <- lapply(fixtures, fit_fixture)
saveRDS(result, output)
