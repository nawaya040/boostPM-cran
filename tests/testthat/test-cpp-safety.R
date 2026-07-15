testthat::test_that("post-processing rejects malformed support", {
  fit <- list(tree_list = list(), Omega = matrix(1, nrow = 1L, ncol = 1L))
  testthat::expect_error(
    boostPM::simulation_b(fit, 1L),
    "exactly two columns"
  )

  fit$Omega <- matrix(c(1, 1), nrow = 1L)
  testthat::expect_error(
    boostPM::simulation_b(fit, 1L),
    "positive width"
  )
})

testthat::test_that("simulation rejects negative sizes", {
  fit <- list(tree_list = list(), Omega = matrix(c(0, 1), nrow = 1L))
  testthat::expect_error(
    boostPM::simulation_b(fit, -1L),
    "non-negative"
  )
})

testthat::test_that("fitting handles node boundaries and round-off drift", {
  fit_raw_value <- function(value) {
    invisible(utils::capture.output(
      result <- boostPM:::do_boosting(
        matrix(value, nrow = 1L, ncol = 1L),
        1, 1, 0, 0, 0, 1, 0, 0.1, 1, 2, 1, 1, 100
      )
    ))
    result
  }

  testthat::expect_no_error(right_boundary <- fit_raw_value(1))
  testthat::expect_identical(right_boundary$residuals_boosting, matrix(1))

  drift <- 16 * .Machine$double.eps
  testthat::expect_no_error(above <- fit_raw_value(1 + drift))
  testthat::expect_no_error(below <- fit_raw_value(0 - drift))
  testthat::expect_identical(above$residuals_boosting, matrix(1))
  testthat::expect_identical(below$residuals_boosting, matrix(0))

  testthat::expect_error(
    fit_raw_value(1.01),
    "beyond the floating-point tolerance"
  )
})

testthat::test_that("density evaluation rejects incompatible points", {
  fit <- list(
    tree_list = list(),
    Omega = cbind(c(0, 0), c(1, 1))
  )
  testthat::expect_error(
    boostPM::eval_density_b(fit, matrix(0.5, nrow = 1L, ncol = 1L)),
    "one column per support row"
  )
  testthat::expect_error(
    boostPM::eval_density_b(fit, matrix(c(NA, 0.5), nrow = 1L)),
    "finite values"
  )
})

testthat::test_that("post-processing rejects malformed serialized trees", {
  malformed <- list(
    tree_list = list(list(
      d = c(0L, -1L, -1L),
      l = c(0.5, -1),
      theta = c(0.5, -1, -1)
    )),
    Omega = matrix(c(0, 1), nrow = 1L)
  )
  testthat::expect_error(
    boostPM::simulation_b(malformed, 1L),
    "equal non-zero lengths"
  )

  malformed$tree_list[[1]] <- list(
    d = c(1L, -1L, -1L),
    l = c(0.5, -1, -1),
    theta = c(0.5, -1, -1)
  )
  testthat::expect_error(
    boostPM::eval_density_b(malformed, matrix(0.5, ncol = 1L)),
    "dimension outside the support"
  )
})
