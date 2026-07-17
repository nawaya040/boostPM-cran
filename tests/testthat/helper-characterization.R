small_two_dimensional_data <- function() {
  matrix(
    c(
      0.10, 0.80,
      0.20, 0.70,
      0.30, 0.60,
      0.40, 0.90
    ),
    ncol = 2L,
    byrow = TRUE
  )
}

fit_small_archive_case <- function(seed = 20240714L) {
  set.seed(seed)
  invisible(capture.output(
    fit <- boostPM::fit_boostpm(
      small_two_dimensional_data(),
      add_noise = FALSE,
      Omega = cbind(c(0, 0), c(1, 1)),
      ntree_max_marginal = 1,
      ntree_max_dependence = 1,
      c0 = 0.1,
      gamma = 0,
      max_resol = 1,
      min_obs = 2,
      early_stop = NULL,
      prior_split_prob = 0.9,
      nbins = 4
    )
  ))
  fit
}

make_one_split_fit <- function(
    theta = 0.25,
    location = 0.5,
    support = matrix(c(0, 1), nrow = 1L)) {
  structure(list(
    tree_list = list(list(
      d = c(0L, -1L, -1L),
      l = c(location, -1, -1),
      theta = c(theta, -1, -1)
    )),
    Omega = support
  ), class = c("boostPM_fit", "list"))
}
