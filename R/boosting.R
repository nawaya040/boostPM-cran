boosting <- function(data,
                     add_noise = TRUE,
                     Omega = NULL,
                     ntree_max_marginal = 100,
                     ntree_max_dependence = 1000,
                     c0 = 0.1,
                     gamma = 0.1,
                     max_resol = 15,
                     min_obs = 5,
                     early_stop = NULL,
                     alpha = 0.9,
                     beta = 0.0,
                     precision = 1.0,
                     nbins = 8) {
  .boostpm_validate_numeric_matrix(data, "data")
  if (!is.null(Omega)) {
    .boostpm_validate_support(Omega, dimension = ncol(data))
  }
  .boostpm_validate_fit_controls(
    add_noise = add_noise,
    ntree_max_marginal = ntree_max_marginal,
    ntree_max_dependence = ntree_max_dependence,
    c0 = c0,
    gamma = gamma,
    max_resol = max_resol,
    min_obs = min_obs,
    early_stop = early_stop,
    alpha = alpha,
    beta = beta,
    precision = precision,
    nbins = nbins
  )
  if (!is.null(early_stop) &&
      (ntree_max_marginal > 0L || ntree_max_dependence > 0L) &&
      nrow(data) < 2L) {
    .boostpm_stop_invalid(
      "`early_stop` requires at least two data rows when a tree may be fitted."
    )
  }

  processed <- .boostpm_preprocess(data, add_noise, Omega)
  x_new <- processed$data
  Omega <- processed$Omega
  stopping <- .boostpm_early_stop_controls(early_stop)

  start_time <- Sys.time()

  out <- do_boosting(
    x_new,
    precision,
    alpha,
    beta,
    gamma,
    max_resol,
    ntree_max_marginal,
    ntree_max_dependence,
    c0,
    min_obs,
    nbins,
    stopping$eta_subsample,
    stopping$thresh_stop,
    stopping$ntrees_wait
  )

  out$Omega <- Omega

  end_time <- Sys.time()
  out$time <- end_time - start_time
  class(out) <- c("boostPM_fit", "list")
  print(end_time - start_time)

  out
}
