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
    max_marginal_trees = 1L,
    max_dependence_trees = 0L,
    max_split_depth = 1L,
    min_node_observations = 2L,
    n_bins = 4L
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
    max_marginal_trees = 1L,
    max_dependence_trees = 1L,
    max_split_depth = 1L,
    min_node_observations = 2L,
    n_bins = 4L
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
    max_marginal_trees = 2L,
    max_dependence_trees = 2L,
    max_split_depth = 2L,
    min_node_observations = 2L,
    n_bins = 8L
  )
)

fit_fixture <- function(fixture) {
  fit_arguments <- list(
    data = fixture$data,
    add_noise = FALSE,
    Omega = fixture$Omega,
    c0 = 0.1,
    gamma = 0,
    early_stop = NULL
  )
  if (implementation == "original") {
    fit_arguments$ntree_max_marginal <- fixture$max_marginal_trees
    fit_arguments$ntree_max_dependence <- fixture$max_dependence_trees
    fit_arguments$max_resol <- fixture$max_split_depth
    fit_arguments$min_obs <- fixture$min_node_observations
    fit_arguments$nbins <- fixture$n_bins
    fit_arguments$alpha <- 0.9
    fit_arguments$beta <- 0
    fit_arguments$max_n_var <- 100L
  } else {
    fit_arguments$max_marginal_trees <- fixture$max_marginal_trees
    fit_arguments$max_dependence_trees <- fixture$max_dependence_trees
    fit_arguments$max_split_depth <- fixture$max_split_depth
    fit_arguments$min_node_observations <- fixture$min_node_observations
    fit_arguments$n_bins <- fixture$n_bins
    fit_arguments$prior_split_prob <- 0.9
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

  normalized_density <- if (implementation == "package") {
    list(
      log_density = density$log_density,
      mean_log_density_path = density$mean_log_density_path
    )
  } else {
    list(
      log_density = density$log_densities,
      mean_log_density_path = density$mean_log_dens_path
    )
  }

  normalized_fit <- if (implementation == "package") {
    list(
      residual_coordinates = fit$residual_coordinates,
      tree_node_counts = fit$tree_diagnostics$node_count,
      tree_depths = fit$tree_diagnostics$max_depth,
      variable_importance = unname(as.numeric(fit$variable_importance)),
      trees = fit$trees,
      support = unname(fit$support)
    )
  } else {
    list(
      residual_coordinates = fit$residuals_boosting,
      tree_node_counts = fit$tree_size_store,
      tree_depths = fit$max_depth_store,
      variable_importance = unname(as.numeric(fit$variable_importance)),
      trees = fit$tree_list,
      support = fit$Omega
    )
  }

  list(
    fit = normalized_fit,
    density = normalized_density,
    simulation = simulation,
    fit_rng = fit_rng,
    simulation_rng = simulation_rng
  )
}

result <- lapply(fixtures, fit_fixture)
saveRDS(result, output)
