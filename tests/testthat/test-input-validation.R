minimal_fit_arguments <- function() {
  list(
    data = matrix(c(0.25, 0.75), ncol = 1L),
    add_noise = FALSE,
    Omega = matrix(c(0, 1), nrow = 1L),
    ntree_max_marginal = 0,
    ntree_max_dependence = 0
  )
}

testthat::test_that("boosting validates the data matrix", {
  arguments <- minimal_fit_arguments()

  testthat::expect_error(
    do.call(boostPM::boosting, utils::modifyList(arguments, list(data = 1:3))),
    "numeric matrix"
  )
  testthat::expect_error(
    do.call(
      boostPM::boosting,
      utils::modifyList(arguments, list(data = matrix(numeric(), ncol = 1L)))
    ),
    "at least one row"
  )
  testthat::expect_error(
    do.call(
      boostPM::boosting,
      utils::modifyList(arguments, list(data = matrix(c(0, Inf), ncol = 1L)))
    ),
    "finite values"
  )
})

testthat::test_that("boosting validates support structure", {
  arguments <- minimal_fit_arguments()

  testthat::expect_error(
    do.call(
      boostPM::boosting,
      utils::modifyList(arguments, list(Omega = matrix(c(0, 1, 2), nrow = 1L)))
    ),
    "exactly two columns"
  )
  testthat::expect_error(
    do.call(
      boostPM::boosting,
      utils::modifyList(arguments, list(Omega = matrix(c(0, 0), nrow = 1L)))
    ),
    "lower bound below"
  )
  testthat::expect_error(
    do.call(
      boostPM::boosting,
      utils::modifyList(
        arguments,
        list(Omega = cbind(c(0, 0), c(1, 1)))
      )
    ),
    "one row for each column"
  )
})

testthat::test_that("boosting validates structural controls", {
  arguments <- minimal_fit_arguments()

  invalid_controls <- list(
    add_noise = NA,
    ntree_max_marginal = -1,
    ntree_max_dependence = 0.5,
    max_resol = -1,
    min_obs = 0,
    nbins = 1,
    c0 = Inf,
    gamma = NA_real_,
    alpha = numeric(),
    beta = c(0, 1),
    precision = "one"
  )

  for (name in names(invalid_controls)) {
    call_arguments <- arguments
    call_arguments[[name]] <- invalid_controls[[name]]
    testthat::expect_error(
      do.call(boostPM::boosting, call_arguments),
      name,
      fixed = TRUE,
      info = name
    )
  }
})

testthat::test_that("boosting validates statistical parameter domains", {
  arguments <- minimal_fit_arguments()

  invalid_parameters <- list(
    c0 = c(0, 1, -0.1, 1.1),
    gamma = -0.1,
    alpha = c(-0.1, 1.1),
    beta = -0.1,
    precision = c(0, -1)
  )

  for (name in names(invalid_parameters)) {
    for (value in invalid_parameters[[name]]) {
      call_arguments <- arguments
      call_arguments[[name]] <- value
      testthat::expect_error(
        do.call(boostPM::boosting, call_arguments),
        name,
        fixed = TRUE,
        info = paste(name, value)
      )
    }
  }

  for (alpha in c(0, 1)) {
    call_arguments <- arguments
    call_arguments$alpha <- alpha
    testthat::expect_no_error({
      output <- utils::capture.output(do.call(boostPM::boosting, call_arguments))
    })
  }
})

testthat::test_that("boosting rejects constant columns", {
  arguments <- minimal_fit_arguments()
  arguments$data <- cbind(c(0.25, 0.75), c(1, 1))
  arguments$Omega <- cbind(c(0, 0), c(1, 2))

  testthat::expect_error(
    do.call(boostPM::boosting, arguments),
    "constant column"
  )
})

testthat::test_that("jittered observations must remain inside supplied support", {
  arguments <- minimal_fit_arguments()
  arguments$data <- matrix(c(0.01, 0.01, 1), ncol = 1L)
  arguments$add_noise <- TRUE
  arguments$Omega <- matrix(c(0, 2), nrow = 1L)

  set.seed(1)
  testthat::expect_error(
    do.call(boostPM::boosting, arguments),
    "Jittered observations"
  )
})

testthat::test_that("experimental max_n_var argument is removed", {
  testthat::expect_false("max_n_var" %in% names(formals(boostPM::boosting)))
})

testthat::test_that("boosting validates early stopping controls", {
  arguments <- minimal_fit_arguments()

  for (value in list(1, c(0, 2, 3), c(NA, 2), c(0, 1), c(0, 2.5))) {
    call_arguments <- arguments
    call_arguments$early_stop <- value
    testthat::expect_error(
      do.call(boostPM::boosting, call_arguments),
      "early_stop",
      fixed = TRUE
    )
  }

  testthat::expect_no_error({
    output <- utils::capture.output(do.call(
      boostPM::boosting,
      utils::modifyList(arguments, list(early_stop = c(-0.01, 2)))
    ))
  })

  one_row <- arguments
  one_row$data <- matrix(0.5, ncol = 1L)
  one_row$ntree_max_marginal <- 1
  one_row$early_stop <- c(0, 2)
  testthat::expect_error(
    do.call(boostPM::boosting, one_row),
    "at least two data rows"
  )
})

testthat::test_that("post-processing validates fitted objects", {
  valid_fit <- list(
    tree_list = list(),
    Omega = matrix(c(0, 1), nrow = 1L)
  )

  testthat::expect_error(
    boostPM::simulation_b(NULL, 1),
    "fitted object"
  )
  testthat::expect_error(
    boostPM::simulation_b(list(tree_list = list()), 1),
    "missing required component"
  )
  testthat::expect_error(
    boostPM::simulation_b(list(tree_list = 1, Omega = valid_fit$Omega), 1),
    "tree_list"
  )
})

testthat::test_that("simulation validates its requested size", {
  fit <- list(tree_list = list(), Omega = matrix(c(0, 1), nrow = 1L))

  for (size in list(-1, 1.5, Inf, c(1, 2), "1")) {
    testthat::expect_error(
      boostPM::simulation_b(fit, size),
      "size",
      fixed = TRUE
    )
  }

  set.seed(1)
  testthat::expect_identical(
    boostPM::simulation_b(fit, 0),
    matrix(numeric(), nrow = 0L, ncol = 1L)
  )
})

testthat::test_that("density evaluation validates its point matrix", {
  fit <- list(
    tree_list = list(),
    Omega = cbind(c(0, 0), c(1, 1))
  )

  testthat::expect_error(
    boostPM::eval_density_b(fit, c(0.5, 0.5)),
    "numeric matrix"
  )
  testthat::expect_error(
    boostPM::eval_density_b(fit, matrix(0.5, ncol = 1L)),
    "one column for each row"
  )
  testthat::expect_error(
    boostPM::eval_density_b(fit, matrix(c(0.5, NA), nrow = 1L)),
    "finite values"
  )
})
