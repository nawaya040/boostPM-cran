# AGENTS.md

## 1. Project overview

This repository contains the implementation of a statistical method developed in a published research paper.

The goals of this project are:

1. Preserve the original implementation used for the published paper.
2. Develop a clean, tested, and maintainable R package.
3. Optimize computationally intensive components using Rcpp or RcppArmadillo where appropriate.
4. Preserve numerical and inferential reproducibility.
5. Prepare the package for submission to CRAN.

The published paper is the authoritative source for the statistical model and methodology. The original code is the authoritative source for the numerical procedure used to generate the published results.

---

## 2. Repository structure

The repository may contain the following directories.

```text
original/
R/
src/
tests/
vignettes/
benchmarks/
docs/
data-raw/
inst/
```

Their intended roles are:

* `original/`: Immutable copy of the original implementation.
* `R/`: R functions included in the package.
* `src/`: C++ source code used through Rcpp or RcppArmadillo.
* `tests/`: Unit, regression, numerical, and integration tests.
* `vignettes/`: User-facing documentation and examples.
* `benchmarks/`: Reproducible performance comparisons.
* `docs/`: Internal design documents, audits, and implementation notes.
* `data-raw/`: Scripts used to construct package data.
* `inst/`: Additional files installed with the package.

Do not assume that every directory already exists.

---

## 3. Preservation rule

The directory `original/` is an archival copy of the implementation used for the published paper.

Files under `original/` must not be modified, reformatted, renamed, reorganized, or deleted unless the user explicitly requests it.

Do not:

* fix style problems inside `original/`;
* rename variables inside `original/`;
* change comments inside `original/`;
* update package calls inside `original/`;
* replace deprecated functions inside `original/`;
* optimize code inside `original/`;
* remove apparently unused files inside `original/`.

If the original code contains a bug, document the suspected bug in `docs/`, but do not change the archived file without explicit approval.

All new implementations must be created outside `original/`.

---

## 4. Statistical invariants

Unless explicitly instructed otherwise, the new implementation must target the same statistical model as the published paper.

Do not change any of the following without explicit approval:

* likelihood;
* prior distributions;
* posterior distribution;
* parameterization;
* identifiability constraints;
* normalization rules;
* transformation of the data;
* hyperparameter definitions;
* default hyperparameter values;
* MCMC transition kernels;
* proposal distributions;
* acceptance probabilities;
* initialization rules;
* burn-in definition;
* thinning definition;
* convergence criteria;
* approximation method;
* treatment of missing values;
* treatment of zero counts or zero probabilities;
* boundary conditions.

A computational optimization must not silently become a methodological modification.

If a proposed change may alter the target distribution, estimator, inferential interpretation, or numerical approximation, stop and describe the issue before implementing it.

---

## 5. Source hierarchy

When determining intended behavior, use the following priority order:

1. Explicit instructions from the user.
2. Mathematical specification in `docs/statistical-specification.md`.
3. Published paper and supplementary material.
4. Original implementation under `original/`.
5. Existing tests.
6. Existing package documentation.
7. Reasonable implementation conventions.

If two sources conflict, report the conflict. Do not silently choose one interpretation.

---

## 6. Development principles

Use small, reviewable changes.

Each change should have one primary purpose, such as:

* adding characterization tests;
* refactoring an R function;
* moving one bottleneck to Rcpp;
* improving input validation;
* adding documentation;
* fixing one numerical stability issue;
* resolving one CRAN check problem.

Do not rewrite the entire codebase in a single change.

Prefer the following order:

1. Understand the current implementation.
2. Add tests for existing behavior.
3. Refactor without changing behavior.
4. Profile the implementation.
5. Optimize verified bottlenecks.
6. Compare results with the original implementation.
7. Document the change.

Do not optimize code solely because it looks inefficient. Use profiling or a clear complexity argument.

---

## 7. R package design

Public functions must have a clear and minimal user-facing API.

Prefer a small set of high-level functions, such as:

```r
fit_method()
predict.method_fit()
print.method_fit()
summary.method_fit()
plot.method_fit()
method_control()
```

Use S3 classes unless another object system is clearly justified.

Public functions must:

* validate inputs;
* produce informative errors;
* document arguments and return values;
* avoid unnecessary console output;
* support reproducible random-number generation;
* avoid modifying global options;
* avoid changing the working directory;
* avoid writing outside temporary or user-specified directories;
* return structured objects rather than unstructured collections of values.

Internal helper functions should not be exported unless users genuinely need them.

Do not expose low-level C++ interfaces directly to users unless required.

---

## 8. R coding conventions

Use clear and conventional R code.

Prefer:

* descriptive function and variable names;
* explicit arguments;
* preallocation;
* vectorized operations when they improve clarity or performance;
* `seq_len()` and `seq_along()` where appropriate;
* `on.exit()` for cleanup;
* `match.arg()` for constrained character arguments;
* `stop()` or `rlang::abort()` with informative messages;
* `warning()` for recoverable but important issues.

Avoid:

* hidden global state;
* reliance on objects in `.GlobalEnv`;
* repeated vector growth with `c()` inside loops;
* `setwd()`;
* unconditional `print()` or `cat()` calls;
* partial argument matching;
* unnecessary package dependencies;
* modifying user options without restoring them;
* nonstandard evaluation unless clearly justified.

Do not replace readable R code with complicated code unless there is a demonstrated benefit.

---

## 9. Rcpp and C++ conventions

Use Rcpp or RcppArmadillo only where it provides a meaningful benefit.

Good candidates include:

* deeply nested loops;
* repeated likelihood evaluations;
* sufficient-statistic updates;
* intensive indexing operations;
* tree traversal;
* repeated matrix or vector calculations;
* operations that cause excessive allocation in R.

Do not move simple orchestration, input validation, or user-facing logic into C++ without a strong reason.

The R interface must validate:

* dimensions;
* types;
* missing values;
* non-finite values;
* index ranges;
* symmetry or positive definiteness where required;
* compatibility among input objects.

C++ code must:

* avoid out-of-bounds access;
* avoid undefined behavior;
* avoid dangling references;
* avoid unnecessary copying;
* avoid memory leaks;
* use appropriate integer types;
* check assumptions at the R boundary;
* remain portable across CRAN platforms.

Do not use compiler-specific extensions unless necessary and documented.

Do not add aggressive compiler flags such as `-march=native`.

Do not use private or undocumented R APIs.

---

## 10. Random-number generation

Stochastic routines must be reproducible through R's random-number generation system.

Prefer R or Rcpp random-number functions compatible with `set.seed()`.

Do not introduce an independent C++ random-number generator unless explicitly requested.

If parallel random-number generation is introduced:

* document the RNG scheme;
* verify reproducibility;
* allow parallel execution to be disabled;
* avoid dependence on scheduling order;
* test behavior across supported platforms.

Do not change the order or number of random draws without documenting the consequence for exact reproducibility.

---

## 11. Numerical stability

Preserve the mathematical target while improving numerical stability.

Consider, where appropriate:

* log-scale calculations;
* log-sum-exp identities;
* Cholesky or QR decompositions;
* solving linear systems instead of forming explicit inverses;
* stable probability normalization;
* sparse matrix representations;
* reuse of factorizations;
* avoidance of subtracting nearly equal quantities;
* explicit handling of underflow and overflow.

Any numerical stabilization must be accompanied by tests.

Document cases where the optimized implementation is numerically equivalent but not bitwise identical to the original implementation.

---

## 12. Testing policy

Do not modify core numerical code before adding tests that capture the existing behavior.

Tests should be divided into the following categories.

### 12.1 Mathematical unit tests

Test individual formulas and transformations against:

* hand calculations;
* direct R implementations;
* analytic solutions;
* known identities;
* small enumerated examples.

### 12.2 Characterization tests

Record the current behavior of the original implementation on small deterministic examples.

These tests may cover:

* intermediate quantities;
* log-likelihood values;
* sufficient statistics;
* initialization;
* one-step updates;
* fixed-seed output;
* summary statistics.

### 12.3 Original-versus-new regression tests

Compare the new implementation with the original implementation.

Use suitable tolerances and explain them.

Do not weaken tolerances merely to make a failing test pass.

### 12.4 Boundary and failure tests

Test cases such as:

* empty inputs;
* one observation;
* one parameter;
* zero counts;
* repeated values;
* singular matrices;
* nearly singular matrices;
* missing values;
* infinite values;
* invalid dimensions;
* invalid hyperparameters;
* extreme parameter values.

### 12.5 Statistical validation tests

Where appropriate, test:

* parameter recovery from simulated data;
* agreement with an analytic posterior;
* posterior moments;
* acceptance rates;
* stationary distributions;
* simulation-based calibration;
* posterior predictive behavior.

Heavy statistical validation should normally be kept outside routine CRAN checks.

---

## 13. Rules for modifying tests

Tests are part of the specification.

Do not:

* delete a failing test without explanation;
* replace a precise test with a weaker test;
* substantially increase tolerances without justification;
* skip a test merely because a new implementation fails it;
* alter expected results to match new output without investigating the cause.

When output legitimately changes, document:

1. why the change is expected;
2. whether it is numerical or methodological;
3. how the new expected behavior was validated.

---

## 14. Reproducibility levels

Distinguish among:

### Exact reproducibility

The same random seed produces identical output.

### Numerical reproducibility

Outputs agree within a specified floating-point tolerance.

### Inferential reproducibility

Posterior summaries, estimators, predictions, or scientific conclusions agree, even if individual stochastic draws differ.

State which level applies to each comparison.

Do not claim exact reproducibility when only numerical or inferential reproducibility has been demonstrated.

---

## 15. Benchmarking policy

All performance claims must be supported by reproducible benchmark scripts.

Benchmark at least:

* the original implementation;
* the refactored R implementation;
* the Rcpp implementation, when present.

Record:

* input size;
* number of iterations;
* elapsed time;
* memory allocation where feasible;
* R version;
* package versions;
* operating system;
* relevant hardware information;
* whether compilation time is included.

Do not optimize only for tiny artificial examples.

Include scaling experiments when computational complexity is important.

Do not trade substantial numerical accuracy for speed without explicit approval.

---

## 16. Documentation requirements

Every exported function must include roxygen2 documentation covering:

* purpose;
* arguments;
* return value;
* statistical interpretation;
* important assumptions;
* reproducibility behavior;
* examples;
* references.

Important internal numerical routines should have comments explaining the mathematics, not merely restating the code.

Maintain the following documents where relevant:

```text
docs/code-audit.md
docs/statistical-specification.md
docs/original-vs-package.md
docs/numerical-validation.md
docs/performance-notes.md
```

Update `NEWS.md` for user-visible changes.

---

## 17. Paper and citation policy

The package must cite the published paper that introduced the method.

The package documentation should clearly distinguish:

* the statistical method;
* the original research implementation;
* the current package implementation.

Do not claim that the package reproduces the paper exactly unless this has been verified.

Provide citation information through `inst/CITATION` or the package's standard citation mechanism.

If external code influenced an implementation, record the source and verify license compatibility.

Do not copy substantial code from another package or repository without attribution and license review.

---

## 18. CRAN compatibility

The package must be designed for CRAN from the beginning.

The package must not:

* require internet access in tests, examples, or vignettes;
* write outside temporary or explicitly selected directories;
* modify the user's environment;
* depend on undeclared packages;
* use unavailable system commands;
* assume a particular operating system;
* use nonportable compiler options;
* use excessive runtime in examples or tests;
* use excessive memory;
* automatically use many CPU cores;
* produce unsolicited console output;
* fail when suggested packages are unavailable.

Examples and tests must be short enough for CRAN checks.

Long simulations, large datasets, and full paper reproductions belong in a separate reproducibility repository or optional scripts.

---

## 19. Dependency policy

Minimize dependencies.

Before adding a dependency, determine:

1. whether base R already provides the needed functionality;
2. whether the dependency is maintained;
3. whether it is available on CRAN;
4. whether it is needed at runtime or only for development;
5. whether it belongs in `Imports`, `LinkingTo`, `Suggests`, or `Enhances`.

Do not add a dependency for a trivial helper function.

Rcpp-related packages must be declared correctly in `DESCRIPTION`.

---

## 20. Parallel computing

Do not introduce parallel computing in the initial implementation unless explicitly requested.

Before adding parallelism:

1. optimize the sequential implementation;
2. profile remaining bottlenecks;
3. verify numerical correctness;
4. define reproducible RNG behavior;
5. limit the number of workers;
6. allow users to disable parallelism;
7. test on multiple operating systems.

Parallel execution must not be required for basic package functionality.

---

## 21. Error handling

Errors must explain:

* what input was invalid;
* what condition was expected;
* where feasible, how the user can fix it.

Avoid cryptic C++ errors reaching the user.

Validate inputs in R before calling C++ when this produces clearer errors.

Do not silently coerce inputs when the coercion may change their meaning.

Use warnings only when the computation can continue with a meaningful result.

---

## 22. Change reporting

For each meaningful code change, report:

1. files changed;
2. purpose of the change;
3. whether statistical behavior changed;
4. tests added or updated;
5. numerical comparisons performed;
6. performance impact;
7. unresolved risks.

When changing a numerical algorithm, include a concise before-and-after description.

---

## 23. Required workflow for core changes

Before modifying a core statistical or numerical routine:

1. Locate the corresponding original implementation.
2. Identify the mathematical operation.
3. Identify existing tests.
4. Add characterization tests if coverage is insufficient.
5. Make the smallest practical change.
6. Run relevant unit tests.
7. Compare with the original implementation.
8. Run package checks.
9. Update documentation.
10. Record performance results if the change was intended as an optimization.

Do not skip directly from code inspection to wholesale replacement.

---

## 24. Prohibited autonomous changes

Do not independently:

* change the statistical model;
* introduce an approximation;
* change parameter constraints;
* change default priors;
* change MCMC kernels;
* change output definitions;
* remove supported functionality;
* change package licensing;
* alter authorship or citation information;
* delete original files;
* add network services;
* upload data;
* publish releases;
* submit to CRAN.

These actions require explicit user approval.

---

## 25. Initial project phases

Unless instructed otherwise, proceed in this order.

### Phase 1: Audit

Inspect the repository without changing implementation files.

Produce:

```text
docs/code-audit.md
```

### Phase 2: Statistical specification

Translate the paper and original code into:

```text
docs/statistical-specification.md
```

Clearly mark uncertainties and inconsistencies.

### Phase 3: Characterization tests

Create small deterministic tests that preserve existing behavior.

### Phase 4: R refactoring

Convert scripts and global-state computations into testable functions without changing the algorithm.

### Phase 5: Profiling

Identify genuine computational bottlenecks.

### Phase 6: Rcpp optimization

Move only justified bottlenecks into C++.

### Phase 7: Validation

Compare original and optimized implementations.

### Phase 8: Package documentation

Create user-facing documentation, examples, and vignettes.

### Phase 9: CRAN preparation

Resolve package checks across supported platforms and prepare submission materials.

---

## 26. Communication style

Be explicit about uncertainty.

Use labels such as:

* confirmed from the paper;
* confirmed from the original code;
* inferred from context;
* unresolved;
* possible bug;
* possible numerical issue;
* proposed optimization.

Do not describe an assumption as a fact.

When multiple implementation choices are reasonable, present the tradeoffs before selecting one.

Prioritize correctness, reproducibility, and maintainability over cleverness.
