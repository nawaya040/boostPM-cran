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

.boostpm_validate_fit_controls <- function(add_noise,
                                           ntree_max_marginal,
                                           ntree_max_dependence,
                                           c0,
                                           gamma,
                                           max_resol,
                                           min_obs,
                                           early_stop,
                                           alpha,
                                           beta,
                                           precision,
                                           nbins) {
  .boostpm_validate_flag(add_noise, "add_noise")

  .boostpm_validate_count(
    ntree_max_marginal,
    "ntree_max_marginal",
    minimum = 0L
  )
  .boostpm_validate_count(
    ntree_max_dependence,
    "ntree_max_dependence",
    minimum = 0L
  )
  .boostpm_validate_count(max_resol, "max_resol", minimum = 0L)
  .boostpm_validate_count(min_obs, "min_obs", minimum = 1L)
  .boostpm_validate_count(nbins, "nbins", minimum = 2L)

  for (name in c("c0", "gamma", "alpha", "beta", "precision")) {
    .boostpm_validate_scalar(get(name), name)
  }

  if (c0 <= 0 || c0 >= 1) {
    .boostpm_stop_invalid("`c0` must be strictly between 0 and 1.")
  }
  if (gamma < 0) {
    .boostpm_stop_invalid("`gamma` must be greater than or equal to 0.")
  }
  if (alpha < 0 || alpha > 1) {
    .boostpm_stop_invalid("`alpha` must be between 0 and 1, inclusive.")
  }
  if (beta < 0) {
    .boostpm_stop_invalid("`beta` must be greater than or equal to 0.")
  }
  if (precision <= 0) {
    .boostpm_stop_invalid("`precision` must be greater than 0.")
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

.boostpm_validate_fit_object <- function(list_boosting) {
  if (!is.list(list_boosting)) {
    .boostpm_stop_invalid(
      "`list_boosting` must be a fitted object returned by `boosting()`."
    )
  }

  required <- c("tree_list", "Omega")
  missing_components <- setdiff(required, names(list_boosting))
  if (length(missing_components) > 0L) {
    .boostpm_stop_invalid(sprintf(
      "`list_boosting` is missing required component%s: %s.",
      if (length(missing_components) == 1L) "" else "s",
      paste(sprintf("`%s`", missing_components), collapse = ", ")
    ))
  }

  if (!is.list(list_boosting$tree_list)) {
    .boostpm_stop_invalid("`list_boosting$tree_list` must be a list.")
  }

  .boostpm_validate_support(list_boosting$Omega)
  invisible(NULL)
}

.boostpm_validate_simulation_size <- function(size) {
  .boostpm_validate_scalar(size, "size")
  if (size != floor(size) || size < 0L || size > .Machine$integer.max) {
    .boostpm_stop_invalid(sprintf(
      "`size` must be a non-negative integer-valued number no greater than %s.",
      format(.Machine$integer.max, scientific = FALSE)
    ))
  }

  invisible(size)
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
        "that is, one column for each row of `Omega`."
      )
    )
  }

  invisible(eval_points)
}
