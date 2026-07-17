#' Fit a boostPM Distribution
#'
#' Fits the unsupervised tree boosting procedure of Awaya and Ma (2024).
#' Marginal trees are fitted first, followed by dependence trees. The fitted
#' ensemble represents a probability distribution on a rectangular support.
#'
#' @param data A finite numeric matrix with observations in rows and variables
#'   in columns. Missing, infinite, and constant columns are not supported.
#' @param Omega Either `NULL`, or a finite numeric matrix with one row per
#'   variable and two columns giving lower and upper support limits. Training
#'   observations must lie strictly inside supplied limits. If `NULL`, the
#'   processed range of each variable is expanded by 10 percent on both sides.
#' @param max_marginal_trees Non-negative integer giving the maximum number of
#'   trees fitted for each marginal distribution. Set to zero to skip marginal
#'   fitting.
#' @param max_dependence_trees Non-negative integer giving the maximum number
#'   of trees fitted to the dependence structure after marginal fitting. Set
#'   to zero to skip this stage.
#' @param n_bins Integer of at least two. Candidate split fractions are
#'   `1 / n_bins, ..., (n_bins - 1) / n_bins`, so the number of interior
#'   candidates is `n_bins - 1`. Larger values provide a finer search at
#'   greater computational cost.
#' @param max_split_depth Non-negative integer giving the deepest node depth
#'   that remains eligible for splitting. Consequently, terminal leaves may
#'   occur at depth `max_split_depth + 1`.
#' @param min_node_observations Positive integer. A node containing fewer than
#'   `min_node_observations` fitting observations is not split; a node
#'   containing exactly `min_node_observations` observations remains eligible.
#' @param c0 Global learning rate, strictly between zero and one. Larger values
#'   move each fitted node mass more strongly toward the empirical residual
#'   distribution and therefore apply less shrinkage.
#' @param gamma Non-negative scale-specific learning-rate exponent. Zero gives
#'   the constant learning rate `c0`; larger values reduce the learning rate
#'   more strongly in small-volume nodes.
#' @param early_stop Either `NULL`, or `c(threshold, window)`, where `threshold`
#'   is finite and `window` is an integer of at least two. See
#'   **Adaptive stopping** for the held-out evaluation rule.
#' @param prior_split_prob Numeric value in `[0, 1]` giving the prior
#'   probability of splitting a node before candidate marginal likelihoods are
#'   considered. It is constant across depths and is not the posterior or
#'   realized split frequency.
#' @param add_noise A single logical value. If `TRUE`, tied observations are
#'   perturbed before fitting using R's random-number generator and spacings
#'   between adjacent distinct values.
#' @param progress Character string controlling progress messages. `"none"`
#'   suppresses progress output and `"stage"` reports each marginal fitting
#'   stage and the dependence stage.
#'
#' @return An object of class `boostPM_fit`, represented as a list containing:
#' \describe{
#'   \item{trees}{Serialized fitted trees used by package methods. This is an
#'   internal representation and is not a stable interface for direct editing.}
#'   \item{residual_coordinates}{Final residual coordinates as a
#'   variables-by-observations numeric matrix. This advanced diagnostic is not
#'   intended for direct modification.}
#'   \item{tree_diagnostics}{A data frame with one row per accepted tree and
#'   columns `tree_index`, `stage`, `variable`, `node_count`, and `max_depth`.
#'   `stage` is `"marginal"` or `"dependence"`; `variable` identifies the
#'   marginal variable and is `NA` for dependence trees.}
#'   \item{variable_importance}{Unnormalized accumulated splitting improvement
#'   attributed to each variable. Larger values indicate greater contribution
#'   within the fitted ensemble. The vector is named when `data` has column
#'   names.}
#'   \item{heldout_diagnostics}{A data frame with one row per held-out
#'   candidate and columns `candidate_index`, `stage`, `variable`,
#'   `mean_log_density_improvement`, and `accepted`, or `NULL` when
#'   `early_stop = NULL`. The candidate that triggers stopping has
#'   `accepted = FALSE`.}
#'   \item{support}{A variables-by-two matrix containing named `lower` and
#'   `upper` original-scale support limits. Row names follow the training
#'   variable names when available.}
#'   \item{elapsed_time}{Elapsed fitting time as a `difftime` object.}
#'   \item{call}{The matched call used to fit the model.}
#'   \item{control}{A named list of the validated controls actually used:
#'   `max_marginal_trees`, `max_dependence_trees`, `n_bins`,
#'   `max_split_depth`, `min_node_observations`, `c0`, `gamma`, `early_stop`,
#'   `prior_split_prob`, `add_noise`, and `progress`.}
#' }
#'
#' @section Fitting stages:
#' The procedure first fits up to `max_marginal_trees` univariate trees for
#' each variable. It then fits up to `max_dependence_trees` multivariate trees
#' to the remaining dependence structure. These arguments are upper bounds;
#' adaptive stopping can end a stage earlier.
#'
#' @section Scale-specific learning rate:
#' For a node \eqn{A} in the normalized unit cube, the learning rate is
#' \deqn{c(A) = c_0 (1 - \log_2[\mathrm{vol}(A)])^{-\gamma}.}
#' Thus `c0` determines the global update size. When `gamma = 0`, every node
#' uses `c0`. When `gamma > 0`, smaller-volume nodes receive smaller updates,
#' which imposes stronger shrinkage on local structure.
#'
#' @section Adaptive stopping:
#' If `early_stop = NULL`, all observations fit each candidate tree and no
#' adaptive stopping is applied. With `early_stop = c(threshold, window)`, each
#' candidate tree is fitted to a random 90 percent subset of the current
#' residuals and evaluated by its average log density on the held-out 10
#' percent. A stage ends when the mean of the most recent `window` held-out
#' scores is strictly below `threshold`. The candidate that triggers stopping
#' is recorded in `heldout_diagnostics` with `accepted = FALSE` but is not added
#' to the ensemble.
#' `c(0, 50)` is the paper-oriented setting; the implementation uses a strict
#' comparison with zero, whereas the paper describes non-positive improvement.
#'
#' @section Support and tied observations:
#' Data are transformed from `Omega` to the unit cube before fitting. If
#' `Omega = NULL`, the range after optional tie perturbation is expanded by 10
#' percent on each side. Set `add_noise = TRUE` when a continuous distribution
#' is assumed and ties are technical artifacts such as rounding. Set it to
#' `FALSE` when perturbing ties would be inappropriate.
#'
#' @section Split prior:
#' The default `prior_split_prob = 0.9` follows the archived implementation and
#' public experiment code. Setting `prior_split_prob = 0.5` corresponds to the
#' constant split prior implied by the 0.5 stopping probability reported in
#' Appendix C of Awaya and Ma (2024). Larger values favor splitting before the
#' data-dependent candidate likelihoods are incorporated.
#'
#' @section Reproducibility and progress:
#' Tree construction is stochastic even when `add_noise = FALSE`, and adaptive
#' stopping also draws random fitting subsets. Call [set.seed()] before every
#' fit that must be reproducible. Fitting is silent by default; set
#' `progress = "stage"` for stage-level messages. Elapsed time is stored in the
#' result and can be inspected with [print()] or [summary()]. Exact equality
#' across operating systems has not been established.
#'
#' @references
#' Awaya, N. and Ma, L. (2024). Unsupervised Tree Boosting for Learning
#' Probability Distributions. *Journal of Machine Learning Research*, 25,
#' 1--52.
#'
#' @examples
#' set.seed(42)
#' n <- 400L
#' x1 <- stats::rbeta(n, shape1 = 2, shape2 = 5)
#' x2 <- stats::rbeta(n, shape1 = 2 + 6 * x1, shape2 = 4)
#' x <- cbind(x1 = x1, x2 = x2)
#' support <- cbind(lower = c(0, 0), upper = c(1, 1))
#'
#' set.seed(123)
#' fit <- fit_boostpm(
#'   x,
#'   Omega = support,
#'   max_marginal_trees = 100,
#'   max_dependence_trees = 1000,
#'   n_bins = 100,
#'   max_split_depth = 15,
#'   min_node_observations = 10,
#'   c0 = 0.1,
#'   gamma = 0.5,
#'   add_noise = FALSE
#' )
#' print(fit)
#'
#' grid <- seq(0.01, 0.99, length.out = 50L)
#' evaluation_grid <- as.matrix(expand.grid(x1 = grid, x2 = grid))
#' fitted_density <- matrix(
#'   predict(fit, newdata = evaluation_grid, type = "density"),
#'   nrow = length(grid)
#' )
#' graphics::image(grid, grid, fitted_density, xlab = "x1", ylab = "x2")
#' graphics::contour(
#'   grid, grid, fitted_density, add = TRUE, drawlabels = FALSE
#' )
#'
#' generated <- simulate(fit, nsim = 500, seed = 321)
#' graphics::plot(
#'   generated, xlab = "x1", ylab = "x2", main = "Generated observations"
#' )
#'
#' @export
#' @md
fit_boostpm <- function(data,
                     Omega = NULL,
                     max_marginal_trees = 100,
                     max_dependence_trees = 1000,
                     n_bins = 8,
                     max_split_depth = 15,
                     min_node_observations = 5,
                     c0 = 0.1,
                     gamma = 0.1,
                     early_stop = NULL,
                     prior_split_prob = 0.9,
                     add_noise = TRUE,
                     progress = c("none", "stage")) {
  fit_call <- match.call()
  variable_names <- colnames(data)
  progress <- tryCatch(
    match.arg(progress),
    error = function(cnd) {
      .boostpm_stop_invalid(
        "`progress` must be one of \"none\" or \"stage\"."
      )
    }
  )
  .boostpm_validate_numeric_matrix(data, "data")
  if (!is.null(Omega)) {
    .boostpm_validate_support(Omega, dimension = ncol(data))
  }
  .boostpm_validate_fit_controls(
    max_marginal_trees = max_marginal_trees,
    max_dependence_trees = max_dependence_trees,
    n_bins = n_bins,
    max_split_depth = max_split_depth,
    min_node_observations = min_node_observations,
    c0 = c0,
    gamma = gamma,
    early_stop = early_stop,
    prior_split_prob = prior_split_prob,
    add_noise = add_noise
  )
  if (!is.null(early_stop) &&
      (max_marginal_trees > 0L || max_dependence_trees > 0L) &&
      nrow(data) < 2L) {
    .boostpm_stop_invalid(
      "`early_stop` requires at least two data rows when a tree may be fitted."
    )
  }

  processed <- .boostpm_preprocess(data, add_noise, Omega)
  x_new <- processed$data
  Omega <- processed$Omega
  colnames(Omega) <- c("lower", "upper")
  if (!is.null(variable_names)) {
    rownames(Omega) <- variable_names
  }
  stopping <- .boostpm_early_stop_controls(early_stop)
  control <- list(
    max_marginal_trees = as.integer(max_marginal_trees),
    max_dependence_trees = as.integer(max_dependence_trees),
    n_bins = as.integer(n_bins),
    max_split_depth = as.integer(max_split_depth),
    min_node_observations = as.integer(min_node_observations),
    c0 = as.numeric(c0),
    gamma = as.numeric(gamma),
    early_stop = if (is.null(early_stop)) {
      NULL
    } else {
      c(
        threshold = as.numeric(early_stop[1L]),
        window = as.integer(early_stop[2L])
      )
    },
    prior_split_prob = as.numeric(prior_split_prob),
    add_noise = add_noise,
    progress = progress
  )

  start_time <- Sys.time()

  internal_out <- do_boosting(
    x_new,
    prior_split_prob,
    gamma,
    max_split_depth,
    max_marginal_trees,
    max_dependence_trees,
    c0,
    min_node_observations,
    n_bins,
    stopping$eta_subsample,
    stopping$thresh_stop,
    stopping$ntrees_wait,
    identical(progress, "stage")
  )

  end_time <- Sys.time()
  importance <- as.numeric(internal_out$variable_importance)
  if (!is.null(variable_names)) {
    names(importance) <- variable_names
  }
  diagnostic_variable_names <- if (is.null(variable_names)) {
    paste0("V", seq_len(ncol(data)))
  } else {
    variable_names
  }
  tree_stage <- .boostpm_stage_metadata(
    internal_out$tree_stage,
    ncol(data),
    diagnostic_variable_names
  )
  tree_diagnostics <- data.frame(
    tree_index = seq_along(internal_out$tree_list),
    stage = tree_stage$stage,
    variable = tree_stage$variable,
    node_count = as.integer(internal_out$tree_size_store),
    max_depth = as.integer(internal_out$max_depth_store),
    stringsAsFactors = FALSE
  )
  heldout_diagnostics <- if (
    "improvement_curve" %in% names(internal_out)
  ) {
    heldout_stage <- .boostpm_stage_metadata(
      internal_out$improvement_stage,
      ncol(data),
      diagnostic_variable_names
    )
    data.frame(
      candidate_index = seq_along(internal_out$improvement_curve),
      stage = heldout_stage$stage,
      variable = heldout_stage$variable,
      mean_log_density_improvement = as.numeric(internal_out$improvement_curve),
      accepted = as.logical(internal_out$improvement_accepted),
      stringsAsFactors = FALSE
    )
  } else {
    NULL
  }
  out <- list(
    trees = internal_out$tree_list,
    residual_coordinates = internal_out$residuals_boosting,
    tree_diagnostics = tree_diagnostics,
    variable_importance = importance,
    heldout_diagnostics = heldout_diagnostics,
    support = Omega,
    elapsed_time = end_time - start_time,
    call = fit_call,
    control = control
  )
  class(out) <- c("boostPM_fit", "list")

  out
}

.boostpm_stage_metadata <- function(stage_codes, dimension, variable_names) {
  stage_codes <- as.integer(stage_codes)
  stage <- rep("dependence", length(stage_codes))
  variable <- rep(NA_character_, length(stage_codes))
  marginal <- stage_codes < dimension
  stage[marginal] <- "marginal"
  variable[marginal] <- variable_names[stage_codes[marginal] + 1L]

  list(stage = stage, variable = variable)
}
