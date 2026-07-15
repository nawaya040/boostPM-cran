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

testthat::test_that("deprecated names retain their established result forms", {
  fit <- list(tree_list = list(), Omega = matrix(c(0, 1), nrow = 1L))

  testthat::expect_warning(
    simulated <- boostPM::simulation_b(fit, 2L),
    "deprecated"
  )
  testthat::expect_identical(dim(simulated), c(2L, 1L))

  testthat::expect_warning(
    details <- boostPM::eval_density_b(fit, matrix(0.5, ncol = 1L)),
    "deprecated"
  )
  testthat::expect_named(details, c("log_densities", "mean_log_dens_path"))
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
