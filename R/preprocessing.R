.boostpm_jitter_ties <- function(data) {
  d <- ncol(data)
  n <- nrow(data)
  x_new <- matrix(NA, nrow = n, ncol = d)

  for (j in 1:d) {
    sort_temp <- sort(data[, j], index.return = TRUE)
    x_j <- sort_temp$x
    indices_unique <- which(!duplicated(x_j))
    num_unique <- length(indices_unique)

    jitter_group <- function(k) {
      ind <- indices_unique[k]
      if (k < num_unique) {
        ind_last <- indices_unique[k + 1] - 1
      } else {
        ind_last <- n
      }

      if (ind != ind_last) {
        if (k == 1) {
          left <- right <-
            (x_j[indices_unique[2]] - x_j[indices_unique[1]]) / 2
        } else if (k == num_unique) {
          left <- right <-
            (x_j[indices_unique[num_unique]] -
              x_j[indices_unique[num_unique - 1]]) / 2
        } else {
          left <-
            (x_j[indices_unique[k]] - x_j[indices_unique[k - 1]]) / 2
          right <-
            (x_j[indices_unique[k + 1]] - x_j[indices_unique[k]]) / 2
        }

        return(
          x_j[ind:ind_last] +
            runif(ind_last - ind + 1, -left, right)
        )
      }

      x_j[ind]
    }

    x_new[sort_temp$ix, j] <-
      unlist(sapply(1:num_unique, jitter_group))
  }

  x_new
}

.boostpm_scale_to_support <- function(data, x_new, Omega) {
  d <- ncol(data)

  if (is.null(Omega)) {
    Omega <- matrix(NA, nrow = d, ncol = 2)

    for (j in 1:d) {
      min_j <- min(x_new[, j])
      max_j <- max(x_new[, j])
      width_j <- max_j - min_j

      m_resize <- min_j - 0.1 * width_j
      M_resize <- max_j + 0.1 * width_j

      Omega[j, 1] <- m_resize
      Omega[j, 2] <- M_resize
      x_new[, j] <-
        (x_new[, j] - m_resize) / (M_resize - m_resize)
    }
  } else {
    for (j in 1:d) {
      is_okay <-
        prod(Omega[j, 1] < data[, j]) *
        prod(Omega[j, 2] > data[, j])
      if (is_okay != 1) {
        stop(
          "The sample space (omega) is too small and some observations are outside"
        )
      }
    }

    for (j in 1:d) {
      x_new[, j] <-
        (x_new[, j] - Omega[j, 1]) / (Omega[j, 2] - Omega[j, 1])
    }
  }

  list(data = x_new, Omega = Omega)
}

.boostpm_preprocess <- function(data, add_noise, Omega) {
  .boostpm_validate_nonconstant_data(data)

  if (add_noise) {
    x_new <- .boostpm_jitter_ties(data)
  } else {
    x_new <- data
  }

  if (!is.null(Omega) &&
      any(vapply(
        seq_len(ncol(data)),
        function(j) {
          any(x_new[, j] <= Omega[j, 1L] | x_new[, j] >= Omega[j, 2L])
        },
        logical(1)
      ))) {
    .boostpm_stop_invalid(
      "Jittered observations must remain strictly inside `Omega`."
    )
  }

  .boostpm_scale_to_support(data, x_new, Omega)
}
