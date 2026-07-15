#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop("Usage: fit-worker.R <library> <output.csv>")
}

library_path <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
output <- args[[2L]]
.libPaths(c(library_path, .libPaths()))
library("boostPM", character.only = TRUE, lib.loc = library_path)

clip_unit_interval <- function(x) {
  pmin(pmax(x, 1e-8), 1 - 1e-8)
}

simulate_scenario <- function(name, n, seed) {
  set.seed(seed)
  if (name == "uniform_2d") {
    return(list(
      train = matrix(stats::runif(n * 2L), ncol = 2L),
      test = matrix(stats::runif(2000L), ncol = 2L),
      mean = c(0.5, 0.5)
    ))
  }
  if (name == "beta_1d") {
    return(list(
      train = matrix(stats::rbeta(n, 2, 5), ncol = 1L),
      test = matrix(stats::rbeta(1000L, 2, 5), ncol = 1L),
      mean = 2 / 7
    ))
  }
  if (name == "gaussian_copula_2d") {
    draw <- function(size) {
      first <- stats::rnorm(size)
      second <- 0.8 * first + sqrt(1 - 0.8^2) * stats::rnorm(size)
      cbind(clip_unit_interval(stats::pnorm(first)),
            clip_unit_interval(stats::pnorm(second)))
    }
    return(list(train = draw(n), test = draw(2000L), mean = c(0.5, 0.5)))
  }
  stop("Unknown scenario: ", name)
}

fit_arguments <- function(data) {
  list(
    data = data,
    add_noise = FALSE,
    Omega = cbind(rep(0, ncol(data)), rep(1, ncol(data))),
    ntree_max_marginal = 5L,
    ntree_max_dependence = 10L,
    c0 = 0.1,
    gamma = 0.5,
    max_resol = 2L,
    min_obs = 10L,
    early_stop = NULL,
    alpha = 0.9,
    beta = 0,
    precision = 1,
    nbins = 8L
  )
}

scenarios <- c("uniform_2d", "beta_1d", "gaussian_copula_2d")
seeds <- c(101L, 202L, 303L)
rows <- vector("list", length(scenarios) * length(seeds))
row <- 0L

for (scenario in scenarios) {
  for (seed in seeds) {
    data <- simulate_scenario(scenario, n = 300L, seed = seed)
    set.seed(10000L + seed)
    invisible(capture.output(
      fit <- do.call(fit_boostpm, fit_arguments(data$train))
    ))

    train_log_density <- stats::predict(fit, data$train, type = "log_density")
    test_log_density <- stats::predict(fit, data$test, type = "log_density")
    set.seed(20000L + seed)
    integration_points <- matrix(
      stats::runif(20000L * ncol(data$train)),
      ncol = ncol(data$train)
    )
    integral_estimate <- mean(exp(
      stats::predict(fit, integration_points, type = "log_density")
    ))
    set.seed(30000L + seed)
    simulated <- stats::simulate(fit, nsim = 2000L)

    if (any(!is.finite(train_log_density)) || any(!is.finite(test_log_density))) {
      stop("Non-finite interior log density in ", scenario, ", seed ", seed)
    }
    if (!is.finite(integral_estimate) || abs(integral_estimate - 1) > 0.20) {
      stop("Monte Carlo normalization check failed in ", scenario, ", seed ", seed)
    }
    if (any(simulated < 0 | simulated > 1)) {
      stop("Simulation left the declared support in ", scenario, ", seed ", seed)
    }

    row <- row + 1L
    rows[[row]] <- data.frame(
      scenario = scenario,
      seed = seed,
      dimension = ncol(data$train),
      train_predictive_score = mean(train_log_density),
      test_predictive_score = mean(test_log_density),
      monte_carlo_integral = integral_estimate,
      simulated_mean_l1_error = sum(abs(colMeans(simulated) - data$mean)),
      stringsAsFactors = FALSE
    )
  }
}

utils::write.csv(do.call(rbind, rows), output, row.names = FALSE)
