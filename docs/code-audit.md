# boostPM code audit

## 1. Scope

- Audit date: 2026-07-14
- Audited archive: `original/`
- Archived branch: `master`
- Archived commit: `1732dba73d3788c9c457f958c4e5699f12ff3bab`
- Source URL: <https://github.com/nawaya040/boostPM.git>
- Paper: Awaya and Ma (2024), *Unsupervised Tree Boosting for Learning Probability Distributions*

This audit is read-only with respect to `original/`. No archived source file was modified.

The audit covers repository structure, package metadata, public interfaces, R and C++ implementation, random-number use, numerical risks, documentation, tests, portability, and CRAN readiness. It does not yet establish full agreement between the code and the mathematical specification in the paper.

## 2. Labels

- **confirmed from the original code**: directly observed in `original/`
- **confirmed from the paper**: directly stated in the local paper PDF
- **inferred from context**: plausible interpretation requiring later verification
- **unresolved**: insufficient evidence
- **possible bug**: behavior that may be unintended and requires a characterization test
- **possible numerical issue**: behavior that may produce unstable or non-finite results
- **proposed next step**: recommendation only; not implemented

## 3. Executive summary

The archived repository contains a small, already Rcpp-based prototype package. Its main algorithm is implemented in C++, while R performs preprocessing, support normalization, and user-facing wrappers. The package has three exported functions: `boosting()`, `simulation_b()`, and `eval_density_b()`.

The implementation is not currently ready for CRAN. The most immediate blockers are placeholder package metadata, an unresolved code license, missing documentation for exported functions, no tests, and GNU-specific C++ headers. Input validation is minimal, and several boundary cases can reach unsafe C++ indexing or non-finite calculations.

The code already uses log-scale normalization in some probability calculations and manually releases tree nodes on normal execution paths. No explicit parallel region was found. OpenMP flags are nevertheless enabled.

No statistical or numerical routine was changed during this audit.

## 4. Provenance and repository history

### 4.1 Archived version

**confirmed from the original code**

- `origin/HEAD` points to `master`.
- `master` is clean at commit `1732dba73d3788c9c457f958c4e5699f12ff3bab`.
- The commit date is 2023-10-09.
- No release tags were found.

### 4.2 Other branch in the same repository

**confirmed from the original code**

The remote also contains `origin/main` at commit `654ea112859479fb0eb603c411646c2b4f66342c`, dated 2025-08-15. A local merge-base was not obtained. Its tree describes a different package named `BATTS` and replaces the boostPM implementation. It should not be treated as a newer boostPM release without separate investigation.

### 4.3 Repository cited by the paper

**confirmed from the paper**

The paper points to <https://github.com/MaStatLab/boostPM> as the R package repository and <https://github.com/MaStatLab/boostPM_experiments> for numerical examples.

**confirmed by read-only Git inspection**

On 2026-07-14, `MaStatLab/boostPM` reported `master` at commit `b3dec3d3370c97b8dbb33db6ec3b7396c2b94650`. The official history contains the archived commit `1732dba73d3788c9c457f958c4e5699f12ff3bab` as its direct parent. The only intervening change is the installation URL in `README.md`; package implementation files are identical.

The experiment repository's initial code commit was created 74 seconds after `1732dba` and uses the same API. This supports the source lineage.

**unresolved**

- Which exact checked-out commit and runtime environment generated each published numerical result, because the experiment scripts do not pin package versions or record result hashes.

The full record is in `docs/code-provenance.md`. The archived source remains fixed because replacing it with the official HEAD would change only README provenance text.

## 5. Repository inventory

```text
original/
├── DESCRIPTION
├── NAMESPACE
├── README.md
├── Example/
│   └── 2d_example.R
├── R/
│   ├── boosting_functions.R
│   └── RcppExports.R
├── man/
│   └── boostPM-package.Rd
└── src/
    ├── class_boosting.cpp
    ├── class_boosting.h
    ├── count_tree.cpp
    ├── count_tree.h
    ├── helpers.cpp
    ├── helpers.h
    ├── main.cpp
    ├── post.cpp
    ├── post.h
    ├── RcppExports.cpp
    ├── Makevars
    └── Makevars.win
```

Missing project components include:

- `tests/`
- function-level `.Rd` documentation
- vignettes
- package data
- `NEWS.md`
- `inst/CITATION`
- a code-license file on the archived `master` branch
- benchmark scripts
- continuous-integration configuration

## 6. Package metadata and dependencies

### 6.1 DESCRIPTION

**confirmed from the original code**

The following fields remain placeholders:

- `Title: What the package does (short line)`
- `Author: Who wrote it`
- `Maintainer: Who to complain to <yourfault@somewhere.net>`
- `Description: More about what it does ...`
- `License: What license is it under?`

These are CRAN blockers. The paper's CC BY 4.0 license applies to the article and must not be assumed to license the package source.

Declared dependencies:

- `Imports: Rcpp (>= 1.0.7)`
- `LinkingTo: Rcpp, RcppArmadillo`

No undeclared runtime R-package use was found in the exported R functions. The nonstandard example script additionally uses `ggplot2` and `viridis`; these are not declared.

### 6.2 NAMESPACE

**confirmed from the original code**

- Native routine registration is enabled with `useDynLib(boostPM, .registration=TRUE)`.
- `Rcpp::evalCpp` is imported.
- The three user-facing wrappers are exported.
- Low-level generated Rcpp functions are not exported through `NAMESPACE`.

### 6.3 Build configuration

**confirmed from the original code**

- C++11 is requested in both `Makevars` files.
- OpenMP compile and link flags are requested.
- LAPACK, BLAS, and Fortran libraries are linked.
- No `#pragma omp` or other explicit parallel region was found.

**proposed next step**

Determine whether OpenMP and explicit LAPACK/BLAS linkage are actually required. Removing unnecessary flags would reduce portability risk, but only outside `original/` and after a clean build comparison.

## 7. Public API and data flow

### 7.1 `boosting()`

**confirmed from the original code**

The implementation expects observations in rows and variables in columns (`n x d`). The leading source comment instead says `d x n`, while the example uses `n x d`. This is a documentation conflict.

Main flow:

1. Optionally jitter tied observations with R's `runif()`.
2. Construct or validate the rectangular support `Omega`.
3. Map every dimension to the unit interval.
4. Fit marginal distributions dimension by dimension.
5. Fit the dependence structure using all active variables.
6. Return residuals, tree diagnostics, variable importance, serialized trees, support, and elapsed time.

The returned object has no S3 class. Its internal layout is exposed directly.

### 7.2 `simulation_b()`

**confirmed from the original code**

The function passes the stored tree list and support to C++. C++ draws uniform values on the unit cube, applies fitted trees in reverse order, and maps the result back to the original support. The result is a `size x d` matrix.

### 7.3 `eval_density_b()`

**confirmed from the original code**

The function evaluates fitted log densities and returns:

- `log_densities`
- `mean_log_dens_path`

No validation is performed on the dimensions, finiteness, or support membership of evaluation points.

### 7.4 Console and global-state behavior

**confirmed from the original code**

- Fitting prints stage progress from C++ unconditionally.
- Fitting prints elapsed time from R unconditionally.
- No R `setwd()`, global assignment, option change, file write, system command, or network call was found in the exported implementation.
- `post.cpp` uses a process-global integer `d_g`, making post-processing code non-reentrant and unsafe for concurrent calls.

## 8. Statistical and computational behavior observed in code

This section records code behavior only. Agreement and conflicts with the paper are documented in `docs/statistical-specification.md`.

**confirmed from the original code**

- Each dimension is first fitted separately with up to `ntree_max_marginal` trees.
- A dependence stage then uses up to `ntree_max_dependence` trees.
- Candidate split locations are equally spaced fractions determined by `nbins`.
- Split versus stop and the selected split rule are sampled stochastically.
- The split probability is implemented as `alpha * (depth + 1)^(-beta)`.
- The R comment describes `alpha * (1 + depth)^beta` without the minus sign. With the default `beta = 0`, the discrepancy is hidden.
- Package resolution: before the first CRAN release, the package removed the
  depth-decay extension and renamed the constant split prior to
  `prior_split_prob`; the archived implementation remains unchanged.
- Node mass is shrunk toward its geometric split mass through `c0` and the scale-dependent factor using `gamma`.
- Early stopping is activated only when `early_stop` is non-`NULL`; this also forces a 90% training subsample.
- The early-stopping window is initialized with large constants, delaying stopping until the window has been replaced by observed improvements.
- The rejected stopping tree is not stored or applied, but its held-out improvement is appended to `improvement_curve`.

**unresolved**

- Whether the depth convention and early-stopping details match the published algorithm exactly.
- Whether variable importance is intended to include both marginal and dependence stages.
- Whether `max_n_var` is part of the published method or an experimental extension only.

## 9. Input validation and boundary behavior

Input validation is the largest immediate correctness risk.

### 9.1 R boundary

**confirmed from the original code**

The public functions do not generally validate:

- numeric matrix type
- nonempty dimensions
- missing or infinite values
- support shape (`d x 2`)
- positive support widths
- integer-valued count and depth arguments
- positive sample sizes
- valid probability and shrinkage ranges
- `early_stop` length and values
- compatibility of fitted objects passed to post-processing

Only one explicit check exists: original observations must lie strictly inside a user-supplied `Omega`.

### 9.2 Boundary risks

| Label | Observation | Possible consequence |
|---|---|---|
| possible bug | A constant column gives zero automatic support width; tie jitter also indexes a nonexistent second unique value | `NA`, division by zero, or non-finite normalized data |
| possible bug | With user-supplied `Omega`, support membership is checked before jitter, not after jitter | Jittered data may leave the support and reach unsafe C++ bin indexing |
| possible bug | `make_left_count_vector()` computes a bin index without clamping or checking it | Out-of-bounds Armadillo access if a residual is outside the node interval or equals its right boundary |
| possible bug | `eval_density_b()` does not reject points outside `Omega` | Finite density may be returned outside the declared support instead of log-density `-Inf` |
| possible bug | Tree construction stops splitting only when `depth > max_resol` | A node at `max_resol` may still split, producing children at `max_resol + 1` |
| possible bug | `early_stop` can provide `ntrees_wait <= 1`; small samples can produce a zero-sized training subset | Invalid Armadillo subvector ranges or empty calculations |
| possible numerical issue | Invalid `alpha`, `precision`, `c0`, `gamma`, or split values are not rejected | Invalid logarithms, beta parameters, probabilities, or `theta` outside `(0, 1)` |
| possible numerical issue | Zero or negative support width is not rejected in simulation or density evaluation | Division by zero or invalid logarithms |
| possible numerical issue | `OneSample()` assumes cumulative probabilities always cross a uniform draw | Empty index result in extreme rounding or invalid-probability cases |

These cases require characterization and failure tests before any fix.

## 10. Random-number generation and reproducibility

**confirmed from the original code**

Random draws occur in:

- R tie jitter through `runif()`
- C++ split/stop selection through `R::runif()`
- C++ split-rule sampling through `R::runif()` in `OneSample()`
- C++ simulation through `Rcpp::runif()`
- subsampling through Armadillo `randperm()`

Generated Rcpp interfaces create `Rcpp::RNGScope` for exported C++ calls.

**inferred from context**

Most random draws are designed to use R's RNG and should respond to `set.seed()`.

**unresolved**

- Exact fixed-seed reproducibility of `arma::randperm()` with the installed RcppArmadillo version.
- Exact reproducibility across operating systems and compiler/library versions.
- Whether the number and order of draws match the implementation used for the published results.

No claim of exact, numerical, or inferential reproducibility is supported yet. Fixed-seed tests are required.

## 11. Numerical implementation

### 11.1 Positive observations

**confirmed from the original code**

- Split likelihoods are accumulated on the log scale.
- A max-shifted log-sum-exp calculation is used for probability normalization.
- Density contributions are accumulated as log densities.
- No explicit matrix inverse was found.

### 11.2 Risks

**possible numerical issue**

- Log-sum-exp helpers do not handle empty vectors or all non-finite inputs explicitly.
- User settings can allow `theta` to reach 0 or 1, making subsequent logarithms or inverse transforms singular.
- Very narrow nodes are blocked only through a fixed `MIN_WIDTH = 1e-10`; the suitability of this threshold is not documented.
- Floating-point boundary drift is not clamped before binning.
- Density and inverse transforms divide by split masses and interval widths without defensive checks.

Numerical stabilization changes must preserve the estimator and be tested against the archived implementation.

## 12. C++ safety and portability

### 12.1 Portability

**confirmed from the original code**

`class_boosting.cpp` and `post.cpp` include `<bits/stdc++.h>`. This is a GNU-specific header and may fail on CRAN platforms using non-GNU standard-library layouts, especially macOS toolchains.

OpenMP flags are enabled despite no explicit parallel implementation. This adds toolchain complexity without an observed computational benefit.

### 12.2 Memory and object safety

**confirmed from the original code**

- Trees use manual `new` and `delete`.
- Normal fitting, simulation, and evaluation paths call iterative cleanup functions.
- No interrupt checks occur in long C++ loops.
- Exceptions after allocation and before cleanup can leak nodes.
- Serialized trees are reconstructed without validating vector lengths or contents.

**possible bug**

`class_boosting.h` and `post.h` define different global structs with the same name `Node` in separate translation units. This can violate the C++ one-definition rule and should be treated as undefined-behavior risk even if current compilers link the package.

### 12.3 Unused or stale code

**confirmed from the original code**

- `count_tree` has no caller in the archived package.
- Several class fields are declared but unused, including `rho`, `parameter_for_test`, `root_nodes`, and old-tree state fields.
- `add_children()` and `evaluate_log_prior()` are not used by the fitting flow.
- `evaluate_log_prior()` computes a beta log density and immediately overwrites it with zero.

These are maintainability findings, not authorization to remove archived code.

## 13. Performance candidates

No benchmark or profiling data exists, so no performance claim is made.

**proposed optimization candidates based on code structure**

- Repeated traversal of all observations after every fitted tree.
- Repeated per-node copying of observation-index vectors.
- Repeated per-column temporary vector creation during residualization and evaluation.
- Evaluation of all dimensions and all split candidates at many nodes.
- Tree reconstruction and manual allocation for every tree during simulation and density evaluation.
- Matrix arguments and fitted structures passed or copied by value in several places.

Profiling should precede optimization. The current C++ implementation must first be covered by characterization tests.

## 14. Documentation and examples

**confirmed from the original code**

- Only package-level `.Rd` documentation exists.
- Exported functions have no argument, return-value, assumption, reproducibility, example, or reference documentation.
- The README cites a 2022 arXiv version.
- The package `.Rd` file cites a 2021 title/version.
- The local authoritative paper is the 2024 JMLR publication.
- `Example/2d_example.R` uses 10,000 observations, up to 1,100 trees, a 10,000-point evaluation grid, and interactive plots.
- The example directory is nonstandard for installed R package examples.
- The example comment for `min_obs` conflicts with the implementation: the code permits splitting when node size is at least `min_obs`.

The full example is unsuitable for routine CRAN checks without substantial reduction or a `\donttest{}` strategy justified by runtime. A smaller deterministic example will be needed.

## 15. Tests and validation

The project now contains a standalone characterization suite under `tests/testthat/`. It installs a temporary copy of `original/`, leaving the archive unchanged.

**confirmed by tests on 2026-07-14**

- 20 test cases and 60 explicit `expect_*` calls pass.
- Local move density and inverse formulas agree with hand calculations.
- Fixed-seed univariate and two-dimensional fits match frozen numerical fixtures.
- Density evaluation and simulation match frozen outputs.
- R preprocessing, controls, support scaling, and tie jitter are characterized.
- Several known boundary and failure behaviors are preserved explicitly.

**not yet established**

- original-versus-new agreement, because the new implementation does not yet exist
- density normalization by numerical integration
- parameter recovery
- inferential reproducibility
- cross-platform numerical tolerance
- performance improvement

Details are recorded in `docs/numerical-validation.md`.

## 16. Static and build checks performed

Environment:

- Windows
- R 4.5.2
- Rcpp 1.1.1.1
- RcppArmadillo 14.4.1.1
- GCC 14.3.0 from Rtools45

Results:

- All R files parsed successfully.
- `tools::checkRd()` reported no issue for the package-level `.Rd` file.
- Every C++ translation unit compiled during `R CMD build` without a reported source compilation error.
- The link command was reached without a reported linker diagnostic.
- Package installation then failed because the sandboxed Rtools shell could not resolve POSIX utilities including `basename`, `sed`, and `rm`.
- `R CMD check` was therefore not run.
- The failure is classified as an audit-environment limitation, not evidence that the package passes or fails a normal build environment.
- The standalone characterization runner successfully compiled and installed a temporary archive copy after supplying sandbox-only toolchain environment variables.
- All 20 characterization cases and 60 explicit `expect_*` calls passed.
- `original/` remained clean after all checks.

## 17. CRAN readiness

Current status: **not ready**.

### P0: submission blockers

1. Replace placeholder `DESCRIPTION` metadata in the new package implementation.
2. Establish a valid code license with explicit user approval; do not infer it from the paper license.
3. Document all exported functions.
4. Replace GNU-specific headers in the new implementation.
5. Add `.Rbuildignore` at the future package root so `original/`, paper PDFs, internal audit documents, and nested `.git` data are excluded from the CRAN source package as appropriate.
6. Run a complete clean-environment `R CMD check` after a new package skeleton exists.

### P1: correctness and safety

1. Reconstruct or explicitly bound the runtime provenance of the published numerical results.
2. Add R-boundary validation before C++ calls.
3. Characterize constant columns, ties, support boundaries, small samples, and malformed controls.
4. Verify density behavior outside `Omega`.
5. Verify the `max_resol` depth convention against the paper.
6. Test learning-rate and probability parameter boundaries.
7. Eliminate the conflicting global `Node` definitions in the new implementation.

### P2: reproducibility and API quality

1. Add fixed-seed tests for fitting and simulation.
2. Define exact, numerical, and inferential reproducibility targets.
3. Introduce a structured S3 fit object and methods without changing stored statistical content.
4. Add a quiet or verbosity control and remove unconditional output from the user-facing path.
5. Add user-interrupt checks to long sequential C++ loops.

### P3: maintainability and performance

1. Separate active code from unused prototype code outside the archive.
2. Profile before changing allocation or traversal strategies.
3. Benchmark archived, refactored R-facing, and optimized implementations.
4. Remove unused OpenMP configuration unless later profiling justifies parallel work and reproducibility is defined.

## 18. Recommended next sequence

1. Create and maintain `docs/statistical-specification.md` from the paper and archived code, marking every conflict.
2. Create a new package skeleton outside `original/`.
3. Add characterization tests for the archived behavior using small fixed-seed inputs.
4. Add failure tests for the P1 boundary cases.
5. Refactor the R-facing API without changing the algorithm.
6. Profile the verified implementation.
7. Optimize only measured bottlenecks.

## 19. Unresolved questions requiring user or source confirmation

- Which exact runtime environment produced each published numerical result?
- What license applies to the package source?
- Is `max_n_var` part of the supported method or only an experiment?
- Is density outside `Omega` intended to be exactly zero?
- Does `max_resol` denote the deepest splittable node or the deepest resulting node?
- Is early stopping intended to force 90% subsampling?
- Should marginal-stage contributions be included in reported variable importance?

## 20. Resolution update: input and boundary policy

**explicit user instructions, 2026-07-14 and 2026-07-17**

The package implementation now resolves the relevant audit findings as follows:

- reject constant columns;
- enforce `0 < c0 < 1`, `gamma >= 0`, and
  `0 <= prior_split_prob <= 1`;
- remove the package-level `precision` control and fix it at one as specified
  in Appendix C and used in the public experiments;
- reject jittered observations leaving a supplied support;
- return log density `-Inf` outside `Omega`;
- assign split-point equality left, following the paper;
- retain archived `max_resol` semantics for compatibility;
- remove the experimental `max_n_var` restriction from package code;
- raise explicit errors before invalid bin access;
- retain numeric-matrix input and strict support containment; and
- add class `boostPM_fit` without changing the compatible list layout.

The later boundary-safe binning refinement replaces the initial error-only
guard with equality-left `std::lower_bound()` lookup. Exact endpoints are
assigned safely, drift within a documented floating-point tolerance is clamped,
and larger interval violations remain errors.

The subsequent uniform-grid optimization replaces binary search with a
constant-time provisional index and adjacent candidate checks. It retains the
same equality-left and endpoint behavior, with a final interval-invariant
guard before vector access.

The observations in earlier audit sections remain a historical description of
the archived implementation.
