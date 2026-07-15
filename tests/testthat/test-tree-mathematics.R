testthat::test_that("one-split density agrees with hand calculation", {
  fit <- make_one_split_fit(theta = 0.25, location = 0.5)
  points <- matrix(c(0.25, 0.75), ncol = 1L)

  result <- stats::predict(fit, points, type = "details")

  testthat::expect_equal(
    as.numeric(result$log_densities),
    log(c(0.25 / 0.5, 0.75 / 0.5)),
    tolerance = 1e-15
  )
  testthat::expect_equal(
    as.numeric(result$mean_log_dens_path),
    mean(log(c(0.5, 1.5))),
    tolerance = 1e-15
  )
})

testthat::test_that("one-split inverse transform agrees with hand calculation", {
  fit <- make_one_split_fit(theta = 0.25, location = 0.5)

  set.seed(101)
  uniforms <- runif(5)
  expected <- ifelse(
    uniforms < 0.25,
    2 * uniforms,
    0.5 + (2 / 3) * (uniforms - 0.25)
  )

  set.seed(101)
  simulated <- stats::simulate(fit, nsim = 5L)

  testthat::expect_equal(as.numeric(simulated), expected, tolerance = 1e-15)
})

testthat::test_that("two-tree density uses residual composition order", {
  fit <- structure(list(
    tree_list = list(
      make_one_split_fit(theta = 0.25)$tree_list[[1]],
      make_one_split_fit(theta = 0.75)$tree_list[[1]]
    ),
    Omega = matrix(c(0, 1), nrow = 1L)
  ), class = c("boostPM_fit", "list"))

  result <- stats::predict(
    fit,
    matrix(c(0.2, 0.8), ncol = 1L),
    type = "details"
  )

  testthat::expect_equal(
    as.numeric(result$log_densities),
    rep(log(0.75), 2L),
    tolerance = 1e-15
  )
  testthat::expect_equal(
    as.numeric(result$mean_log_dens_path),
    c(mean(log(c(0.5, 1.5))), log(0.75)),
    tolerance = 1e-15
  )
})

testthat::test_that("support Jacobian is subtracted on the original scale", {
  fit <- make_one_split_fit(
    theta = 0.25,
    location = 0.5,
    support = matrix(c(10, 14), nrow = 1L)
  )
  points <- matrix(c(11, 13), ncol = 1L)

  result <- stats::predict(fit, points, type = "details")

  testthat::expect_equal(
    as.numeric(result$log_densities),
    log(c(0.5, 1.5)) - log(4),
    tolerance = 1e-15
  )
})
