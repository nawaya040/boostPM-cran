testthat::test_that("fit arguments follow the documented public order", {
  testthat::expect_identical(
    names(formals(boostPM::fit_boostpm)),
    c(
      "data", "Omega", "max_marginal_trees", "max_dependence_trees",
      "n_bins", "max_split_depth", "min_node_observations",
      "c0", "gamma", "early_stop", "prior_split_prob",
      "add_noise", "progress"
    )
  )
})

testthat::test_that("new public API returns documented prediction types", {
  fit <- list(
    trees = list(list(
      d = c(0L, -1L, -1L),
      l = c(0.5, -1, -1),
      theta = c(0.25, -1, -1)
    )),
    support = matrix(c(0, 1), nrow = 1L)
  )
  class(fit) <- c("boostPM_fit", "list")
  points <- matrix(c(0.25, 0.75), ncol = 1L)

  log_density <- stats::predict(fit, points, type = "log_density")
  density <- stats::predict(fit, points, type = "density")
  details <- stats::predict(fit, points, type = "details")

  testthat::expect_type(log_density, "double")
  testthat::expect_equal(density, exp(log_density))
  testthat::expect_identical(details$log_density, log_density)
  testthat::expect_identical(
    names(details),
    c("log_density", "mean_log_density_path")
  )
  testthat::expect_equal(
    stats::predict(fit, matrix(-0.1, ncol = 1L), type = "density"),
    0
  )
})

testthat::test_that("provisional function names are absent from the public API", {
  retired <- c("boosting", "eval_density_b", "simulation_b")
  testthat::expect_false(any(retired %in% getNamespaceExports("boostPM")))
  testthat::expect_false(any(vapply(
    retired,
    exists,
    logical(1),
    envir = asNamespace("boostPM"),
    inherits = FALSE
  )))
})

testthat::test_that("progress messages are optional and numerically inert", {
  arguments <- list(
    data = small_two_dimensional_data(),
    add_noise = FALSE,
    Omega = cbind(c(0, 0), c(1, 1)),
    max_marginal_trees = 1,
    max_dependence_trees = 1,
    c0 = 0.1,
    gamma = 0,
    max_split_depth = 1,
    min_node_observations = 2,
    prior_split_prob = 0.9,
    n_bins = 4
  )

  set.seed(20240714)
  silent_output <- capture.output(
    silent_fit <- do.call(
      boostPM::fit_boostpm,
      c(arguments, list(progress = "none"))
    )
  )
  set.seed(20240714)
  stage_output <- capture.output(
    stage_fit <- do.call(
      boostPM::fit_boostpm,
      c(arguments, list(progress = "stage"))
    )
  )

  testthat::expect_length(silent_output, 0L)
  testthat::expect_identical(
    stage_output,
    c(
      "Fitting marginal distribution 1 of 2",
      "Fitting marginal distribution 2 of 2",
      "Fitting dependence structure"
    )
  )

  fields <- c(
    "residual_coordinates", "tree_diagnostics", "variable_importance",
    "trees", "heldout_diagnostics", "support"
  )
  testthat::expect_identical(silent_fit[fields], stage_fit[fields])
})

testthat::test_that("boostPM fit methods provide compact diagnostics", {
  fit <- list(
    trees = list(list(), list()),
    residual_coordinates = matrix(0, nrow = 2L, ncol = 4L),
    tree_diagnostics = data.frame(
      tree_index = 1:2,
      stage = c("marginal", "dependence"),
      variable = c("x1", NA_character_),
      node_count = c(3L, 5L),
      max_depth = c(1L, 2L)
    ),
    variable_importance = c(x1 = 0.7, x2 = 0.3),
    heldout_diagnostics = NULL,
    support = structure(
      cbind(lower = c(0, 0), upper = c(1, 1)),
      dimnames = list(c("x1", "x2"), c("lower", "upper"))
    ),
    elapsed_time = structure(0.25, units = "secs", class = "difftime"),
    call = quote(fit_boostpm(data)),
    control = list()
  )
  class(fit) <- c("boostPM_fit", "list")

  summarized <- summary(fit)
  testthat::expect_s3_class(summarized, "summary.boostPM_fit")
  testthat::expect_identical(summarized$n_observations, 4L)
  testthat::expect_identical(summarized$n_variables, 2L)
  testthat::expect_identical(summarized$n_trees, 2L)
  testthat::expect_identical(summarized$call, fit$call)
  testthat::expect_identical(summarized$tree_diagnostics, fit$tree_diagnostics)

  output <- capture.output(print(fit))
  testthat::expect_true(any(grepl("boostPM fit", output, fixed = TRUE)))
  testthat::expect_true(any(grepl("Elapsed time:", output, fixed = TRUE)))
  testthat::expect_true(any(grepl("x1 =", output, fixed = TRUE)))

  summary_output <- capture.output(print(summarized))
  testthat::expect_true(any(grepl("Call:", summary_output, fixed = TRUE)))
  testthat::expect_true(any(grepl("Support:", summary_output, fixed = TRUE)))
  testthat::expect_true(any(grepl("Nodes per tree:", summary_output, fixed = TRUE)))
  testthat::expect_true(any(grepl("Maximum tree depth:", summary_output, fixed = TRUE)))

  pdf_file <- tempfile(fileext = ".pdf")
  grDevices::pdf(pdf_file)
  on.exit(grDevices::dev.off(), add = TRUE)
  testthat::expect_silent(plot(fit))
  testthat::expect_silent(plot(fit, type = "tree_node_counts"))
  testthat::expect_silent(plot(fit, type = "tree_depths"))
  testthat::expect_silent(plot(fit, ylab = "Custom label", names.arg = c("a", "b")))
  testthat::expect_error(
    plot(fit, height = c(1, 2)),
    "computed diagnostic values"
  )

  testthat::expect_identical(print(summarized), summarized)
})

testthat::test_that("simulation preserves fitted variable names", {
  fit <- make_one_split_fit()
  fit$variable_importance <- c(measurement = 0)

  simulated <- stats::simulate(fit, nsim = 3L, seed = 1L)

  testthat::expect_identical(colnames(simulated), "measurement")
})

testthat::test_that("fit objects use stable descriptive component names", {
  data <- small_two_dimensional_data()
  colnames(data) <- c("x1", "x2")

  set.seed(20240714)
  fit <- boostPM::fit_boostpm(
    data,
    Omega = cbind(c(0, 0), c(1, 1)),
    add_noise = FALSE,
    max_marginal_trees = 1,
    max_dependence_trees = 1,
    n_bins = 4,
    c0 = 0.1,
    gamma = 0,
    early_stop = NULL,
    max_split_depth = 1,
    min_node_observations = 2,
    prior_split_prob = 0.9,
    progress = "none"
  )

  testthat::expect_identical(names(fit), c(
    "trees", "residual_coordinates", "tree_diagnostics",
    "variable_importance", "heldout_diagnostics", "support",
    "elapsed_time", "call", "control"
  ))
  testthat::expect_named(fit$variable_importance, c("x1", "x2"))
  testthat::expect_null(fit$heldout_diagnostics)
  testthat::expect_identical(rownames(fit$support), c("x1", "x2"))
  testthat::expect_identical(colnames(fit$support), c("lower", "upper"))
  testthat::expect_s3_class(fit$elapsed_time, "difftime")
  testthat::expect_match(
    paste(deparse(fit$call), collapse = " "),
    "fit_boostpm",
    fixed = TRUE
  )
  testthat::expect_identical(fit$control, list(
    max_marginal_trees = 1L,
    max_dependence_trees = 1L,
    n_bins = 4L,
    max_split_depth = 1L,
    min_node_observations = 2L,
    c0 = 0.1,
    gamma = 0,
    early_stop = NULL,
    prior_split_prob = 0.9,
    add_noise = FALSE,
    progress = "none"
  ))

  testthat::expect_identical(
    names(fit$tree_diagnostics),
    c("tree_index", "stage", "variable", "node_count", "max_depth")
  )
  testthat::expect_identical(
    fit$tree_diagnostics$stage,
    c("marginal", "marginal", "dependence")
  )

  old_names <- c(
    "tree_list", "residuals_boosting", "tree_size_store",
    "max_depth_store", "improvement_curve", "Omega", "time",
    "tree_node_counts", "tree_depths", "heldout_log_improvements"
  )
  testthat::expect_false(any(old_names %in% names(fit)))
})
