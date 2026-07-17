# boostPM

`boostPM` fits probability distributions with unsupervised tree boosting. The
method represents a density as an ensemble of tree-based probability measures,
allows analytic density evaluation, and provides a sampler from the fitted
distribution.

This repository is an in-development, CRAN-oriented package implementation.
The immutable research implementation used for the published work is retained
under `original/` for numerical provenance.

## Installation

The package is not on CRAN yet. Install a development checkout with:

```r
install.packages("/path/to/boostPM-cran", repos = NULL, type = "source")
```

Once the repository is public, a GitHub installation route can be used with
`remotes::install_github("nawaya040/boostPM-cran")`.

## A small example

```r
library(boostPM)

set.seed(1)
data <- cbind(
  rbeta(80, shape1 = 2, shape2 = 5),
  rbeta(80, shape1 = 5, shape2 = 2)
)

support <- cbind(c(0, 0), c(1, 1))

set.seed(2)
fit <- fit_boostpm(
  data,
  Omega = support,
  add_noise = FALSE,
  ntree_max_marginal = 2,
  ntree_max_dependence = 2,
  nbins = 4,
  c0 = 0.1,
  gamma = 0.5,
  max_resol = 1,
  min_obs = 2
)

log_density <- predict(fit, data, type = "log_density")
exp(log_density)

set.seed(3)
simulated <- simulate(fit, nsim = 10)
```

The fit is a `boostPM_fit` object whose list components include serialized
trees, residuals, support, and variable-importance diagnostics.

## Inspect a fitted model

`fit_boostpm()` returns silently. Use the S3 methods to inspect the fit and
its diagnostics.

```r
print(fit)
summary(fit)
plot(fit, type = "variable_importance")
```

The plot method also supports `type = "tree_size"` and
`type = "max_depth"`.

## Input and reproducibility notes

- `data` must be a finite numeric matrix with observations in rows.
- Constant columns are rejected.
- A supplied `Omega` has one lower and upper bound per variable. Training data
  must be strictly inside those bounds.
- `predict(fit, newdata, type = "log_density")` returns log density.
  Evaluation outside `Omega` returns `-Inf`.
- Fits and simulation use R's random-number generator. Call `set.seed()`
  before each stochastic operation when reproducibility is needed.

The introductory vignette is available after installation:

```r
vignette("boostPM-introduction", package = "boostPM")
```

## Citation

Please cite the method paper:

> Awaya, N. and Ma, L. (2024). Unsupervised Tree Boosting for Learning
> Probability Distributions. *Journal of Machine Learning Research*, 25, 1-52.

Use `citation("boostPM")` for the installed-package citation record.

## Development and validation

Routine checks run on Windows, macOS, and Ubuntu through GitHub Actions.
Original-versus-package regression and longer statistical validation runners
live under `validation/`. Their results and performance records are documented
under `docs/` and `benchmarks/`.
