testthat::test_that("max_resol zero currently creates depth-one leaves", {
  set.seed(10)
  invisible(capture.output(
    fit <- boostPM::boosting(
      matrix(c(0.1, 0.3, 0.7, 0.9), ncol = 1L),
      add_noise = FALSE,
      Omega = matrix(c(0, 1), nrow = 1L),
      ntree_max_marginal = 1,
      ntree_max_dependence = 0,
      c0 = 0.1,
      gamma = 0,
      max_resol = 0,
      min_obs = 1,
      alpha = 1,
      beta = 0,
      nbins = 2,
      max_n_var = 1
    )
  ))

  testthat::expect_identical(fit$tree_size_store, 3L)
  testthat::expect_identical(fit$max_depth_store, 1L)
})

testthat::test_that("split equality is trained right but evaluated left", {
  set.seed(11)
  invisible(capture.output(
    fit <- boostPM::boosting(
      matrix(c(0.25, 0.5, 0.75), ncol = 1L),
      add_noise = FALSE,
      Omega = matrix(c(0, 1), nrow = 1L),
      ntree_max_marginal = 1,
      ntree_max_dependence = 0,
      c0 = 1,
      gamma = 0,
      max_resol = 0,
      min_obs = 1,
      alpha = 1,
      beta = 0,
      nbins = 2,
      max_n_var = 1
    )
  ))

  testthat::expect_equal(fit$tree_list[[1]]$theta[[1]], 1 / 3, tolerance = 1e-15)
  expected_importance <-
    (1 / 3) * log((1 / 3) / 0.5) +
    (2 / 3) * log((2 / 3) / 0.5)
  testthat::expect_lte(
    abs(as.numeric(fit$variable_importance) - expected_importance),
    1e-15
  )

  at_boundary <- boostPM::eval_density_b(fit, matrix(0.5, ncol = 1L))
  testthat::expect_equal(
    as.numeric(at_boundary$log_densities),
    log((1 / 3) / 0.5),
    tolerance = 1e-15
  )
})

testthat::test_that("density outside Omega is currently finite", {
  fit <- make_one_split_fit(theta = 0.25, location = 0.5)
  outside <- matrix(c(-0.1, 1.1), ncol = 1L)

  result <- boostPM::eval_density_b(fit, outside)

  testthat::expect_true(all(is.finite(result$log_densities)))
  testthat::expect_equal(
    as.numeric(result$log_densities),
    log(c(0.5, 1.5)),
    tolerance = 1e-15
  )
})

testthat::test_that("a rejected early-stopping tree is not stored or applied", {
  data <- small_two_dimensional_data()
  set.seed(12)
  invisible(capture.output(
    fit <- boostPM::boosting(
      data,
      add_noise = FALSE,
      Omega = cbind(c(0, 0), c(1, 1)),
      ntree_max_marginal = 5,
      ntree_max_dependence = 5,
      c0 = 0.1,
      gamma = 0,
      max_resol = 1,
      min_obs = 1,
      early_stop = c(200, 2),
      alpha = 0.9,
      beta = 0,
      nbins = 4,
      max_n_var = 2
    )
  ))

  testthat::expect_length(fit$tree_list, 0L)
  testthat::expect_length(fit$tree_size_store, 0L)
  testthat::expect_length(fit$max_depth_store, 0L)
  testthat::expect_length(fit$improvement_curve, 3L)
  testthat::expect_equal(fit$residuals_boosting, t(data), tolerance = 1e-15)
})
