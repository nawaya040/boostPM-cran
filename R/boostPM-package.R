#' boostPM: Unsupervised Tree Boosting for Learning Probability Distributions
#'
#' Implements the unsupervised tree boosting method of Awaya and Ma (2024) for
#' fitting tree-ensemble probability distributions, evaluating fitted
#' densities, and generating samples.
#'
#' @seealso [fit_boostpm()], [predict.boostPM_fit()],
#'   [simulate.boostPM_fit()], and [plot.boostPM_fit()].
#'
#' @references
#' Awaya, N. and Ma, L. (2024). Unsupervised Tree Boosting for Learning
#' Probability Distributions. *Journal of Machine Learning Research*, 25,
#' 1--52.
#'
#' @docType package
#' @name boostPM-package
#' @aliases boostPM
#' @useDynLib boostPM, .registration = TRUE
#' @importFrom graphics barplot plot
#' @importFrom Rcpp evalCpp
#' @importFrom stats predict runif simulate
#' @md
"_PACKAGE"
