project_root <- normalizePath(
  Sys.getenv("BOOSTPM_PROJECT_ROOT"),
  winslash = "/",
  mustWork = TRUE
)

original_dir <- file.path(project_root, "original")
expected_original_commit <- Sys.getenv("BOOSTPM_EXPECTED_ORIGINAL_COMMIT")
actual_original_commit <- Sys.getenv("BOOSTPM_ACTUAL_ORIGINAL_COMMIT")

make_wrapper_environment <- function() {
  environment <- new.env(parent = globalenv())
  sys.source(
    file.path(original_dir, "R", "boosting_functions.R"),
    envir = environment
  )
  environment
}

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
    fit <- boostPM::boosting(
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
      alpha = 0.9,
      beta = 0,
      nbins = 4,
      max_n_var = 2
    )
  ))
  fit
}

make_one_split_fit <- function(
    theta = 0.25,
    location = 0.5,
    support = matrix(c(0, 1), nrow = 1L)) {
  list(
    tree_list = list(list(
      d = c(0L, -1L, -1L),
      l = c(location, -1, -1),
      theta = c(theta, -1, -1)
    )),
    Omega = support
  )
}
