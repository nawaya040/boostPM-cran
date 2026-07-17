.boostpm_stop_invalid <- function(message) {
  stop(message, call. = FALSE)
}

.boostpm_validate_numeric_matrix <- function(x,
                                             name,
                                             allow_zero_rows = FALSE) {
  if (!is.matrix(x) || !is.numeric(x)) {
    .boostpm_stop_invalid(sprintf("`%s` must be a numeric matrix.", name))
  }

  if (ncol(x) < 1L) {
    .boostpm_stop_invalid(
      sprintf("`%s` must have at least one column.", name)
    )
  }

  if (!allow_zero_rows && nrow(x) < 1L) {
    .boostpm_stop_invalid(
      sprintf("`%s` must have at least one row.", name)
    )
  }

  if (any(!is.finite(x))) {
    .boostpm_stop_invalid(
      sprintf("`%s` must contain only finite values.", name)
    )
  }

  invisible(x)
}

.boostpm_validate_flag <- function(x, name) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    .boostpm_stop_invalid(
      sprintf("`%s` must be one non-missing logical value.", name)
    )
  }

  invisible(x)
}

.boostpm_validate_scalar <- function(x, name) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x)) {
    .boostpm_stop_invalid(
      sprintf("`%s` must be one finite numeric value.", name)
    )
  }

  invisible(x)
}

.boostpm_validate_count <- function(x, name, minimum) {
  .boostpm_validate_scalar(x, name)

  if (x != floor(x) || x < minimum || x > .Machine$integer.max) {
    .boostpm_stop_invalid(sprintf(
      "`%s` must be an integer-valued number between %s and %s.",
      name,
      format(minimum, scientific = FALSE),
      format(.Machine$integer.max, scientific = FALSE)
    ))
  }

  invisible(x)
}

.boostpm_validate_support <- function(Omega, dimension = NULL) {
  .boostpm_validate_numeric_matrix(Omega, "Omega")

  if (ncol(Omega) != 2L) {
    .boostpm_stop_invalid("`Omega` must have exactly two columns.")
  }

  if (!is.null(dimension) && nrow(Omega) != dimension) {
    .boostpm_stop_invalid(
      "`Omega` must have one row for each column of `data`."
    )
  }

  if (any(Omega[, 1L] >= Omega[, 2L])) {
    .boostpm_stop_invalid(
      paste(
        "Each row of `Omega` must have its lower bound below its upper bound",
        "and therefore have positive width."
      )
    )
  }

  invisible(Omega)
}

.boostpm_validate_nonconstant_data <- function(data) {
  constant_columns <- which(vapply(
    seq_len(ncol(data)),
    function(j) min(data[, j]) == max(data[, j]),
    logical(1)
  ))

  if (length(constant_columns) > 0L) {
    .boostpm_stop_invalid(sprintf(
      "`data` must not contain constant columns; constant column%s: %s.",
      if (length(constant_columns) == 1L) "" else "s",
      paste(constant_columns, collapse = ", ")
    ))
  }

  invisible(data)
}

.boostpm_validate_fit_controls <- function(max_marginal_trees,
                                           max_dependence_trees,
                                           n_bins,
                                           max_split_depth,
                                           min_node_observations,
                                           c0,
                                           gamma,
                                           early_stop,
                                           prior_split_prob,
                                           add_noise) {
  .boostpm_validate_flag(add_noise, "add_noise")

  .boostpm_validate_count(
    max_marginal_trees,
    "max_marginal_trees",
    minimum = 0L
  )
  .boostpm_validate_count(
    max_dependence_trees,
    "max_dependence_trees",
    minimum = 0L
  )
  .boostpm_validate_count(n_bins, "n_bins", minimum = 2L)
  .boostpm_validate_count(max_split_depth, "max_split_depth", minimum = 0L)
  .boostpm_validate_count(
    min_node_observations,
    "min_node_observations",
    minimum = 1L
  )

  for (name in c("c0", "gamma", "prior_split_prob")) {
    .boostpm_validate_scalar(get(name), name)
  }

  if (c0 <= 0 || c0 >= 1) {
    .boostpm_stop_invalid("`c0` must be strictly between 0 and 1.")
  }
  if (gamma < 0) {
    .boostpm_stop_invalid("`gamma` must be greater than or equal to 0.")
  }
  if (prior_split_prob < 0 || prior_split_prob > 1) {
    .boostpm_stop_invalid(
      "`prior_split_prob` must be between 0 and 1, inclusive."
    )
  }
  if (!is.null(early_stop)) {
    if (!is.numeric(early_stop) || length(early_stop) != 2L ||
        any(!is.finite(early_stop))) {
      .boostpm_stop_invalid(
        "`early_stop` must be NULL or a finite numeric vector of length two."
      )
    }

    .boostpm_validate_count(early_stop[2L], "early_stop[2]", minimum = 2L)
  }

  invisible(NULL)
}

.boostpm_validate_fit_object <- function(object) {
  if (!is.list(object)) {
    .boostpm_stop_invalid(
      "`object` must be a fitted object returned by `fit_boostpm()`."
    )
  }

  required <- c("trees", "support")
  missing_components <- setdiff(required, names(object))
  if (length(missing_components) > 0L) {
    .boostpm_stop_invalid(sprintf(
      "`object` is missing required component%s: %s.",
      if (length(missing_components) == 1L) "" else "s",
      paste(sprintf("`%s`", missing_components), collapse = ", ")
    ))
  }

  if (!is.list(object$trees)) {
    .boostpm_stop_invalid("`object$trees` must be a list.")
  }

  .boostpm_validate_support(object$support)
  invisible(NULL)
}

.boostpm_validate_simulation_size <- function(nsim) {
  .boostpm_validate_scalar(nsim, "nsim")
  if (nsim != floor(nsim) || nsim < 0L || nsim > .Machine$integer.max) {
    .boostpm_stop_invalid(sprintf(
      "`nsim` must be a non-negative integer-valued number no greater than %s.",
      format(.Machine$integer.max, scientific = FALSE)
    ))
  }

  invisible(nsim)
}

.boostpm_validate_eval_points <- function(eval_points, dimension) {
  .boostpm_validate_numeric_matrix(
    eval_points,
    "eval_points",
    allow_zero_rows = TRUE
  )

  if (ncol(eval_points) != dimension) {
    .boostpm_stop_invalid(
      paste(
        "`eval_points` must have one column per support row;",
        "that is, one column for each row of the fitted `support`."
      )
    )
  }

  invisible(eval_points)
}
