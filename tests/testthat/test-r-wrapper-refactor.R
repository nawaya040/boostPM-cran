testthat::test_that("refactored preprocessing preserves automatic support", {
  data <- matrix(
    c(1, 10, 2, 20, 3, 30),
    ncol = 2L,
    byrow = TRUE
  )

  result <- boostPM:::.boostpm_preprocess(
    data,
    add_noise = FALSE,
    Omega = NULL
  )

  expected_support <- matrix(c(0.8, 8, 3.2, 32), nrow = 2L)
  expected_scaled <- matrix(
    rep(c(1 / 12, 1 / 2, 11 / 12), 2L),
    nrow = 3L
  )

  testthat::expect_equal(result$Omega, expected_support, tolerance = 1e-15)
  testthat::expect_equal(result$data, expected_scaled, tolerance = 1e-15)
})

testthat::test_that("refactored preprocessing preserves fixed-seed jitter", {
  set.seed(42)
  result <- boostPM:::.boostpm_preprocess(
    matrix(c(1, 1, 2, 3, 3), ncol = 1L),
    add_noise = TRUE,
    Omega = NULL
  )

  expected_scaled <- matrix(c(
    0.0833333333333334,
    0.0930208491696808,
    0.337901638206532,
    0.679884337344537,
    0.916666666666667
  ), ncol = 1L)
  expected_support <- matrix(
    c(1.22324188523926, 3.52201178432442),
    nrow = 1L
  )

  testthat::expect_equal(result$data, expected_scaled, tolerance = 1e-14)
  testthat::expect_equal(result$Omega, expected_support, tolerance = 1e-14)
})

testthat::test_that("refactored controls preserve archived forwarding", {
  disabled <- boostPM:::.boostpm_early_stop_controls(NULL)
  enabled <- boostPM:::.boostpm_early_stop_controls(c(-0.01, 7))

  testthat::expect_identical(disabled, list(
    eta_subsample = 1,
    thresh_stop = 1,
    ntrees_wait = 100
  ))
  testthat::expect_identical(enabled, list(
    eta_subsample = 0.9,
    thresh_stop = -0.01,
    ntrees_wait = 7
  ))
})

testthat::test_that("public fit API preserves low-level argument order", {
  recorded <- new.env(parent = emptyenv())
  testthat::local_mocked_bindings(
    do_boosting = function(...) {
      recorded$arguments <- list(...)
      list(marker = "mock fit")
    },
    .package = "boostPM"
  )

  data <- matrix(
    c(1, 10, 2, 20, 3, 30),
    ncol = 2L,
    byrow = TRUE
  )
  output <- capture.output(
    fit <- boostPM::fit_boostpm(data, add_noise = FALSE)
  )

  expected_scaled <- matrix(
    rep(c(1 / 12, 1 / 2, 11 / 12), 2L),
    nrow = 3L
  )
  testthat::expect_equal(recorded$arguments[[1]], expected_scaled, tolerance = 1e-15)
  testthat::expect_identical(recorded$arguments[2:14], list(
    1, 0.9, 0, 0.1, 15, 100, 1000, 0.1, 5, 8,
    1, 1, 100
  ))
  testthat::expect_identical(fit$marker, "mock fit")
  testthat::expect_s3_class(fit, "boostPM_fit")
  testthat::expect_s3_class(fit$time, "difftime")
  testthat::expect_true(any(grepl("Time difference", output, fixed = TRUE)))
})

testthat::test_that("S3 post-processing methods preserve argument order", {
  recorded <- new.env(parent = emptyenv())
  testthat::local_mocked_bindings(
    simulation = function(tree_list, size_simulation, support) {
      recorded$simulation <- list(tree_list, size_simulation, support)
      matrix(0.25, nrow = size_simulation, ncol = 1L)
    },
    evaluate_log_density = function(tree_list, eval_points, support) {
      recorded$density <- list(tree_list, eval_points, support)
      list(log_densities = 1:2, mean_log_dens_path = 3:4)
    },
    .package = "boostPM"
  )

  fit <- list(
    tree_list = list("tree"),
    Omega = matrix(c(0, 1), nrow = 1L)
  )
  class(fit) <- c("boostPM_fit", "list")
  points <- matrix(c(0.2, 0.8), ncol = 1L)

  simulated <- stats::simulate(fit, nsim = 2L)
  density <- stats::predict(fit, points, type = "details")

  testthat::expect_identical(recorded$simulation, list(
    fit$tree_list, 2L, fit$Omega
  ))
  testthat::expect_identical(recorded$density, list(
    fit$tree_list, points, fit$Omega
  ))
  testthat::expect_identical(simulated, matrix(0.25, nrow = 2L, ncol = 1L))
  testthat::expect_identical(names(density), c(
    "log_densities", "mean_log_dens_path"
  ))
  testthat::expect_identical(density$log_densities, 1:2)
  testthat::expect_identical(density$mean_log_dens_path, 3:4)
})

testthat::test_that("preprocessing rejects constant columns", {
  testthat::expect_error(
    boostPM:::.boostpm_preprocess(
      matrix(rep(1, 4), ncol = 1L),
      add_noise = TRUE,
      Omega = NULL
    ),
    "constant column"
  )
})
