# boostPM 0.1.0

* First CRAN submission candidate.

* Provides the public fitting interface fit_boostpm(), S3 methods for fitted
  objects, prediction through predict(), and simulation through simulate().

* Preserves the archived research implementation in original/ while providing
  a validated, portable package implementation.

* Removed the provisional `boosting()`, `eval_density_b()`, and
  `simulation_b()` interfaces before the first CRAN release.

* Added optional stage-level fitting messages through
  `progress = "stage"`; fitting remains silent by default.

* Replaced the provisional `alpha` and `beta` split-prior controls with
  `prior_split_prob`. The default remains 0.9, matching the archived software
  and public experiment code, while the depth-decay extension is no longer
  exposed.

* Removed the provisional `precision` fitting control and fixed the auxiliary
  beta-prior precision at 1, matching Appendix C and the public experiments.

* Reordered `fit_boostpm()` arguments so that support, tree-count, split-grid,
  and learning-rate controls appear before lower-level regularization controls.
  Expanded the manual with the paper's scale-specific learning-rate formula,
  the exact held-out early-stopping rule, support and tie handling, split-prior
  interpretation, and reproducibility guidance.

* Renamed the remaining implementation-oriented fitting controls to
  `max_marginal_trees`, `max_dependence_trees`, `n_bins`, `max_split_depth`,
  and `min_node_observations`. The superseded public names are not retained.

* Replaced miniature fitted-object examples throughout the manual with
  reproducible two-dimensional fits using 400 observations, 100 marginal-tree
  candidates per variable, 1,000 dependence-tree candidates, 100 split bins,
  and a maximum split depth of 15. Prediction examples evaluate a 50-by-50
  grid, and simulation examples generate 500 observations. All examples remain
  suitable for CRAN checks.

* Replaced provisional fitted-object component names with descriptive names:
  `trees`, `residual_coordinates`, `tree_diagnostics`, `variable_importance`,
  `heldout_diagnostics`, `support`, and `elapsed_time`. Per-tree and held-out
  diagnostics now include marginal-versus-dependence stage labels, marginal
  variable labels, and held-out acceptance status.
  `variable_importance` is now a numeric vector named from the data columns
  when available. Fits also store the matched `call` and validated `control`
  settings. The provisional component names are not retained as aliases.

* Clarified and separated `summary()` and summary-printing documentation,
  preserved variable names in printed importance values and simulated samples,
  renamed detailed prediction components to `log_density` and
  `mean_log_density_path`, and made documented `barplot()` label overrides
  safe in `plot()`.

* Expanded the introductory vignette with an independent beta reference case,
  a nonlinear sinusoidal scenario, paper-oriented accuracy controls,
  fitted-density comparisons, and generated-sample visualizations.

# boostPM 0.0.0.9000

* Added print(), summary(), and plot() methods for boostPM_fit objects.
  fit_boostpm() no longer prints elapsed fitting time automatically.
* Renamed the primary public API to `fit_boostpm()`, `predict()`, and
  `simulate()`. The provisional names used during development were removed
  before the 0.1.0 release.
* Added R-side validation for public fitting, simulation, and density-evaluation
  inputs.
* Enforced approved parameter domains: `0 < c0 < 1`, `gamma >= 0`,
  and `0 <= prior_split_prob <= 1`.
* Rejected constant data columns and jittered observations that leave a supplied
  support.
* Assigned split-point equality to the left child throughout fitting, density
  evaluation, and inverse simulation, following the paper.
* Returned `-Inf` log densities for evaluation points outside the support.
* Removed the experimental `max_n_var` control from the package implementation.
* Replaced unsafe bin indexing with constant-time uniform-grid lookup. Exact
  candidate equality remains assigned left, round-off-sized endpoint drift is
  clamped using a documented tolerance, and larger interval violations raise
  explicit errors.
* Added the `boostPM_fit` S3 class and structured post-processing methods.
* Added reproducible isolated-kernel and end-to-end benchmarks for the
  boundary-safe binning change. Arithmetic lookup reduced full-fit time by
  about 8%--33% relative to the preceding binary-search implementation; its
  measured cost relative to the unsafe floor kernel is 1.12--1.16 times.
* Added standalone original-versus-package regression validation, paper-aligned
  predictive-score simulations, and a Windows/macOS/Linux R CMD check workflow.

* Created a CRAN-oriented package skeleton outside the immutable research archive.
* Added regression tests that preserve the archived numerical behavior.
* Licensed the package source under the MIT License.
* Added package author and maintainer metadata.
* Split the archived R wrapper into preprocessing, controls, fitting, and
  post-processing modules without changing its numerical behavior.
* Improved C++ portability and safety by removing GNU-specific headers and
  unused OpenMP flags, separating conflicting node types, removing global
  post-processing state, adding exception-safe tree cleanup and interrupt
  checks, and validating serialized post-processing inputs.
