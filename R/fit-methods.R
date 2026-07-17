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
#' print(fit)
#'
#' @export
#' @md
print.boostPM_fit <- function(x, ...) {
  extra_arguments <- list(...)
  if (length(extra_arguments) > 0L) {
    .boostpm_stop_invalid("'...' must be empty for print.boostPM_fit().")
  }

  summarized <- summary(x)
  cat("boostPM fit\n")
  if (!is.na(summarized$n_observations)) {
    cat("  Observations:", summarized$n_observations, "\n")
  }
  cat("  Variables:", summarized$n_variables, "\n")
  cat("  Trees:", summarized$n_trees, "\n")
  if (!is.null(summarized$elapsed_time)) {
    cat("  Elapsed time:", format(summarized$elapsed_time), "\n")
  }
  if (!is.null(summarized$variable_importance)) {
    cat(
      "  Variable importance:",
      .boostpm_format_named_values(summarized$variable_importance),
      "\n"
    )
  }

  invisible(x)
}

.boostpm_format_named_values <- function(x) {
  values <- format(as.numeric(x), trim = TRUE)
  labels <- names(x)
  if (is.null(labels)) {
    return(paste(values, collapse = ", "))
  }

  paste(paste0(labels, " = ", values), collapse = ", ")
}

.boostpm_format_diagnostic_range <- function(x) {
  paste0(
    "min ", format(min(x), trim = TRUE),
    ", median ", format(stats::median(x), trim = TRUE),
    ", max ", format(max(x), trim = TRUE)
  )
}

#' Summarize a Fitted boostPM Distribution
#'
#' Extracts compact structural diagnostics from a boostPM_fit object.
#'
#' @param object A fitted object returned by [fit_boostpm()].
#' @param ... Unused.
#'
#' @return An object of class `summary.boostPM_fit`, represented as a list
#'   containing:
#' \describe{
#'   \item{call}{The matched call used to fit the model.}
#'   \item{n_observations}{Number of training observations, or `NA` when it
#'   cannot be recovered from the fitted object.}
#'   \item{n_variables}{Number of fitted variables.}
#'   \item{n_trees}{Number of accepted trees.}
#'   \item{support}{The original-scale lower and upper support limits.}
#'   \item{tree_diagnostics}{The per-tree diagnostic data frame returned by
#'   [fit_boostpm()].}
#'   \item{variable_importance}{Accumulated improvement attributed to each
#'   variable.}
#'   \item{elapsed_time}{Elapsed fitting time as a `difftime` object.}
#' }
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

  residuals <- object$residual_coordinates
  n_observations <- if (is.matrix(residuals)) ncol(residuals) else NA_integer_
  elapsed_time <- object$elapsed_time

  structure(
    list(
      call = object$call,
      n_observations = n_observations,
      n_variables = nrow(object$support),
      n_trees = length(object$trees),
      support = object$support,
      tree_diagnostics = object$tree_diagnostics,
      variable_importance = object$variable_importance,
      elapsed_time = elapsed_time
    ),
    class = "summary.boostPM_fit"
  )
}

#' Print a boostPM Fit Summary
#'
#' Prints the fitted call, data dimensions, support, structural tree
#' diagnostics, variable importance, and elapsed fitting time.
#'
#' @param x An object returned by [summary.boostPM_fit()].
#' @param ... Unused. Additional arguments are an error.
#'
#' @return The input summary object, invisibly.
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
#' print(summary(fit))
#'
#' @export
#' @md
print.summary.boostPM_fit <- function(x, ...) {
  extra_arguments <- list(...)
  if (length(extra_arguments) > 0L) {
    .boostpm_stop_invalid("'...' must be empty for print.summary.boostPM_fit().")
  }

  cat("Summary of boostPM fit\n")
  if (!is.null(x$call)) {
    cat("\nCall:\n")
    print(x$call)
  }
  cat("\nFit dimensions:\n")
  if (!is.na(x$n_observations)) {
    cat("  Observations:", x$n_observations, "\n")
  }
  cat("  Variables:", x$n_variables, "\n")
  cat("  Trees:", x$n_trees, "\n")
  cat("\nSupport:\n")
  print(x$support)
  if (!is.null(x$tree_diagnostics) && nrow(x$tree_diagnostics) > 0L) {
    cat(
      "\nNodes per tree:",
      .boostpm_format_diagnostic_range(x$tree_diagnostics$node_count),
      "\n"
    )
    cat(
      "Maximum tree depth:",
      .boostpm_format_diagnostic_range(x$tree_diagnostics$max_depth),
      "\n"
    )
  }
  if (!is.null(x$elapsed_time)) {
    cat("  Elapsed time:", format(x$elapsed_time), "\n")
  }
  if (!is.null(x$variable_importance)) {
    cat(
      "  Variable importance:",
      .boostpm_format_named_values(x$variable_importance),
      "\n"
    )
  }

  invisible(x)
}

#' Plot Diagnostics for a Fitted boostPM Distribution
#'
#' Displays a bar plot of variable importance, the number of nodes per tree,
#' or maximum tree depths.
#'
#' @param x A fitted object returned by [fit_boostpm()].
#' @param type Character string selecting "variable_importance",
#'   "tree_node_counts", or "tree_depths".
#' @param ... Additional arguments passed to [graphics::barplot()]. User values
#'   for `names.arg` and `ylab` override the method defaults. `height` cannot be
#'   supplied because it is determined by the selected diagnostic.
#'
#' @return The bar midpoints returned by [graphics::barplot()], invisibly.
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
#' plot(fit, type = "variable_importance")
#' plot(fit, type = "tree_node_counts")
#' plot(fit, type = "tree_depths")
#'
#' @export
#' @md
plot.boostPM_fit <- function(x,
                             type = c(
                               "variable_importance",
                               "tree_node_counts",
                               "tree_depths"
                             ),
                             ...) {
  .boostpm_validate_fit_object(x)
  type <- match.arg(type)
  extra_arguments <- list(...)
  if ("height" %in% names(extra_arguments)) {
    .boostpm_stop_invalid(
      "`height` is determined by the computed diagnostic values and cannot be supplied."
    )
  }

  values <- switch(
    type,
    variable_importance = x$variable_importance,
    tree_node_counts = x$tree_diagnostics$node_count,
    tree_depths = x$tree_diagnostics$max_depth
  )
  if (is.null(values) || length(values) == 0L) {
    .boostpm_stop_invalid(sprintf("No '%s' diagnostic is available.", type))
  }
  values <- as.numeric(values)

  labels <- switch(
    type,
    variable_importance = if (is.null(names(x$variable_importance))) {
      paste0("V", seq_along(values))
    } else {
      names(x$variable_importance)
    },
    tree_node_counts = paste0("Tree ", seq_along(values)),
    tree_depths = paste0("Tree ", seq_along(values))
  )
  y_label <- switch(
    type,
    variable_importance = "Variable importance",
    tree_node_counts = "Number of nodes",
    tree_depths = "Maximum depth"
  )

  if (!("names.arg" %in% names(extra_arguments))) {
    extra_arguments$names.arg <- labels
  }
  if (!("ylab" %in% names(extra_arguments))) {
    extra_arguments$ylab <- y_label
  }
  midpoints <- do.call(
    graphics::barplot,
    c(list(height = values), extra_arguments)
  )
  invisible(midpoints)
}
