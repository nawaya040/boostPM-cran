\name{eval_density_b}
\alias{eval_density_b}
\title{Evaluate a Fitted boostPM Log Density}
\usage{
eval_density_b(list_boosting, eval_points)
}
\arguments{
  \item{list_boosting}{A fitted object returned by \code{boosting()}.}
  \item{eval_points}{A numeric matrix with evaluation points in rows and variables in columns.}
}
\value{
A list with \code{log_densities} and \code{mean_log_dens_path}. The latter
records the cumulative mean log density after each fitted tree.
}
\description{
Evaluates the serialized tree ensemble and applies the Jacobian associated
with the stored rectangular support.
}
\details{
Evaluation points outside the stored rectangular support receive log density
\code{-Inf}. Split-point equality follows the paper's left-child convention.
}
\examples{
fit <- list(
  tree_list = list(list(
    d = c(0L, -1L, -1L),
    l = c(0.5, -1, -1),
    theta = c(0.25, -1, -1)
  )),
  Omega = matrix(c(0, 1), nrow = 1)
)
eval_density_b(fit, matrix(c(0.25, 0.75), ncol = 1))
}
