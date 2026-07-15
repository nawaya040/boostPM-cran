\name{boosting}
\alias{boosting}
\title{Fit an Unsupervised Tree Boosting Density Model}
\usage{
boosting(
  data,
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
  beta = 0,
  precision = 1,
  nbins = 8
)
}
\arguments{
  \item{data}{A numeric matrix with observations in rows and variables in columns.}
  \item{add_noise}{Logical. If true, tied observations are jittered using R's random-number generator.}
  \item{Omega}{Optional numeric matrix with one row per variable and columns containing lower and upper support limits.}
  \item{ntree_max_marginal}{Maximum number of trees fitted in each marginal stage.}
  \item{ntree_max_dependence}{Maximum number of trees fitted in the dependence stage.}
  \item{c0}{Global shrinkage parameter strictly between zero and one.}
  \item{gamma}{Non-negative local scale parameter used by the numerical procedure.}
  \item{max_resol}{Maximum resolution control used during tree construction.}
  \item{min_obs}{Minimum node observation count used by the split rule.}
  \item{early_stop}{Optional numeric vector containing the stopping threshold and waiting-window length.}
  \item{alpha, beta}{Parameters controlling the depth-dependent split probability. \code{alpha} lies in \code{[0, 1]} and \code{beta} is non-negative.}
  \item{precision}{Positive precision parameter of the beta distribution used in split scoring.}
  \item{nbins}{Number of bins defining candidate split locations.}
}
\value{
A \code{boostPM_fit} object. It is a list containing residuals, tree diagnostics, variable importance,
serialized trees, the support matrix \code{Omega}, and elapsed fitting time.
The list layout is retained for compatibility with the archived implementation.
}
\description{
Fits the unsupervised tree boosting procedure introduced by Awaya and Ma
(2024). This development interface currently preserves the archived research
implementation.
}
\details{
The input is mapped to a unit hypercube. Marginal trees are fitted first,
followed by dependence trees. Stochastic fits use R-compatible random-number
generation and can be repeated within a fixed runtime by calling
\code{set.seed()} first. Exact cross-platform reproducibility has not been
established. Constant data columns are rejected. \code{max_resol} retains the
archived meaning of the deepest node that may be split, so resulting leaves can
occur at depth \code{max_resol + 1}.
}
\examples{
set.seed(1)
x <- matrix(c(0.2, 0.4, 0.6, 0.8), ncol = 1)
fit <- boosting(
  x,
  add_noise = FALSE,
  Omega = matrix(c(0, 1), nrow = 1),
  ntree_max_marginal = 0,
  ntree_max_dependence = 0
)
}
\references{
Awaya, N. and Ma, L. (2024). Unsupervised Tree Boosting for Learning
Probability Distributions. \emph{Journal of Machine Learning Research}, 25,
1--52.
}
