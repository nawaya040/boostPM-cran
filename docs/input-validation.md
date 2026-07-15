# R-side input validation

Implementation date: 2026-07-14.

## Scope

This layer validates public R inputs before preprocessing or C++. It does not
resolve statistical parameter domains or established boundary conventions that
require an explicit methodological decision.

## Implemented checks

### Fitting

- `data`: finite numeric matrix with at least one row and column.
- `add_noise`: one non-missing logical value.
- supplied `Omega`: finite numeric matrix with one row per data variable,
  exactly two columns, and strictly positive row widths.
- tree counts and `max_resol`: non-negative integer-valued numbers within the
  Rcpp integer range.
- `min_obs`: positive integer-valued number within that range.
- `nbins`: integer-valued number of at least two, ensuring at least one split
  candidate.
- `0 < c0 < 1`, `gamma >= 0`, `0 <= alpha <= 1`, `beta >= 0`, and
  `precision > 0`.
- `early_stop`: `NULL` or a finite numeric vector of length two, with an
  integer waiting window of at least two.
- adaptive stopping: at least two observations when any tree may be fitted,
  preventing an empty 90% training subset.

### Simulation and density evaluation

- fitted object: a list containing a list-valued `tree_list` and valid `Omega`.
- simulation size: non-negative integer-valued scalar within the Rcpp integer
  range; zero remains supported.
- evaluation points: finite numeric matrix with one column per support
  dimension.
- serialized-tree details: retained in C++, where reconstruction already
  reports explicit errors before traversal.

## Behavior statement

Most interior valid-input calculations and random draws remain unchanged.
Approved changes affect parameter domains, constant columns, jitter escaping a
support, split-point equality, density outside the support, the experimental
`max_n_var` control, and fitted-object class metadata. The immutable archive
remains unchanged.

## Decision record and alternatives

The decisions below were approved by the package author on 2026-07-14. The
alternatives remain recorded to explain why behavior differs from the archive.

### 1. Constant columns and automatic support

**confirmed from the original code:** a constant column with automatic support
can warn and become `NaN`, because its constructed support has zero width.

Options:

1. Reject every constant column before jitter. Simple and safest for continuous
   density estimation.
2. Allow it only with a user-supplied positive-width `Omega` and
   `add_noise = FALSE`. Explicit, but the empirical dimension remains
   degenerate.
3. Construct artificial width and jitter within it. Convenient, but adds a new
   preprocessing and RNG rule.
4. Remove constant dimensions and restore them in output. This changes fitted
   dimension and needs a statistical interpretation.

**approved decision:** option 1. Constant columns are rejected.

### 2. Learning-rate domain for `c0`

**confirmed from the paper:** `c0` lies in `(0, 1]`.

**possible numerical issue:** at `c0 = 1`, an empty child can produce mass zero
or one, making logarithms and inverse maps singular.

Options:

1. Require `0 < c0 < 1`. Strongest protection, but excludes the paper endpoint.
2. Require `0 < c0 <= 1`, matching the paper, then handle zero/one masses.
3. Allow `c0 = 0` as a no-learning case and require `0 <= c0 < 1`.
4. Retain scalar-finiteness checking only.

**approved decision:** option 1. The package requires `0 < c0 < 1`.

### 3. Scale exponent `gamma`

**confirmed from the paper:** `gamma >= 0`. Negative values can make the
node-specific learning rate grow on smaller nodes and possibly exceed one.

Options:

1. Require `gamma >= 0`, matching the paper.
2. Allow negative values only when the effective rate stays valid through
   `max_resol`.
3. Retain scalar-finiteness checking as an undocumented extension.

**approved decision:** option 1. The package requires `gamma >= 0`.

### 4. Split-prior parameters `alpha` and `beta`

The code uses `alpha * (depth + 1)^(-beta)` as a split probability.

Options:

1. Require `0 <= alpha <= 1` and `beta >= 0`. Simple and sufficient at every
   depth.
2. Validate only depths reachable under `max_resol`, permitting some negative
   `beta` values.
3. Require `0 < alpha < 1` and `beta >= 0`, excluding deterministic choices.
4. Retain scalar-finiteness checking only.

**approved decision:** option 1. The package requires `0 <= alpha <= 1` and
`beta >= 0`. The separate paper-versus-code conflict over the reported value of
`alpha` remains unresolved.

### 5. Auxiliary beta-prior `precision`

The beta shapes are `precision * L` and `precision * (1 - L)`, implying
positive precision.

Options:

1. Require `precision > 0`.
2. Add a positive numerical lower bound, which would need justification.
3. Retain scalar-finiteness checking and allow downstream non-finite results.

**approved decision:** option 1. The package requires `precision > 0`.

### 6. Jitter relative to user-supplied `Omega`

**confirmed from the original code:** membership is checked on raw data before
jitter, so jittered ties can leave `Omega`.

Options:

1. Preserve jitter and reject if its result leaves `Omega`. Random-draw order
   remains unchanged for successful fits.
2. Redraw until inside. Changes the draw count and jitter distribution.
3. Truncate at the support. Changes the distribution and may create ties.
4. Define jitter intervals using neighbors and `Omega`. A new preprocessing
   algorithm.
5. Disable jitter implicitly when support is narrow. Convenient, but difficult
   to reproduce and explain.

**approved decision:** option 1. Jitter is preserved, then checked against the
strict interior of `Omega`; an escaped value raises an error.

### 7. Evaluation outside `Omega`

**confirmed from current behavior:** finite density values are returned outside
the declared support.

Options:

1. Return log density `-Inf`, consistent with bounded support.
2. Raise an error for any outside point.
3. Preserve finite extrapolation and document it as intentional.
4. Add a user option selecting error, `-Inf`, or legacy extrapolation.

**approved decision:** option 1. Points outside `Omega` receive log density
`-Inf`.

### 8. Equality at a split boundary

**confirmed conflict:** the paper assigns equality left. Training assigns it
right, while density evaluation assigns it left.

Options:

1. Use the paper's left convention everywhere.
2. Use the training code's right convention everywhere.
3. Preserve and document the mixed legacy convention.

Options 1 and 2 can alter trees for tied, rounded, or boundary-valued data.

**approved decision:** option 1. Fitting, evaluation, and inverse simulation
assign equality left, following the paper.

### 9. Meaning of `max_resol`

Current code permits a node at `max_resol` to split, creating leaves at
`max_resol + 1`.

Options:

1. Treat it as deepest resulting leaf and stop at `depth >= max_resol`.
2. Treat it as deepest splittable node and retain current behavior.
3. Rename the control to express current semantics, with a compatibility alias.

**approved decision:** option 2. `max_resol` retains the archived meaning of the
deepest splittable node; resulting leaves may occur at `max_resol + 1`.

### 10. `max_n_var` status and upper range

This is an experimental code extension absent from the published method.
Values above data dimension currently act as no effective cap.

Options:

1. Keep it public, require `1 <= max_n_var <= d`, and default to `d`.
2. Keep it public and allow values above `d` as no-cap behavior.
3. Move it to an internal or experimental control object.
4. Remove it after compatibility review.

**approved decision:** option 4. `max_n_var` and its variable-restriction state
are removed from the package implementation. They remain documented as
archived-code provenance.

### 11. C++ bin indexing at node boundaries

The archived fitting code computes a floor-derived bin index. A residual at a
node's right boundary, or outside after numerical drift, can index past the
vector. Floor binning also assigns equality with an internal candidate to its
right bin, conflicting with the approved equality-left rule.

Options:

1. Detect and raise an informative error. Prevents undefined access without
   silently changing allocation.
2. Clamp into `[0, nbins - 1]`. Operationally robust, but changes the boundary
   allocation rule.
3. Adjust residuals with a defined tolerance. Requires a justified tolerance.

**initial approved decision:** option 1. C++ first raised an explicit error
before invalid access.

**approved refinement:** candidate lookup now uses `std::lower_bound()`, so
candidate equality enters the left bin and the exact node right endpoint enters
the final bin. Drift within
`64 * epsilon * max(1, abs(left), abs(right))` is clamped to the endpoint and
retained. Larger violations still raise an explicit error.

**approved optimization:** the uniform grid now supplies a constant-time
arithmetic provisional index. Comparisons with the adjacent actual candidate
values retain the same equality-left rule. The endpoint tolerance and explicit
failure for an unresolved interval invariant remain unchanged.

### 12. Accepted R input classes

The documented API specifies numeric matrices, which the validator now
enforces.

Options:

1. Retain strict matrix input. Predictable, without silent coercion.
2. Accept all-numeric data frames through explicit conversion.
3. Apply `as.matrix()` broadly. Convenient, but mixed frames may become
   character matrices.

**approved decision:** option 1. Public data inputs remain numeric matrices.

### 13. Fitted-object contract

The archived return value is an unclassed list. The package retains that list
layout and adds class `boostPM_fit`. R checks required top-level components;
C++ checks serialized trees.

Options:

1. Retain the unclassed list for compatibility.
2. Add an S3 class without changing contents, while accepting older saved fits.
3. Replace the structure and provide a compatibility converter.

**approved decision:** option 2. New fits receive class `boostPM_fit`; their list
contents remain compatible, and post-processing continues to accept structurally
valid unclassed fits.

### 14. Training observations on the boundary of `Omega`

The original R code requires every training observation to lie strictly inside
the supplied support. Equality to either endpoint is rejected. This avoids unit
coordinates zero and one, which can interact with C++ bin indexing.

Options:

1. Retain strict interior containment. Safest and exactly compatible.
2. Permit endpoint equality and define its bin and tree allocation explicitly.
3. Permit values within a numerical tolerance, then move or clamp them inward.
   This needs a scale-aware tolerance and changes normalized data.

**approved decision:** option 1. Training observations must remain strictly
inside a supplied `Omega`.
