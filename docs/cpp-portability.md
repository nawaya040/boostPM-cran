# C++ portability and safety notes

## Scope

Date: 2026-07-14.

This change applies only to the package implementation under `src/`. The
immutable files under `original/` were not modified.

## Changes

### Portability

- Standard C++ headers replace `bits/stdc++.h`.
- Unused OpenMP flags were removed from `Makevars` and `Makevars.win`.
- The explicit C++11 request was removed; the tested R 4.5.2 toolchain used
  its default GNU++17 mode.
- Header files no longer import the Rcpp, Armadillo, or standard namespaces.
- Rcpp export signatures use qualified types and can be regenerated normally.

### Safety

- The fitting node and post-processing node now have distinct type names,
  removing the previous one-definition-rule risk.
- Post-processing dimensions are local variables rather than process-global
  state.
- Active trees are owned by scope guards and are released during exceptions or
  user interruption.
- Tree cleanup is non-allocating and marked `noexcept`.
- Long C++ loops periodically check for user interruption.
- Post-processing checks support shape and width, evaluation dimensions and
  finiteness, simulation size, and serialized tree structure before indexing.

## Portability-refactor statistical behavior

At the portability-refactor milestone, there was no intentional statistical or
numerical algorithm change. Fixed-seed package
fixtures and the independently built archive agree at the previously recorded
reproducibility levels. Random-number order is unchanged because interrupt and
validation checks do not draw random values.

Malformed post-processing inputs now produce explicit R errors instead of
reaching undefined indexing or allocation behavior. This is an error-handling
change, not an output change for valid fitted objects.

## Remaining risks

- Linux and macOS compilation has not yet been run.
- The unused prototype `count_tree` code still uses recursive ownership and
  should be removed or isolated only after confirming it is not supported API.

## Boundary-safe binning update

On 2026-07-14, after explicit approval, floor-derived bin indexing was replaced
by `std::lower_bound()` over the actual candidate split points. Candidate
equality follows the paper's left-child convention, and the exact node right
endpoint maps to the final valid bin.

Round-off drift no larger than
`64 * epsilon * max(1, abs(left), abs(right))` is clamped to the corresponding
node endpoint and retained in the residual matrix. Larger violations raise an R
error before vector access. The implementation uses standard C++17 facilities.

The subsequent uniform-grid optimization replaces the per-residual binary
search with a constant-time arithmetic index. At most two comparisons against
the existing `L_candidates` values preserve equality-left behavior. A final
interval check prevents an unresolved rounded index from reaching vector
access. Fixed-seed and boundary tests remained unchanged. Recorded full-fit
time is 8%--33% lower than the preceding `lower_bound` implementation.

## Verification

- Package tests: 34 cases, 90 explicit expectation calls, all passed.
- Archived tests: 20 cases, 60 explicit expectations, all passed.
- `Rcpp::compileAttributes()` completed successfully.
- `R CMD build` completed successfully.
- `R CMD check --as-cran --no-manual`: 0 warnings, 3 notes.
