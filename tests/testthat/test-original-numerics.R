testthat::test_that("small fixed-seed fit reproduces the archived numerical fixture", {
  fit <- fit_small_archive_case()
  repeated <- fit_small_archive_case()

  fields <- c(
    "residual_coordinates", "tree_diagnostics",
    "variable_importance", "trees", "support"
  )
  testthat::expect_identical(fit[fields], repeated[fields])

  expected_residuals <- matrix(c(
    0.106777777777778, 0.765088888888889,
    0.213555555555556, 0.647633333333333,
    0.320333333333333, 0.530177777777778,
    0.427111111111111, 0.882544444444444
  ), nrow = 2L)
  expected_importance <- c(0.0655796456459819, 0.160889825450307)
  expected_trees <- list(
    list(
      d = c(0L, 0L, -1L, -1L, -1L),
      l = c(0.75, 0.75, -1, -1, -1),
      theta = c(0.775, 0.775, -1, -1, -1)
    ),
    list(
      d = c(1L, -1L, 1L, -1L, -1L),
      l = c(0.5, -1, 0.75, -1, -1),
      theta = c(0.45, -1, 0.75, -1, -1)
    ),
    list(
      d = c(1L, -1L, 1L, -1L, -1L),
      l = c(0.25, -1, 0.25, -1, -1),
      theta = c(0.225, -1, 0.225, -1, -1)
    )
  )

  testthat::expect_equal(fit$residual_coordinates, expected_residuals, tolerance = 1e-13)
  testthat::expect_identical(fit$tree_diagnostics$node_count, c(5L, 5L, 5L))
  testthat::expect_identical(fit$tree_diagnostics$max_depth, c(2L, 2L, 2L))
  testthat::expect_equal(as.numeric(fit$variable_importance), expected_importance, tolerance = 1e-13)
  testthat::expect_identical(fit$trees, expected_trees)
  testthat::expect_identical(
    fit$support,
    structure(
      matrix(c(0, 0, 1, 1), nrow = 2L),
      dimnames = list(NULL, c("lower", "upper"))
    )
  )
})

testthat::test_that("fixed archived fit reproduces density path", {
  fit <- fit_small_archive_case()
  result <- stats::predict(
    fit,
    small_two_dimensional_data(),
    type = "details"
  )

  testthat::expect_equal(
    as.numeric(result$log_density),
    rep(0.226469471096288, 4L),
    tolerance = 1e-13
  )
  testthat::expect_equal(
    as.numeric(result$mean_log_density_path),
    c(0.0655796456459817, 0.160889825450307, 0.226469471096288),
    tolerance = 1e-13
  )
})

testthat::test_that("fixed archived fit reproduces simulation output", {
  fit <- fit_small_archive_case()

  set.seed(99)
  simulated <- stats::simulate(fit, nsim = 3L)
  expected <- matrix(c(
    0.547596947343305,
    0.65243520828024,
    0.50103457445428,
    0.140471203988533,
    0.993622078768301,
    0.971575685986011
  ), nrow = 3L)

  testthat::expect_equal(simulated, expected, tolerance = 1e-13)
})

testthat::test_that("small univariate fit reproduces the archived fixture", {
  data <- matrix(c(0.1, 0.2, 0.4, 0.6, 0.8, 0.9), ncol = 1L)
  set.seed(314)
  invisible(capture.output(
    fit <- boostPM::fit_boostpm(
      data,
      add_noise = FALSE,
      Omega = matrix(c(0, 1), nrow = 1L),
      max_marginal_trees = 1,
      max_dependence_trees = 0,
      c0 = 0.1,
      gamma = 0,
      max_split_depth = 1,
      min_node_observations = 2,
      early_stop = NULL,
      prior_split_prob = 1,
      n_bins = 4
    )
  ))

  expected_residuals <- matrix(c(
    0.0988888888888889,
    0.197777777777778,
    0.396666666666667,
    0.603333333333333,
    0.802222222222222,
    0.901111111111111
  ), nrow = 1L)
  expected_tree <- list(
    d = c(0L, 0L, -1L, -1L, 0L, -1L, -1L),
    l = c(0.5, 0.75, -1, -1, 0.25, -1, -1),
    theta = c(0.5, 0.741666666666667, -1, -1, 0.258333333333333, -1, -1)
  )

  testthat::expect_equal(fit$residual_coordinates, expected_residuals, tolerance = 1e-13)
  testthat::expect_identical(fit$tree_diagnostics$node_count, 7L)
  testthat::expect_identical(fit$tree_diagnostics$max_depth, 2L)
  testthat::expect_equal(
    as.numeric(fit$variable_importance),
    0.00348107387558016,
    tolerance = 1e-14
  )
  testthat::expect_equal(fit$trees[[1]], expected_tree, tolerance = 1e-14)

  density <- stats::predict(fit, data, type = "details")
  testthat::expect_equal(
    as.numeric(density$log_density),
    c(
      -0.0111733005981253,
      -0.0111733005981253,
      0.0327898228229908,
      0.032789822822991,
      -0.0111733005981253,
      -0.0111733005981253
    ),
    tolerance = 1e-13
  )
})
