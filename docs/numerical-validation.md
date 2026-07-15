# boostPM numerical validation

## 1. Scope

- Validation date: 2026-07-14
- Archived commit: `1732dba73d3788c9c457f958c4e5699f12ff3bab`
- Archived test location: `validation/characterization/testthat/`
- Archived runner: `validation/characterization/run-original.R`
- Package test location: `tests/testthat/`
- Package runner: `tests/testthat.R`
- Statistical implementation changes: none

The suite characterizes the immutable package archive. It installs a temporary copy of `original/`, runs the tests against that copy, and removes the temporary installation. No archived source file is modified.

## 2. Environment

- Operating system: Windows
- R: 4.5.2
- Rcpp: 1.1.1.1
- RcppArmadillo: 14.4.1.1
- testthat: 3.2.3
- Compiler: GCC 14.3.0 from Rtools45

The local sandbox required temporary Make toolchain environment variables. No machine-specific toolchain path was written into the repository.

## 3. Result

```text
known-boundary-behavior: ............
original-numerics: ................
r-wrapper-characterization: ..........................
tree-mathematics: ......

DONE
```

- Test cases: 20
- Explicit `expect_*` calls: 60
- Failures: 0
- Warnings escaping expectations: 0
- Runtime including temporary compilation: approximately 35 seconds

## 4. Test coverage

### 4.1 Mathematical unit checks

- One-split density factors against hand calculations.
- One-split inverse transform against a direct formula.
- Two-tree residual composition order.
- Original-scale support Jacobian.
- One-node variable-importance contribution.

### 4.2 R-wrapper characterization

- Automatic support expansion and unit-cube scaling.
- Archived default arguments and low-level argument order.
- Strict support containment.
- Adaptive stopping control and forced 90% fitting fraction.
- Endpoint and interior tie jitter under fixed seeds.
- Simulation and density wrapper forwarding.
- Constant-column warning and resulting `NaN` behavior.

### 4.3 Fixed-seed numerical regression

- Small univariate fit.
- Small two-dimensional marginal-plus-dependence fit.
- Serialized tree structure and ordering.
- Final residuals.
- Tree sizes and maximum depths.
- Variable importance.
- Density values and cumulative density path.
- Simulated values from the fitted ensemble.
- Repeated fits under the same seed within one runtime.

### 4.4 Known boundary behavior

The following tests intentionally record behavior currently classified as a possible bug:

- `max_resol = 0` can produce leaves at depth 1.
- A training point exactly on a split is counted on the right, while evaluation sends equality left.
- Density evaluation outside `Omega` returns finite values.
- A tree rejected by adaptive stopping is evaluated but not stored or applied.
- A constant column warns and becomes non-finite during preprocessing.

Passing these tests does not mean the behavior is desirable. It means the behavior has been preserved accurately.

## 5. Reproducibility level

### Exact reproducibility

Confirmed only within the tested runtime for selected fit components. Repeating the small two-dimensional fit with the same seed produced identical residuals, tree structures, depths, and variable importance. Elapsed time is excluded.

### Numerical reproducibility

Hard-coded archived numerical fixtures are checked with tolerances from `1e-15` to `1e-13`, depending on the calculation. This is the current cross-runtime target until other platforms are tested.

### Inferential reproducibility

Not assessed. No parameter-recovery, simulation-based calibration, posterior predictive, or paper-result reproduction test has been run.

## 6. Remaining validation gaps

- Other R, Rcpp, and RcppArmadillo versions.
- Missing and infinite inputs.
- Empty data and very small samples.
- Invalid control values.
- Density integration to one.
- Large-sample statistical behavior.
- Parameter recovery.
- Full reproduction of paper tables and figures.
- Direct original-versus-package comparisons on Linux and macOS.
- Performance and memory benchmarks.

## 7. Run command

From the project root in a normal R development environment:

```text
Rscript --vanilla validation/characterization/run-original.R
```

The runner requires Rcpp, RcppArmadillo, testthat, and a working package compiler toolchain.

## 8. Package-skeleton validation

On 2026-07-14, the new root package was compiled and installed with R 4.5.2 and
the same Windows toolchain. Its routine numerical, mathematical, and known
boundary tests passed. The archived suite was then rebuilt independently and
all 20 cases and 60 explicit expectations passed.

One variable-importance check differed from its analytic expression by one ULP,
approximately `1.1e-16`, in both builds. The test now checks absolute error
against the unchanged `1e-15` threshold because testthat edition 3 applies the
`tolerance` argument relatively. This is a test-semantics correction rather
than a numerical algorithm change.

The source package passed installation, examples, and routine tests during
`R CMD check --as-cran --no-manual`. After applying the MIT License, the
remaining status was four notes and no warnings. The notes include
development-version metadata, offline URL checks, the retained C++11
request, local clock verification, and missing pandoc in the check environment.

## 9. R-wrapper refactoring validation

On 2026-07-14, the single archived R wrapper was split into preprocessing,
early-stopping controls, fitting orchestration, and post-processing modules.
No C++ source was changed.

The routine package suite now contains 18 test cases and 54 explicit
expectations. All passed. A direct in-process comparison between the archived
and refactored wrappers also confirmed identical function arguments, values
forwarded to C++, returned content excluding elapsed time, and final R random
number state for fixed-seed tie and early-stopping cases.

The independently compiled archived suite continued to pass all 20 cases and
60 explicit expectations. `R CMD check --as-cran --no-manual` completed with
no warnings and the same four environment or development notes.

## 10. C++ portability and safety validation

On 2026-07-14, the package C++ layer was refactored for portability, exception
safety, reentrancy of post-processing, and user interruption. No likelihood,
prior, split rule, default, random draw, tree serialization format, or boundary
convention was intentionally changed.

The routine suite contains 22 test cases and 61 explicit expectations after
adding malformed-input checks. All passed. The independently compiled archive
continued to pass 20 cases and 60 expectations. Fixed-seed numerical fixtures
for fitting, density evaluation, and simulation remained unchanged within the
existing tolerances.

`R CMD build` succeeded. `R CMD check --as-cran --no-manual` completed with no
warnings and three notes. The earlier C++11 specification note was removed. The
remaining notes concern development-version and offline URL checks, local clock
verification, and unavailable pandoc in the check environment.

## 11. R-side input-validation layer

On 2026-07-14, public fitting and post-processing wrappers gained R-side checks
for input types, dimensions, finiteness, integer-valued structural controls,
support widths, adaptive-stopping structure, and required fitted-object
components. Invalid inputs now stop before preprocessing or C++ with explicit
messages.

The routine suite contains 29 test cases and 79 explicit expectation calls.
All passed. The independently compiled archive continued to pass 20 cases and
60 expectation calls. Existing fixed-seed numerical, mathematical, wrapper,
and known-boundary tests also passed.

No statistical parameter range or established boundary convention was changed.
Those decisions are recorded with alternatives in `docs/input-validation.md`.

## 12. Approved input and boundary changes

On 2026-07-14, the package author selected the parameter domains and boundary
rules recorded in `docs/input-validation.md`. The implementation now rejects
constant columns, enforces the selected parameter domains, checks jittered
support membership, returns `-Inf` outside `Omega`, assigns split equality
left, removes `max_n_var`, reports invalid fitting bins explicitly, and adds S3
class `boostPM_fit` while retaining list compatibility.

The routine suite contains 34 test cases and 84 explicit expectation calls.
All passed on Windows with R 4.5.2. Existing interior fixed-seed fixtures for
trees, residuals, density, simulation, variable importance, and RNG behavior
continued to pass at their original tolerances. The changed equality and
outside-support behaviors have dedicated new expectations rather than weakened
legacy tolerances.

The archived implementation remains unchanged and its separate suite continues
to define the historical behavior. `R CMD build` succeeded, and
`R CMD check --as-cran --no-manual` completed with no errors, no warnings, and
three notes concerning development/offline incoming checks, local clock
verification, and unavailable pandoc.

## 13. Boundary-safe binning

On 2026-07-14, the initial error-only bin guard was replaced with the approved
equality-left assignment rule. Candidate bins are selected with
`std::lower_bound()`, the exact node right endpoint enters the final bin, and
endpoint drift within
`64 * epsilon * max(1, abs(left), abs(right))` is clamped and retained in the
residual matrix. Larger violations remain errors.

The routine suite contains 34 cases and 90 explicit expectation calls. Tests
cover exact right-endpoint assignment, correction from both sides by 16 machine
epsilons, rejection of a material interval violation, and the existing
candidate-equality fit. Interior fixed-seed numerical fixtures remain within
their existing tolerances. `R CMD build` succeeded, and
`R CMD check --as-cran --no-manual` completed with no errors, no warnings, and
the same three environment or development notes.

## 14. Constant-time uniform-grid binning

On 2026-07-14, per-residual `std::lower_bound()` lookup was replaced with an
arithmetic provisional index and at most two comparisons against actual grid
candidates. Endpoint tolerance, equality-left allocation, and explicit failure
on an unresolved interval invariant remain in place.

The routine suite retained 34 cases and 90 explicit expectation calls. The
archived characterization suite retained 20 cases and 60 explicit expectation
calls. Both passed. Full-fit benchmark checksums agreed across the current
arithmetic build, the preceding `lower_bound` build, the archived floor build,
and `original/` for all four measured cases. This supports exact reproducibility
for those deterministic benchmark outputs; cross-platform verification remains
unresolved. `R CMD build` succeeded. `R CMD check --as-cran --no-manual`
completed with no errors, no warnings, and the same three environment or
development notes.

## 15. Original comparison and statistical validation

On 2026-07-14, separate validation runners were added outside routine CRAN
checks. `validation/regression/run-original-vs-package.R` installs copied
versions of `original/` and the current package into distinct temporary
libraries and executes them in separate R processes. This avoids a namespace
collision while comparing the same fixed-seed computation.

Three valid, strictly interior fixtures were compared: a univariate fixture, a
small two-dimensional fixture, and a two-dimensional `nbins = 8` fixture. For
each fixture, the fitted object excluding timing and class metadata, density
evaluation, simulation, and final R RNG state matched with `identical()`.
This establishes exact reproducibility for those fixtures. It does not apply to
the intentional differences in boundary assignment, validation errors, or the
removed `max_n_var` option.

The paper's Section 3 evaluates fitted distributions with held-out average
log-density, termed the predictive score. The new statistical runner uses this
criterion on three simulated unit-support distributions and three fixed data
seeds. It also checks finite interior densities, Monte Carlo normalization
within 0.20 of one, and simulated values inside the support.

| scenario | mean train score | mean test score | mean MC integral | mean simulated-mean L1 error |
|---|---:|---:|---:|---:|
| Beta(2, 5), 1D | 0.42484 | 0.41467 | 0.99830 | 0.04098 |
| Gaussian copula, 2D, rho = 0.8 | 0.07394 | 0.06178 | 0.99997 | 0.01196 |
| Uniform, 2D | 0.01082 | -0.00331 | 1.00038 | 0.00874 |

The positive scores for the non-uniform examples and the near-zero uniform
test score are descriptive results, not a performance guarantee. The runners
are intended for regression detection and later expansion with paper-scale
experiments.

`.github/workflows/R-CMD-check.yaml` now defines checks on Windows, macOS, and
Ubuntu. GitHub Actions run 29393713955 completed successfully on all three
platforms. This confirms compilation, examples, and the routine test suite on
the hosted release-R environments. It does not establish exact numerical
equality across platforms. After excluding `.github` from the source tarball,
the final local Windows `R CMD check --as-cran --no-manual` completed with 0
errors, 0 warnings, and 2 notes: the development version/new-submission notice
and unavailable local pandoc.
