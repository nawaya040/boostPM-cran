# Original implementation versus package skeleton

## Scope

Comparison date: 2026-07-14.

The immutable reference is `original/` at commit
`1732dba73d3788c9c457f958c4e5699f12ff3bab`. The initial package code lives in
the root `R/` and `src/` directories.

## Source relationship

**confirmed from the original code**

The initial files in `R/`, `src/`, `NAMESPACE`, and the package-level manual
page were copied from the archive. Comparison after normalizing line endings
and the final empty line found no substantive source-text change.

The root package adds metadata, citation data, user documentation, standard
tests, and CRAN build exclusions. `NAMESPACE` additionally imports
`stats::runif` so package checks can resolve the existing call explicitly.

## Validation

**confirmed by tests on Windows with R 4.5.2**

- The archived suite passes 20 test cases and 60 explicit expectations.
- The root package suite passes 34 test cases and 90 explicit expectation calls,
  including numerical, mathematical, wrapper, C++ safety, and known-boundary
  fixtures.
- Fixed-seed fits, serialized trees, residuals, density evaluation, simulation,
  and variable importance remain within the recorded tolerances.
- `R CMD build` succeeds.
- The first `R CMD check --as-cran --no-manual` completed with two warnings and
  seven notes.
- After adding exported-function documentation, the `stats::runif` import,
  NEWS formatting, and build exclusions, the second check completed with one
  warning and four notes.
- After applying the MIT License, the third check completed with no warnings
  and four notes.
- After the C++ portability and safety refactoring, the final check completed
  with no warnings and three notes.

One fixture was rewritten from `expect_equal(..., tolerance = 1e-15)` to an
explicit absolute-error comparison at the same `1e-15` threshold. Testthat
edition 3 interpreted the former as a relative tolerance, causing both the
archive and package builds to fail on a one-ULP difference of approximately
`1.1e-16`. No expected value or tolerance was changed.

## Statistical behavior

Before the explicitly approved changes recorded below, no statistical model,
default, random draw order, boundary convention, output definition, or
numerical algorithm had been intentionally changed.

## R-wrapper refactoring

**confirmed by direct comparison on 2026-07-14**

The archived `boosting_functions.R` was divided into `R/preprocessing.R`,
`R/controls.R`, `R/boosting.R`, and `R/postprocessing.R`. Defaults, low-level
argument order, returned content, console output, and the start point of
elapsed-time measurement were retained. The current primary API is
`fit_boostpm()`, `predict()`, and `simulate()`; the archived public names were
removed before the first CRAN release.

A fixed-seed direct comparison found identical preprocessing results, C++ call
arguments, returned content excluding elapsed time, and final R random-number
state. Known constant-column and boundary behavior remains characterized rather
than corrected.

## C++ portability and safety refactoring

**confirmed by source inspection and regression tests on 2026-07-14**

- Replaced GNU-specific `bits/stdc++.h` includes with standard headers.
- Removed unused OpenMP compile and link flags and the obsolete explicit C++11
  request. No parallel region was added or removed.
- Renamed the post-processing node type to eliminate the conflicting global
  `Node` definitions.
- Replaced the process-global post-processing dimension with a call-local
  value.
- Added scope-managed cleanup for active fitting and reconstructed trees, so
  R errors and user interrupts release allocated nodes.
- Replaced allocation-dependent cleanup traversal with a `noexcept` traversal
  using existing parent links.
- Added periodic user-interrupt checks to long fitting, simulation, density,
  and tree-reconstruction loops.
- Qualified exported Armadillo and Rcpp types and regenerated Rcpp interfaces
  with `Rcpp::compileAttributes()`.
- Added defensive checks for malformed support matrices, simulation sizes,
  evaluation matrices, and serialized trees before C++ indexing.
- Removed namespace-wide imports from header files.

Fixed-seed tree structures, residuals, importance values, density values,
simulations, and final R random-number states remained within their existing
tolerances. The new checks affect malformed post-processing inputs only.

## Unresolved

- Cross-platform numerical comparison.
- Paper-versus-code settings for split probability, split-grid size, and
  marginal-tree cap.
- Adaptive-stopping variable-importance normalization.

## Approved input and boundary decisions

**explicit user instructions, 2026-07-14 and 2026-07-17**

- Constant data columns are rejected.
- The package validates `0 < c0 < 1`, `gamma >= 0`,
  and `0 <= prior_split_prob <= 1`.
- The archived `alpha = 0.9, beta = 0` split prior is exposed as
  `prior_split_prob = 0.9`; the unreported depth-decay extension is not part of
  the package API.
- The archived `precision` control is removed and fixed internally at one,
  matching both Appendix C and the public experiment setting.
- Jittered values leaving a supplied `Omega` raise an error.
- Evaluation points outside `Omega` receive log density `-Inf`.
- Split-point equality is assigned left during fitting, evaluation,
  residualization, and inverse simulation, following the paper.
- `max_split_depth` retains the archived `max_resol`
  deepest-splittable-node behavior.
- The experimental `max_n_var` feature is removed from the package code.
- Invalid C++ bin indices raise an explicit error before vector access.
- The public data input remains restricted to numeric matrices.
- Fits receive S3 class `boostPM_fit`. Before the first CRAN release, archived
  working-component names were replaced at the R boundary by descriptive
  public names; post-processing requires the new fitted-object structure.
- Training observations must remain strictly inside supplied support bounds.

These are intentional package-versus-archive differences. Interior fixed-seed
fixtures not exercising the changed boundaries remain numerically identical at
the existing tolerances. `R CMD check --as-cran --no-manual` completed with no
errors, no warnings, and the same three environment or development notes.

The bin rule was subsequently refined: candidate equality enters the left bin,
the exact right endpoint enters the final bin, round-off-sized endpoint drift is
clamped, and larger violations still raise an error.

The uniform-grid implementation now computes a provisional bin in constant
time, then checks adjacent actual candidate values. This retains the same
equality-left and endpoint rules as the preceding binary search. Fixed-seed
tests and four-way benchmark checksums remained unchanged. Recorded full-fit
time improved by about 8%--33% relative to binary search.
