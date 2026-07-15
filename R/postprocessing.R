simulation_b <- function(list_boosting, size) {
  .boostpm_validate_fit_object(list_boosting)
  .boostpm_validate_simulation_size(size)

  simulation(
    list_boosting$tree_list,
    size,
    list_boosting$Omega
  )
}

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
