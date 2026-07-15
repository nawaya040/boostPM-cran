#' Simulate from a Fitted boostPM Model
#'
#' Draws samples from the probability distribution represented by a fitted
#' tree ensemble.
#'
#' @param list_boosting A fitted object returned by [boosting()].
#' @param size Non-negative integer. Number of observations to simulate.
#'
#' @return A numeric matrix with `size` rows and one column per fitted
#'   variable.
#'
#' @details
#' The routine uses R's random-number generator. Calling [set.seed()] before
#' simulation supports reproducibility within a fixed R runtime.
#'
#' @examples
#' fit <- list(tree_list = list(), Omega = matrix(c(0, 1), nrow = 1))
#' set.seed(1)
#' simulation_b(fit, 3)
#'
#' @export
#' @md
simulation_b <- function(list_boosting, size) {
  .boostpm_validate_fit_object(list_boosting)
  .boostpm_validate_simulation_size(size)

  simulation(
    list_boosting$tree_list,
    size,
    list_boosting$Omega
  )
}

#' Evaluate a Fitted boostPM Log Density
#'
#' Evaluates the log density represented by a fitted tree ensemble at supplied
#' points.
#'
#' @param list_boosting A fitted object returned by [boosting()].
#' @param eval_points A finite numeric matrix with evaluation points in rows
#'   and one column per fitted variable.
#'
#' @return A list with two components: `log_densities`, the log density for
#'   each row of `eval_points`; and `mean_log_dens_path`, the cumulative mean
#'   log-density path after each fitted tree.
#'
#' @details
#' Points outside the fitted rectangular support receive log density `-Inf`.
#' At a split point, the evaluation follows the left-child convention used in
#' the method specification.
#'
#' @examples
#' fit <- list(
#'   tree_list = list(list(
#'     d = c(0L, -1L, -1L),
#'     l = c(0.5, -1, -1),
#'     theta = c(0.25, -1, -1)
#'   )),
#'   Omega = matrix(c(0, 1), nrow = 1)
#' )
#' eval_density_b(fit, matrix(c(0.25, 0.75), ncol = 1))
#'
#' @export
#' @md
eval_density_b <- function(list_boosting, eval_points) {
  .boostpm_validate_fit_object(list_boosting)
  .boostpm_validate_eval_points(eval_points, nrow(list_boosting$Omega))

  outside <- vapply(
    seq_len(nrow(eval_points)),
    function(i) {
      any(
        eval_points[i, ] < list_boosting$Omega[, 1L] |
          eval_points[i, ] > list_boosting$Omega[, 2L]
      )
    },
    logical(1)
  )

  if (!any(outside)) {
    out_dens <- evaluate_log_density(
      list_boosting$tree_list,
      eval_points,
      list_boosting$Omega
    )
  } else {
    log_densities <- rep(-Inf, nrow(eval_points))
    inside <- !outside
    if (any(inside)) {
      inside_dens <- evaluate_log_density(
        list_boosting$tree_list,
        eval_points[inside, , drop = FALSE],
        list_boosting$Omega
      )
      log_densities[inside] <- inside_dens$log_densities
    }

    out_dens <- list(
      log_densities = log_densities,
      mean_log_dens_path = rep(-Inf, length(list_boosting$tree_list))
    )
  }

  out <- list(
    out_dens$log_densities,
    out_dens$mean_log_dens_path
  )
  names(out) <- c("log_densities", "mean_log_dens_path")
  out
}
