# boostPM 0.0.0.9000

* Renamed the primary public API to `fit_boostpm()`, `predict()`, and
  `simulate()`. The former `boosting()`, `eval_density_b()`, and
  `simulation_b()` functions remain as deprecated compatibility wrappers.
* Added R-side validation for public fitting, simulation, and density-evaluation
  inputs.
* Enforced approved parameter domains: `0 < c0 < 1`, `gamma >= 0`,
  `0 <= alpha <= 1`, `beta >= 0`, and `precision > 0`.
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
* Added the `boostPM_fit` S3 class while retaining the archived list layout and
  accepting compatible unclassed fitted lists in post-processing.
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
