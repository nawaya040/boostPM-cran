#' Simulate from a Fitted boostPM Distribution
#'
#' Draws samples from the probability distribution represented by a fitted
#' tree ensemble.
#'
#' @param object A fitted object returned by [fit_boostpm()].
#' @param nsim Non-negative integer. Number of observations to simulate.
#' @param seed Either `NULL`, or a non-negative integer used to set R's random
#'   number generator immediately before simulation.
#' @param ... Unused. Additional arguments are an error.
#'
#' @return A numeric matrix with `nsim` rows and one column per fitted
#'   variable, in the same order as the training data. Training variable names
#'   are preserved as column names when available. Every draw lies within the
#'   fitted rectangular support.
#'
#' @details
#' With `seed = NULL`, randomness is controlled by calling [set.seed()] before
#' `simulate()`. Supplying `seed` sets R's random-number generator and changes
#' its subsequent state.
#'
#' @examples
#' set.seed(42)
#' n <- 400L
#' x1 <- stats::rbeta(n, shape1 = 2, shape2 = 5)
#' x <- cbind(x1 = x1, x2 = stats::rbeta(n, 2 + 6 * x1, 4))
#' set.seed(123)
#' fit <- fit_boostpm(
#'   x,
#'   Omega = cbind(lower = c(0, 0), upper = c(1, 1)),
#'   max_marginal_trees = 100,
#'   max_dependence_trees = 1000,
#'   n_bins = 100,
#'   max_split_depth = 15,
#'   min_node_observations = 10,
#'   c0 = 0.1,
#'   gamma = 0.5,
#'   add_noise = FALSE
#' )
#' generated <- simulate(fit, nsim = 500, seed = 321)
#'
#' old_par <- graphics::par(mfrow = c(1, 2))
#' graphics::plot(x, xlab = "x1", ylab = "x2", main = "Training data")
#' graphics::plot(
#'   generated,
#'   xlab = "x1",
#'   ylab = "x2",
#'   main = "Generated data"
#' )
#' graphics::par(old_par)
#'
#' @export
#' @md
simulate.boostPM_fit <- function(object, nsim = 1L, seed = NULL, ...) {
  extra_arguments <- list(...)
  if (length(extra_arguments) > 0L) {
    .boostpm_stop_invalid("`...` must be empty for `simulate.boostPM_fit()`.")
  }

  .boostpm_validate_fit_object(object)
  .boostpm_validate_simulation_size(nsim)

  if (!is.null(seed)) {
    .boostpm_validate_count(seed, "seed", minimum = 0L)
    set.seed(as.integer(seed))
  }

  simulated <- simulation(
    object$trees,
    nsim,
    object$support
  )
  variable_names <- names(object$variable_importance)
  if (!is.null(variable_names)) {
    colnames(simulated) <- variable_names
  }

  simulated
}

#' Evaluate a Fitted boostPM Density
#'
#' Evaluates the probability density represented by a fitted tree ensemble at
#' supplied points.
#'
#' @param object A fitted object returned by [fit_boostpm()].
#' @param newdata A finite numeric matrix with evaluation points in rows and
#'   one column per fitted variable.
#' @param type Character string selecting the return value: `"log_density"`
#'   returns log densities, `"density"` returns densities, and `"details"`
#'   returns a diagnostic list containing log densities and the cumulative mean
#'   log-density path across the fitted trees.
#' @param ... Unused. Additional arguments are an error.
#'
#' @return For `type = "log_density"` or `type = "density"`, a numeric vector
#'   with one entry per row of `newdata`, in the original row order. For
#'   `type = "details"`, a list containing:
#' \describe{
#'   \item{log_density}{The same vector returned by `type = "log_density"`.}
#'   \item{mean_log_density_path}{A numeric vector with one entry per fitted
#'   tree. Entry `k` is the mean log density over all rows of `newdata` after
#'   the first `k` trees have been applied.}
#' }
#'
#' @details
#' Points outside the fitted rectangular support receive log density `-Inf` and
#' density zero. At a split point, evaluation follows the left-child convention
#' in the method specification. Because `mean_log_density_path` averages over
#' every row of `newdata`, the entire path is `-Inf` when any row lies outside
#' the support.
#'
#' @examples
#' set.seed(42)
#' n <- 400L
#' x1 <- stats::rbeta(n, shape1 = 2, shape2 = 5)
#' x <- cbind(x1 = x1, x2 = stats::rbeta(n, 2 + 6 * x1, 4))
#' set.seed(123)
#' fit <- fit_boostpm(
#'   x,
#'   Omega = cbind(lower = c(0, 0), upper = c(1, 1)),
#'   max_marginal_trees = 100,
#'   max_dependence_trees = 1000,
#'   n_bins = 100,
#'   max_split_depth = 15,
#'   min_node_observations = 10,
#'   c0 = 0.1,
#'   gamma = 0.5,
#'   add_noise = FALSE
#' )
#'
#' grid <- seq(0.01, 0.99, length.out = 50L)
#' evaluation_grid <- as.matrix(expand.grid(x1 = grid, x2 = grid))
#' fitted_density <- matrix(
#'   predict(fit, evaluation_grid, type = "density"),
#'   nrow = length(grid)
#' )
#' graphics::image(grid, grid, fitted_density, xlab = "x1", ylab = "x2")
#' graphics::contour(
#'   grid, grid, fitted_density, add = TRUE, drawlabels = FALSE
#' )
#'
#' @export
#' @md
predict.boostPM_fit <- function(object,
                                newdata,
                                type = c("log_density", "density", "details"),
                                ...) {
  extra_arguments <- list(...)
  if (length(extra_arguments) > 0L) {
    .boostpm_stop_invalid("`...` must be empty for `predict.boostPM_fit()`.")
  }

  type <- match.arg(type)
  .boostpm_validate_fit_object(object)
  .boostpm_validate_eval_points(newdata, nrow(object$support))

  outside <- vapply(
    seq_len(nrow(newdata)),
    function(i) {
      any(
        newdata[i, ] < object$support[, 1L] |
          newdata[i, ] > object$support[, 2L]
      )
    },
    logical(1)
  )

  if (!any(outside)) {
    raw_details <- evaluate_log_density(
      object$trees,
      newdata,
      object$support
    )
    details <- list(
      log_density = raw_details$log_densities,
      mean_log_density_path = raw_details$mean_log_dens_path
    )
  } else {
    log_density <- rep(-Inf, nrow(newdata))
    inside <- !outside
    if (any(inside)) {
      inside_densities <- evaluate_log_density(
        object$trees,
        newdata[inside, , drop = FALSE],
        object$support
      )
      log_density[inside] <- inside_densities$log_densities
    }

    details <- list(
      log_density = log_density,
      mean_log_density_path = rep(-Inf, length(object$trees))
    )
  }

  if (identical(type, "details")) {
    return(details)
  }
  if (identical(type, "log_density")) {
    return(details$log_density)
  }

  exp(details$log_density)
}
