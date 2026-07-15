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
