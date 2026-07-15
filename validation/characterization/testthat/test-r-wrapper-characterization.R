testthat::test_that("archived commit identifier is fixed", {
  testthat::expect_identical(
    actual_original_commit,
    expected_original_commit
  )
  testthat::expect_identical(
    expected_original_commit,
    "1732dba73d3788c9c457f958c4e5699f12ff3bab"
  )
})

testthat::test_that("automatic support and defaults are forwarded unchanged", {
  wrapper <- make_wrapper_environment()
  recorded <- new.env(parent = emptyenv())
  wrapper$do_boosting <- function(...) {
    recorded$arguments <- list(...)
    list(marker = "mock fit")
  }

  data <- matrix(
    c(1, 10, 2, 20, 3, 30),
    ncol = 2L,
    byrow = TRUE
  )
  output <- capture.output(fit <- wrapper$boosting(data, add_noise = FALSE))

  expected_support <- matrix(c(0.8, 8, 3.2, 32), nrow = 2L)
  expected_scaled <- matrix(
    rep(c(1 / 12, 1 / 2, 11 / 12), 2L),
    nrow = 3L
  )

  testthat::expect_equal(fit$Omega, expected_support, tolerance = 1e-15)
  testthat::expect_equal(recorded$arguments[[1]], expected_scaled, tolerance = 1e-15)
  testthat::expect_identical(recorded$arguments[2:15], list(
    1, 0.9, 0, 0.1, 15, 100, 1000, 0.1, 5, 8,
    1, 1, 100, 100
  ))
  testthat::expect_identical(fit$marker, "mock fit")
  testthat::expect_s3_class(fit$time, "difftime")
  testthat::expect_true(any(grepl("Time difference", output, fixed = TRUE)))
})

testthat::test_that("supplied support uses strict containment and affine scaling", {
  wrapper <- make_wrapper_environment()
  recorded <- new.env(parent = emptyenv())
  wrapper$do_boosting <- function(...) {
    recorded$arguments <- list(...)
    list()
  }

  data <- matrix(c(2, 12, 4, 16), ncol = 2L, byrow = TRUE)
  support <- matrix(c(0, 10, 5, 20), nrow = 2L)
  invisible(capture.output(
    fit <- wrapper$boosting(data, add_noise = FALSE, Omega = support)
  ))

  testthat::expect_equal(
    recorded$arguments[[1]],
    matrix(c(0.4, 0.2, 0.8, 0.6), ncol = 2L, byrow = TRUE),
    tolerance = 1e-15
  )
  testthat::expect_identical(fit$Omega, support)

  boundary_data <- matrix(c(0, 12, 4, 16), ncol = 2L, byrow = TRUE)
  testthat::expect_error(
    wrapper$boosting(boundary_data, add_noise = FALSE, Omega = support),
    "sample space.*too small"
  )
})

testthat::test_that("early stopping control forces the archived 90 percent fraction", {
  wrapper <- make_wrapper_environment()
  recorded <- new.env(parent = emptyenv())
  wrapper$do_boosting <- function(...) {
    recorded$arguments <- list(...)
    list()
  }

  data <- matrix(c(0.2, 0.4, 0.6, 0.8), ncol = 1L)
  invisible(capture.output(
    wrapper$boosting(
      data,
      add_noise = FALSE,
      Omega = matrix(c(0, 1), nrow = 1L),
      early_stop = c(-0.01, 7)
    )
  ))

  testthat::expect_identical(recorded$arguments[[12]], 0.9)
  testthat::expect_identical(recorded$arguments[[13]], -0.01)
  testthat::expect_identical(recorded$arguments[[14]], 7)
})

testthat::test_that("tie jitter has fixed seeded archived output", {
  wrapper <- make_wrapper_environment()
  recorded <- new.env(parent = emptyenv())
  wrapper$do_boosting <- function(...) {
    recorded$arguments <- list(...)
    list()
  }

  set.seed(42)
  invisible(capture.output(
    fit <- wrapper$boosting(
      matrix(c(1, 1, 2, 3, 3), ncol = 1L),
      ntree_max_marginal = 0,
      ntree_max_dependence = 0
    )
  ))

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

  testthat::expect_equal(recorded$arguments[[1]], expected_scaled, tolerance = 1e-14)
  testthat::expect_equal(fit$Omega, expected_support, tolerance = 1e-14)
})

testthat::test_that("interior tie jitter has fixed seeded archived output", {
  wrapper <- make_wrapper_environment()
  recorded <- new.env(parent = emptyenv())
  wrapper$do_boosting <- function(...) {
    recorded$arguments <- list(...)
    list()
  }

  set.seed(7)
  invisible(capture.output(
    fit <- wrapper$boosting(
      matrix(c(0, 1, 1, 2), ncol = 1L),
      ntree_max_marginal = 0,
      ntree_max_dependence = 0
    )
  ))

  testthat::expect_equal(
    recorded$arguments[[1]],
    matrix(c(
      0.0833333333333333,
      0.703712207439821,
      0.457393938869548,
      0.916666666666667
    ), ncol = 1L),
    tolerance = 1e-14
  )
  testthat::expect_equal(
    fit$Omega,
    matrix(c(-0.2, 2.2), nrow = 1L),
    tolerance = 1e-15
  )
})

testthat::test_that("constant columns currently warn and become non-finite", {
  wrapper <- make_wrapper_environment()
  recorded <- new.env(parent = emptyenv())
  wrapper$do_boosting <- function(...) {
    recorded$arguments <- list(...)
    list()
  }

  set.seed(42)
  testthat::expect_warning(
    invisible(capture.output(
      fit <- wrapper$boosting(
        matrix(rep(1, 4), ncol = 1L),
        ntree_max_marginal = 0,
        ntree_max_dependence = 0
      )
    )),
    "NAs produced"
  )

  testthat::expect_true(all(is.nan(recorded$arguments[[1]])))
  testthat::expect_true(all(is.nan(fit$Omega)))
})

testthat::test_that("post-processing wrappers preserve low-level argument order", {
  wrapper <- make_wrapper_environment()
  recorded <- new.env(parent = emptyenv())
  fit <- list(tree_list = list("tree"), Omega = matrix(c(0, 1), nrow = 1L))

  wrapper$simulation <- function(tree_list, size_simulation, support) {
    recorded$simulation <- list(tree_list, size_simulation, support)
    matrix(0.25, nrow = size_simulation, ncol = 1L)
  }
  wrapper$evaluate_log_density <- function(tree_list, eval_points, support) {
    recorded$density <- list(tree_list, eval_points, support)
    list(log_densities = 1:2, mean_log_dens_path = 3:4)
  }

  simulated <- wrapper$simulation_b(fit, 2L)
  density <- wrapper$eval_density_b(fit, matrix(c(0.2, 0.8), ncol = 1L))

  testthat::expect_identical(recorded$simulation, list(
    fit$tree_list, 2L, fit$Omega
  ))
  testthat::expect_identical(simulated, matrix(0.25, nrow = 2L, ncol = 1L))
  testthat::expect_identical(names(density), c("log_densities", "mean_log_dens_path"))
  testthat::expect_identical(density$log_densities, 1:2)
  testthat::expect_identical(density$mean_log_dens_path, 3:4)
})

