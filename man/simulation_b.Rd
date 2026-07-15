\name{simulation_b}
\alias{simulation_b}
\title{Simulate from a Fitted boostPM Model}
\usage{
simulation_b(list_boosting, size)
}
\arguments{
  \item{list_boosting}{A fitted object returned by \code{boosting()}.}
  \item{size}{Number of observations to simulate.}
}
\value{A numeric matrix with simulated observations in rows.}
\description{
Draws uniform values on the unit hypercube, applies the fitted inverse tree
transformations, and maps the result to the stored support.
}
\details{
The routine uses R-compatible random-number generation. Calling
\code{set.seed()} before the function supports repeatability within a fixed
runtime.
}
\examples{
fit <- list(
  tree_list = list(),
  Omega = matrix(c(0, 1), nrow = 1)
)
set.seed(1)
simulation_b(fit, 3)
}

