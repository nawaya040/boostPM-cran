#' boostPM: Unsupervised Tree Boosting for Learning Probability Distributions
#'
#' Fits tree-ensemble probability distributions, evaluates fitted log
#' densities, and generates samples. The package implementation follows the
#' method of Awaya and Ma (2024), while retaining numerical provenance from the
#' archived research implementation.
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
