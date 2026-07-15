#' Fit a boostPM Distribution
#'
#' Fits the unsupervised tree boosting procedure of Awaya and Ma (2024).
#' Marginal trees are fitted first, followed by dependence trees. The fitted
#' ensemble represents a probability distribution on a rectangular support.
#'
#' @param data A finite numeric matrix. Rows are observations and columns are
#'   variables. Constant columns are not supported.
#' @param add_noise A single logical value. If `TRUE`, tied observations are
#'   jittered using R's random-number generator before fitting.
#' @param Omega Either `NULL`, or a finite numeric matrix with one row per
#'   variable and two columns giving lower and upper support limits. Each
#'   training observation must be strictly inside the supplied limits.
#' @param ntree_max_marginal Non-negative integer. Maximum number of trees in
#'   each marginal fitting stage.
#' @param ntree_max_dependence Non-negative integer. Maximum number of trees in
#'   the dependence fitting stage.
#' @param c0 Numeric shrinkage parameter, strictly between zero and one.
#' @param gamma Non-negative numeric local scale parameter.
#' @param max_resol Non-negative integer controlling the maximum split
#'   resolution. Its archived interpretation permits leaves at depth
#'   `max_resol + 1`.
#' @param min_obs Positive integer giving the minimum node observation count
#'   used by the split rule.
#' @param early_stop Either `NULL`, or a finite numeric vector of length two.
#'   Its first entry is the stopping threshold and its second entry is an
#'   integer waiting-window length of at least two.
#' @param alpha Numeric parameter in `[0, 1]` for the depth-dependent split
#'   probability.
#' @param beta Non-negative numeric parameter for the depth-dependent split
#'   probability.
#' @param precision Positive numeric precision parameter for the beta
#'   distribution used in split scoring.
#' @param nbins Integer of at least two. Number of uniform-grid candidate split
#'   locations.
#' @param progress Character string controlling progress messages. `"none"`
#'   suppresses progress output and `"stage"` reports each marginal fitting
#'   stage and the dependence stage.
#'
#' @return An object of class `boostPM_fit`. It retains the list layout of the
#'   archived implementation and contains serialized trees, residuals, tree
#'   diagnostics, variable importance, `Omega`, and elapsed fitting time.
#'
#' @details
#' If `Omega` is `NULL`, a rectangular support is constructed from the
#' processed data. If `add_noise` is `TRUE`, call [set.seed()] before fitting
#' to reproduce the jitter and subsequent stochastic tree-fitting decisions.
#' Fitting progress is silent by default. Set `progress = "stage"` to report
#' the current fitting stage. Elapsed time is stored in the returned object;
#' use [print()] or [summary()] to inspect the fit.
#' Reproducibility is intended within a fixed R runtime. Exact equality across
#' operating systems has not been established.
#'
#' @references
#' Awaya, N. and Ma, L. (2024). Unsupervised Tree Boosting for Learning
#' Probability Distributions. *Journal of Machine Learning Research*, 25,
#' 1--52.
#'
#' @examples
#' set.seed(1)
#' x <- matrix(c(0.2, 0.4, 0.6, 0.8), ncol = 1)
#' fit <- fit_boostpm(
#'   x,
#'   add_noise = FALSE,
#'   Omega = matrix(c(0, 1), nrow = 1),
#'   ntree_max_marginal = 0,
#'   ntree_max_dependence = 0
#' )
#'
#' @export
#' @md
fit_boostpm <- function(data,
                     add_noise = TRUE,
                     Omega = NULL,
                     ntree_max_marginal = 100,
                     ntree_max_dependence = 1000,
                     c0 = 0.1,
                     gamma = 0.1,
                     max_resol = 15,
                     min_obs = 5,
                     early_stop = NULL,
                     alpha = 0.9,
                     beta = 0.0,
                     precision = 1.0,
                     nbins = 8,
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
    alpha = alpha,
    beta = beta,
    precision = precision,
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
    precision,
    alpha,
    beta,
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
