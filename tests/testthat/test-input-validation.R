minimal_fit_arguments <- function() {
  list(
    data = matrix(c(0.25, 0.75), ncol = 1L),
    add_noise = FALSE,
    Omega = matrix(c(0, 1), nrow = 1L),
    ntree_max_marginal = 0,
    ntree_max_dependence = 0
  )
}

testthat::test_that("fit_boostpm validates the data matrix", {
  arguments <- minimal_fit_arguments()

  testthat::expect_error(
    do.call(boostPM::fit_boostpm, utils::modifyList(arguments, list(data = 1:3))),
    "numeric matrix"
  )
  testthat::expect_error(
    do.call(
      boostPM::fit_boostpm,
      utils::modifyList(arguments, list(data = matrix(numeric(), ncol = 1L)))
    ),
    "at least one row"
  )
  testthat::expect_error(
    do.call(
      boostPM::fit_boostpm,
      utils::modifyList(arguments, list(data = matrix(c(0, Inf), ncol = 1L)))
    ),
    "finite values"
  )
})

testthat::test_that("fit_boostpm validates support structure", {
  arguments <- minimal_fit_arguments()

  testthat::expect_error(
    do.call(
      boostPM::fit_boostpm,
      utils::modifyList(arguments, list(Omega = matrix(c(0, 1, 2), nrow = 1L)))
    ),
    "exactly two columns"
  )
  testthat::expect_error(
    do.call(
      boostPM::fit_boostpm,
      utils::modifyList(arguments, list(Omega = matrix(c(0, 0), nrow = 1L)))
    ),
    "lower bound below"
  )
  testthat::expect_error(
    do.call(
      boostPM::fit_boostpm,
      utils::modifyList(
        arguments,
        list(Omega = cbind(c(0, 0), c(1, 1)))
      )
    ),
    "one row for each column"
  )
})

testthat::test_that("fit_boostpm validates structural controls", {
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
    prior_split_prob = numeric()
  )

  for (name in names(invalid_controls)) {
    call_arguments <- arguments
    call_arguments[[name]] <- invalid_controls[[name]]
    testthat::expect_error(
      do.call(boostPM::fit_boostpm, call_arguments),
      name,
      fixed = TRUE,
      info = name
    )
  }

  testthat::expect_error(
    do.call(
      boostPM::fit_boostpm,
      utils::modifyList(arguments, list(progress = "bar"))
    ),
    "progress"
  )
})

testthat::test_that("fit_boostpm validates statistical parameter domains", {
  arguments <- minimal_fit_arguments()

  invalid_parameters <- list(
    c0 = c(0, 1, -0.1, 1.1),
    gamma = -0.1,
    prior_split_prob = c(-0.1, 1.1)
  )

  for (name in names(invalid_parameters)) {
    for (value in invalid_parameters[[name]]) {
      call_arguments <- arguments
      call_arguments[[name]] <- value
      testthat::expect_error(
        do.call(boostPM::fit_boostpm, call_arguments),
        name,
        fixed = TRUE,
        info = paste(name, value)
      )
    }
  }

  for (prior_split_prob in c(0, 1)) {
    call_arguments <- arguments
    call_arguments$prior_split_prob <- prior_split_prob
    testthat::expect_no_error(do.call(boostPM::fit_boostpm, call_arguments))
  }
})

testthat::test_that("fit_boostpm rejects constant columns", {
  arguments <- minimal_fit_arguments()
  arguments$data <- cbind(c(0.25, 0.75), c(1, 1))
  arguments$Omega <- cbind(c(0, 0), c(1, 2))

  testthat::expect_error(
    do.call(boostPM::fit_boostpm, arguments),
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
    do.call(boostPM::fit_boostpm, arguments),
    "Jittered observations"
  )
})

testthat::test_that("retired fitting controls are removed", {
  testthat::expect_false(
    "max_n_var" %in% names(formals(boostPM::fit_boostpm))
  )
  testthat::expect_false(
    any(c("alpha", "beta", "precision") %in%
        names(formals(boostPM::fit_boostpm)))
  )
  testthat::expect_identical(
    formals(boostPM::fit_boostpm)$prior_split_prob,
    0.9
  )

  arguments <- minimal_fit_arguments()
  arguments$alpha <- 0.9
  testthat::expect_error(
    do.call(boostPM::fit_boostpm, arguments),
    "unused argument"
  )

  arguments <- minimal_fit_arguments()
  arguments$beta <- 0
  testthat::expect_error(
    do.call(boostPM::fit_boostpm, arguments),
    "unused argument"
  )

  arguments <- minimal_fit_arguments()
  arguments$precision <- 1
  testthat::expect_error(
    do.call(boostPM::fit_boostpm, arguments),
    "unused argument"
  )
})

testthat::test_that("fit_boostpm validates early stopping controls", {
  arguments <- minimal_fit_arguments()

  for (value in list(1, c(0, 2, 3), c(NA, 2), c(0, 1), c(0, 2.5))) {
    call_arguments <- arguments
    call_arguments$early_stop <- value
    testthat::expect_error(
      do.call(boostPM::fit_boostpm, call_arguments),
      "early_stop",
      fixed = TRUE
    )
  }

  testthat::expect_no_error(do.call(
    boostPM::fit_boostpm,
    utils::modifyList(arguments, list(early_stop = c(-0.01, 2)))
  ))

  one_row <- arguments
  one_row$data <- matrix(0.5, ncol = 1L)
  one_row$ntree_max_marginal <- 1
  one_row$early_stop <- c(0, 2)
  testthat::expect_error(
    do.call(boostPM::fit_boostpm, one_row),
    "at least two data rows"
  )
})

testthat::test_that("post-processing validates fitted objects", {
  incomplete <- structure(
    list(tree_list = list()),
    class = c("boostPM_fit", "list")
  )
  malformed <- structure(
    list(tree_list = 1, Omega = matrix(c(0, 1), nrow = 1L)),
    class = c("boostPM_fit", "list")
  )

  testthat::expect_error(
    boostPM:::simulate.boostPM_fit(NULL, 1),
    "fitted object"
  )
  testthat::expect_error(
    stats::simulate(incomplete, nsim = 1),
    "missing required component"
  )
  testthat::expect_error(
    stats::simulate(malformed, nsim = 1),
    "tree_list"
  )
})

testthat::test_that("simulation validates nsim", {
  fit <- structure(
    list(tree_list = list(), Omega = matrix(c(0, 1), nrow = 1L)),
    class = c("boostPM_fit", "list")
  )

  for (nsim in list(-1, 1.5, Inf, c(1, 2), "1")) {
    testthat::expect_error(
      stats::simulate(fit, nsim = nsim),
      "nsim",
      fixed = TRUE
    )
  }

  set.seed(1)
  testthat::expect_identical(
    stats::simulate(fit, nsim = 0),
    matrix(numeric(), nrow = 0L, ncol = 1L)
  )
})

testthat::test_that("density evaluation validates its point matrix", {
  fit <- structure(
    list(tree_list = list(), Omega = cbind(c(0, 0), c(1, 1))),
    class = c("boostPM_fit", "list")
  )

  testthat::expect_error(
    stats::predict(fit, c(0.5, 0.5)),
    "numeric matrix"
  )
  testthat::expect_error(
    stats::predict(fit, matrix(0.5, ncol = 1L)),
    "one column for each row"
  )
  testthat::expect_error(
    stats::predict(fit, matrix(c(0.5, NA), nrow = 1L)),
    "finite values"
  )
})
