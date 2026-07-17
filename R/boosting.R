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
#' @param add_noise A single logical value. If `TRUE`, tied observations are
#'   perturbed before fitting using R's random-number generator and spacings
#'   between adjacent distinct values.
#' @param ntree_max_marginal Non-negative integer giving the maximum number of
#'   trees fitted for each marginal distribution. Set to zero to skip marginal
#'   fitting.
#' @param ntree_max_dependence Non-negative integer giving the maximum number
#'   of trees fitted to the dependence structure after marginal fitting. Set
#'   to zero to skip this stage.
#' @param nbins Integer of at least two. Candidate split fractions are
#'   `1 / nbins, ..., (nbins - 1) / nbins`, so the number of interior
#'   candidates is `nbins - 1`. Larger values provide a finer search at
#'   greater computational cost.
#' @param c0 Global learning rate, strictly between zero and one. Larger values
#'   move each fitted node mass more strongly toward the empirical residual
#'   distribution and therefore apply less shrinkage.
#' @param gamma Non-negative scale-specific learning-rate exponent. Zero gives
#'   the constant learning rate `c0`; larger values reduce the learning rate
#'   more strongly in small-volume nodes.
#' @param early_stop Either `NULL`, or `c(threshold, window)`, where `threshold`
#'   is finite and `window` is an integer of at least two. See
#'   **Adaptive stopping** for the held-out evaluation rule.
#' @param max_resol Non-negative integer giving the deepest node depth that
#'   remains eligible for splitting. Consequently, terminal leaves may occur
#'   at depth `max_resol + 1`.
#' @param min_obs Positive integer. A node containing fewer than `min_obs`
#'   fitting observations is not split; a node containing exactly `min_obs`
#'   observations remains eligible.
#' @param prior_split_prob Numeric value in `[0, 1]` giving the prior
#'   probability of splitting a node before candidate marginal likelihoods are
#'   considered. It is constant across depths and is not the posterior or
#'   realized split frequency.
#' @param progress Character string controlling progress messages. `"none"`
#'   suppresses progress output and `"stage"` reports each marginal fitting
#'   stage and the dependence stage.
#'
#' @return An object of class `boostPM_fit`, represented as a list containing:
#' \describe{
#'   \item{tree_list}{Serialized fitted trees used by prediction and
#'   simulation.}
#'   \item{residuals_boosting}{Final residual coordinates as a
#'   variables-by-observations numeric matrix.}
#'   \item{tree_size_store}{Number of nodes in each accepted tree.}
#'   \item{max_depth_store}{Maximum depth of each accepted tree.}
#'   \item{variable_importance}{Accumulated improvement attributed to each
#'   variable.}
#'   \item{improvement_curve}{Held-out candidate-tree scores when
#'   `early_stop` is enabled; absent otherwise.}
#'   \item{Omega}{The original-scale rectangular support used for fitting.}
#'   \item{time}{Elapsed fitting time as a `difftime` object.}
#' }
#'
#' @section Fitting stages:
#' The procedure first fits up to `ntree_max_marginal` univariate trees for
#' each variable. It then fits up to `ntree_max_dependence` multivariate trees
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
#' is recorded in `improvement_curve` but is not added to the ensemble.
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
#' x1 <- stats::rbeta(80, shape1 = 2, shape2 = 5)
#' x2 <- stats::rbeta(80, shape1 = 2 + 6 * x1, shape2 = 4)
#' x <- cbind(x1 = x1, x2 = x2)
#'
#' set.seed(123)
#' fit <- fit_boostpm(
#'   x,
#'   Omega = cbind(lower = c(0, 0), upper = c(1, 1)),
#'   add_noise = FALSE,
#'   ntree_max_marginal = 2,
#'   ntree_max_dependence = 3,
#'   nbins = 8,
#'   max_resol = 2,
#'   min_obs = 5
#' )
#' print(fit)
#'
#' evaluation_points <- matrix(c(0.25, 0.25, 0.50, 0.50, 0.75, 0.75),
#'                             ncol = 2, byrow = TRUE)
#' predict(fit, newdata = evaluation_points, type = "density")
#' simulate(fit, nsim = 5)
#'
#' @export
#' @md
fit_boostpm <- function(data,
                     Omega = NULL,
                     add_noise = TRUE,
                     ntree_max_marginal = 100,
                     ntree_max_dependence = 1000,
                     nbins = 8,
                     c0 = 0.1,
                     gamma = 0.1,
                     early_stop = NULL,
                     max_resol = 15,
                     min_obs = 5,
                     prior_split_prob = 0.9,
                     progress = c("none", "stage")) {
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
    add_noise = add_noise,
    ntree_max_marginal = ntree_max_marginal,
    ntree_max_dependence = ntree_max_dependence,
    c0 = c0,
    gamma = gamma,
    max_resol = max_resol,
    min_obs = min_obs,
    early_stop = early_stop,
    prior_split_prob = prior_split_prob,
    nbins = nbins
  )
  if (!is.null(early_stop) &&
      (ntree_max_marginal > 0L || ntree_max_dependence > 0L) &&
      nrow(data) < 2L) {
    .boostpm_stop_invalid(
      "`early_stop` requires at least two data rows when a tree may be fitted."
    )
  }

  processed <- .boostpm_preprocess(data, add_noise, Omega)
  x_new <- processed$data
  Omega <- processed$Omega
  stopping <- .boostpm_early_stop_controls(early_stop)

  start_time <- Sys.time()

  out <- do_boosting(
    x_new,
    prior_split_prob,
    gamma,
    max_resol,
    ntree_max_marginal,
    ntree_max_dependence,
    c0,
    min_obs,
    nbins,
    stopping$eta_subsample,
    stopping$thresh_stop,
    stopping$ntrees_wait,
    identical(progress, "stage")
  )

  out$Omega <- Omega

  end_time <- Sys.time()
  out$time <- end_time - start_time
  class(out) <- c("boostPM_fit", "list")

  out
}
