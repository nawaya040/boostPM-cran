testthat::test_that("new public API returns documented prediction types", {
  fit <- list(
    tree_list = list(list(
      d = c(0L, -1L, -1L),
      l = c(0.5, -1, -1),
      theta = c(0.25, -1, -1)
    )),
    Omega = matrix(c(0, 1), nrow = 1L)
  )
  class(fit) <- c("boostPM_fit", "list")
  points <- matrix(c(0.25, 0.75), ncol = 1L)

  log_density <- stats::predict(fit, points, type = "log_density")
  density <- stats::predict(fit, points, type = "density")
  details <- stats::predict(fit, points, type = "details")

  testthat::expect_type(log_density, "double")
  testthat::expect_equal(density, exp(log_density))
  testthat::expect_identical(details$log_densities, log_density)
  testthat::expect_equal(
    stats::predict(fit, matrix(-0.1, ncol = 1L), type = "density"),
    0
  )
})

testthat::test_that("provisional function names are absent from the public API", {
  retired <- c("boosting", "eval_density_b", "simulation_b")
  testthat::expect_false(any(retired %in% getNamespaceExports("boostPM")))
  testthat::expect_false(any(vapply(
    retired,
    exists,
    logical(1),
    envir = asNamespace("boostPM"),
    inherits = FALSE
  )))
})

testthat::test_that("progress messages are optional and numerically inert", {
  arguments <- list(
    data = small_two_dimensional_data(),
    add_noise = FALSE,
    Omega = cbind(c(0, 0), c(1, 1)),
    ntree_max_marginal = 1,
    ntree_max_dependence = 1,
    c0 = 0.1,
    gamma = 0,
    max_resol = 1,
    min_obs = 2,
    alpha = 0.9,
    beta = 0,
    precision = 1,
    nbins = 4
  )

  set.seed(20240714)
  silent_output <- capture.output(
    silent_fit <- do.call(
      boostPM::fit_boostpm,
      c(arguments, list(progress = "none"))
    )
  )
  set.seed(20240714)
  stage_output <- capture.output(
    stage_fit <- do.call(
      boostPM::fit_boostpm,
      c(arguments, list(progress = "stage"))
    )
  )

  testthat::expect_length(silent_output, 0L)
  testthat::expect_identical(
    stage_output,
    c(
      "Fitting marginal distribution 1 of 2",
      "Fitting marginal distribution 2 of 2",
      "Fitting dependence structure"
    )
  )

  fields <- c(
    "residuals_boosting", "tree_size_store", "max_depth_store",
    "variable_importance", "tree_list", "Omega"
  )
  testthat::expect_identical(silent_fit[fields], stage_fit[fields])
})

testthat::test_that("boostPM fit methods provide compact diagnostics", {
  fit <- list(
    residuals_boosting = matrix(0, nrow = 2L, ncol = 4L),
    tree_size_store = c(3L, 5L),
    max_depth_store = c(1L, 2L),
    variable_importance = matrix(c(0.7, 0.3), ncol = 1L),
    tree_list = list(list(), list()),
    Omega = cbind(c(0, 0), c(1, 1)),
    time = structure(0.25, units = "secs", class = "difftime")
  )
  class(fit) <- c("boostPM_fit", "list")

  summarized <- summary(fit)
  testthat::expect_s3_class(summarized, "summary.boostPM_fit")
  testthat::expect_identical(summarized$n_observations, 4L)
  testthat::expect_identical(summarized$n_variables, 2L)
  testthat::expect_identical(summarized$n_trees, 2L)

  output <- capture.output(print(fit))
  testthat::expect_true(any(grepl("boostPM fit", output, fixed = TRUE)))
  testthat::expect_true(any(grepl("Elapsed time:", output, fixed = TRUE)))

  pdf_file <- tempfile(fileext = ".pdf")
  grDevices::pdf(pdf_file)
  on.exit(grDevices::dev.off(), add = TRUE)
  testthat::expect_silent(plot(fit))
  testthat::expect_silent(plot(fit, type = "tree_size"))
  testthat::expect_silent(plot(fit, type = "max_depth"))
})
