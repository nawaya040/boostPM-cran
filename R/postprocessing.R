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
#'   variable.
#'
#' @details
#' With `seed = NULL`, randomness is controlled by calling [set.seed()] before
#' `simulate()`. Supplying `seed` sets R's random-number generator and changes
#' its subsequent state.
#'
#' @examples
#' set.seed(10)
#' x1 <- stats::rbeta(60, shape1 = 2, shape2 = 5)
#' x <- cbind(x1 = x1, x2 = stats::rbeta(60, 2 + 4 * x1, 3))
#' fit <- fit_boostpm(
#'   x,
#'   Omega = cbind(lower = c(0, 0), upper = c(1, 1)),
#'   add_noise = FALSE,
#'   ntree_max_marginal = 1,
#'   ntree_max_dependence = 1,
#'   max_resol = 1
#' )
#' simulate(fit, nsim = 3, seed = 1)
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

  simulation(
    object$tree_list,
    nsim,
    object$Omega
  )
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
#'   log-density path.
#' @param ... Unused. Additional arguments are an error.
#'
#' @return For `type = "log_density"` or `type = "density"`, a numeric vector
#'   with one entry per row of `newdata`. For `type = "details"`, a list with
#'   components `log_densities` and `mean_log_dens_path`.
#'
#' @details
#' Points outside the fitted rectangular support receive log density `-Inf` and
#' density zero. At a split point, evaluation follows the left-child convention
#' in the method specification.
#'
#' @examples
#' set.seed(10)
#' x1 <- stats::rbeta(60, shape1 = 2, shape2 = 5)
#' x <- cbind(x1 = x1, x2 = stats::rbeta(60, 2 + 4 * x1, 3))
#' fit <- fit_boostpm(
#'   x,
#'   Omega = cbind(lower = c(0, 0), upper = c(1, 1)),
#'   add_noise = FALSE,
#'   ntree_max_marginal = 1,
#'   ntree_max_dependence = 1,
#'   max_resol = 1
#' )
#' evaluation_points <- matrix(c(0.25, 0.25, 0.50, 0.50),
#'                             ncol = 2, byrow = TRUE)
#' predict(fit, evaluation_points, type = "density")
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
  .boostpm_validate_eval_points(newdata, nrow(object$Omega))

  outside <- vapply(
    seq_len(nrow(newdata)),
    function(i) {
      any(
        newdata[i, ] < object$Omega[, 1L] |
          newdata[i, ] > object$Omega[, 2L]
      )
    },
    logical(1)
  )

  if (!any(outside)) {
    details <- evaluate_log_density(
      object$tree_list,
      newdata,
      object$Omega
    )
  } else {
    log_densities <- rep(-Inf, nrow(newdata))
    inside <- !outside
    if (any(inside)) {
      inside_densities <- evaluate_log_density(
        object$tree_list,
        newdata[inside, , drop = FALSE],
        object$Omega
      )
      log_densities[inside] <- inside_densities$log_densities
    }

    details <- list(
      log_densities = log_densities,
      mean_log_dens_path = rep(-Inf, length(object$tree_list))
    )
  }

  if (identical(type, "details")) {
    return(details)
  }
  if (identical(type, "log_density")) {
    return(details$log_densities)
  }

  exp(details$log_densities)
}
