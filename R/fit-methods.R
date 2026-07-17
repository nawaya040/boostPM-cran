#' Print a Fitted boostPM Distribution
#'
#' Prints a compact description of a boostPM_fit object.
#'
#' @param x A fitted object returned by [fit_boostpm()].
#' @param ... Unused.
#'
#' @return The input object, invisibly.
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
#' print(fit)
#'
#' @export
#' @md
print.boostPM_fit <- function(x, ...) {
  print(summary(x))
  invisible(x)
}

#' Summarize a Fitted boostPM Distribution
#'
#' Extracts compact structural diagnostics from a boostPM_fit object.
#'
#' @param object A fitted object returned by [fit_boostpm()].
#' @param ... Unused.
#'
#' @return An object of class summary.boostPM_fit containing the number of
#'   observations, variables, and trees; support; tree-size and depth
#'   diagnostics; variable importance; and elapsed fitting time when available.
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
#' summary(fit)
#'
#' @export
#' @md
summary.boostPM_fit <- function(object, ...) {
  extra_arguments <- list(...)
  if (length(extra_arguments) > 0L) {
    .boostpm_stop_invalid("'...' must be empty for summary.boostPM_fit().")
  }

  .boostpm_validate_fit_object(object)

  residuals <- object$residuals_boosting
  n_observations <- if (is.matrix(residuals)) ncol(residuals) else NA_integer_
  elapsed_time <- if ("time" %in% names(object)) object$time else NULL

  structure(
    list(
      n_observations = n_observations,
      n_variables = nrow(object$Omega),
      n_trees = length(object$tree_list),
      support = object$Omega,
      tree_size = object$tree_size_store,
      max_depth = object$max_depth_store,
      variable_importance = object$variable_importance,
      elapsed_time = elapsed_time
    ),
    class = "summary.boostPM_fit"
  )
}

#' @rdname summary.boostPM_fit
#' @param x A summary.boostPM_fit object.
#' @export
#' @md
print.summary.boostPM_fit <- function(x, ...) {
  extra_arguments <- list(...)
  if (length(extra_arguments) > 0L) {
    .boostpm_stop_invalid("'...' must be empty for print.summary.boostPM_fit().")
  }

  cat("boostPM fit\n")
  if (!is.na(x$n_observations)) {
    cat("  Observations:", x$n_observations, "\n")
  }
  cat("  Variables:", x$n_variables, "\n")
  cat("  Trees:", x$n_trees, "\n")
  if (!is.null(x$elapsed_time)) {
    cat("  Elapsed time:", format(x$elapsed_time), "\n")
  }
  if (!is.null(x$variable_importance)) {
    cat(
      "  Variable importance:",
      paste(format(as.numeric(x$variable_importance), trim = TRUE), collapse = ", "),
      "\n"
    )
  }

  invisible(x)
}

#' Plot Diagnostics for a Fitted boostPM Distribution
#'
#' Displays a bar plot of variable importance, tree sizes, or maximum tree
#' depths.
#'
#' @param x A fitted object returned by [fit_boostpm()].
#' @param type Character string selecting "variable_importance", "tree_size",
#'   or "max_depth".
#' @param ... Additional arguments passed to [graphics::barplot()].
#'
#' @return The bar midpoints returned by [graphics::barplot()], invisibly.
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
#' plot(fit)
#'
#' @export
#' @md
plot.boostPM_fit <- function(x,
                             type = c("variable_importance", "tree_size", "max_depth"),
                             ...) {
  .boostpm_validate_fit_object(x)
  type <- match.arg(type)

  values <- switch(
    type,
    variable_importance = x$variable_importance,
    tree_size = x$tree_size_store,
    max_depth = x$max_depth_store
  )
  if (is.null(values) || length(values) == 0L) {
    .boostpm_stop_invalid(sprintf("No '%s' diagnostic is available.", type))
  }
  values <- as.numeric(values)

  labels <- switch(
    type,
    variable_importance = paste0("V", seq_along(values)),
    tree_size = paste0("Tree ", seq_along(values)),
    max_depth = paste0("Tree ", seq_along(values))
  )
  y_label <- switch(
    type,
    variable_importance = "Variable importance",
    tree_size = "Number of nodes",
    max_depth = "Maximum depth"
  )

  midpoints <- graphics::barplot(
    height = values,
    names.arg = labels,
    ylab = y_label,
    ...
  )
  invisible(midpoints)
}
