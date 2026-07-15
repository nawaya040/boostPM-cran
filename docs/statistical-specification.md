# boostPM statistical specification

## 1. Purpose and status

This document specifies the statistical target and the numerical procedure for boostPM. It separates the published method from the behavior of the archived implementation.

Status labels:

- **confirmed from the paper**: stated in Awaya and Ma (2024)
- **confirmed from the original code**: directly implemented at archived commit `1732dba73d3788c9c457f958c4e5699f12ff3bab`
- **confirmed from the experiment code**: stated in `MaStatLab/boostPM_experiments`
- **inferred from context**: interpretation requiring verification
- **unresolved**: sources disagree or do not provide enough information
- **possible bug**: code behavior that may be unintended
- **possible numerical issue**: behavior that may create unstable or non-finite results

This document does not authorize changes to the statistical method or to `original/`.

## 2. Authoritative sources

The source order for this project is:

1. Explicit user instructions.
2. This statistical specification after review.
3. Awaya and Ma (2024), including appendices.
4. Archived implementation under `original/`.
5. Public experiment scripts.
6. Tests and package documentation.

The local paper is:

```text
docs/references/paper/Awaya_Ma_2024.pdf
```

The archived source is code-identical to the implementation in the repository cited by the paper. See `docs/code-provenance.md`.

## 3. Scope of the model

### 3.1 Observations

**confirmed from the paper**

Let

$$
x_1,\ldots,x_n \overset{\mathrm{iid}}{\sim} F^*
$$

on a continuous (d)-dimensional sample space. The paper works without loss of generality on

$$
\Omega=(0,1]^d
$$

with uniform probability measure (\mu).

**confirmed from the original code**

The R interface expects a numeric observation matrix with shape (n\times d): rows are observations and columns are variables. A source comment incorrectly says (d\times n); the example and implementation use (n\times d).

### 3.2 Distributional assumptions

**confirmed from the paper**

- The motivating theory assumes distributions absolutely continuous with respect to Lebesgue measure.
- Tree measures have full support on (\Omega).
- Each tree measure is conditionally uniform on every leaf of its partition tree.
- Tied observations are treated as technical rounding artifacts only when the user deliberately applies jitter under a continuous-data assumption.

The method is a density model. Discrete atoms and mixed discrete-continuous distributions are not specified by the paper.

### 3.3 Target and approximation

The fitted distribution is a finite ordered ensemble

$$
F=G_1\oplus\cdots\oplus G_K,
$$

where each (G_k) is a tree-based probability measure associated with a finite recursive partition tree (T_k).

The approximation is piecewise constant within each weak learner, but the ensemble is formed through compositions of tree-CDF maps rather than a mixture or arithmetic average of densities.

## 4. Recursive partition trees

### 4.1 Nodes and splits

**confirmed from the paper**

A node is an axis-aligned rectangle

$$
A=(a_1,b_1]\times\cdots\times(a_d,b_d].
$$

For a selected dimension (j) and split point (c_j\in(a_j,b_j)), the children are

$$
A_l=(a_1,b_1]\times\cdots\times(a_j,c_j]\times\cdots\times(a_d,b_d],
$$

and

$$
A_r=(a_1,b_1]\times\cdots\times(c_j,b_j]\times\cdots\times(a_d,b_d].
$$

Thus the mathematical convention assigns the split point to the left child.

### 4.2 Tree-measure class

For a finite tree (T), let (\mathcal L(T)) be the leaves and (\mathcal N(T)) the nonterminal nodes. The class (\mathcal P_T) contains full-support measures (G) satisfying

$$
G(\cdot\mid A)=\mu(\cdot\mid A), \qquad A\in\mathcal L(T).
$$

A tree measure is determined by its conditional left-child masses

$$
q_A=G(A_l\mid A), \qquad A\in\mathcal N(T).
$$

For a split in dimension (j), define the geometric left fraction

$$
L_A=\mu(A_l\mid A)=\frac{c_j-a_j}{b_j-a_j}.
$$

## 5. Tree-CDF transform

### 5.1 Local move

**confirmed from the paper and original code**

For (x\in A), only the split coordinate changes. The local move is

$$
G_{A,j}(x)=
\begin{cases}
a_j+\dfrac{q_A}{L_A}(x_j-a_j), & x\in A_l,\\[6pt]
b_j+\dfrac{1-q_A}{1-L_A}(x_j-b_j), & x\in A_r,
\end{cases}
$$

and (G_{A,h}(x)=x_h) for (h\ne j).

The local density factor is therefore

$$
g_A(x)=
\begin{cases}
q_A/L_A, & x\in A_l,\\
(1-q_A)/(1-L_A), & x\in A_r.
\end{cases}
$$

### 5.2 Tree-CDF

For the nested branch containing (x), the tree-CDF (\mathbf G) is the fine-to-coarse composition of local moves. The archived code finds the terminal node, walks upward to the root, and applies each local move in that order.

**confirmed from the paper**

- (\mathbf G:(0,1]^d\to(0,1]^d) is measurable and bijective for a full-support tree measure.
- The pair ((G,T)) determines the tree-CDF representation.
- If (X\sim G), then (\mathbf G(X)\sim\mathrm{Unif}((0,1]^d)).
- If (U\sim\mathrm{Unif}((0,1]^d)), then (\mathbf G^{-1}(U)\sim G).

The uniform measure is the identity or “zero” element.

## 6. Addition and residualization

### 6.1 Addition

**confirmed from the paper**

For ordered tree measures (G_1,\ldots,G_K), define (F=G_1\oplus\cdots\oplus G_K) through

$$
F(B)=\mu\left(\left\{\mathbf G_K\circ\cdots\circ\mathbf G_1(x):x\in B\right\}\right).
$$

This addition is associative through function composition but is generally not commutative. Tree order is part of the fitted model.

### 6.2 Residuals

Initialize

$$
r_i^{(0)}=x_i.
$$

After fitting (G_k), update

$$
r_i^{(k)}=\mathbf G_k(r_i^{(k-1)}).
$$

If the fitted ensemble equaled the true sampling distribution, the final residual distribution would be uniform.

### 6.3 Identifiability

**confirmed from the paper**

The composed tree-CDF determines the fitted probability measure. The ordered decomposition into individual weak learners need not be unique. No additional parameter-identifiability constraint is stated beyond the ordered tree representation and the local conditional masses.

## 7. Forward-stagewise fitting

### 7.1 Generic algorithm

**confirmed from the paper**

For (k=1,\ldots,K):

1. Fit a weak learner ((G_k,T_k)) to the current residuals (r^{(k-1)}).
2. Store the tree and its conditional masses.
3. Transform every residual by (\mathbf G_k).

The paper interprets each step as a reduction of KL divergence.

### 7.2 Objective

Let (g_k=dG_k/d\mu). The contribution of the (k)th weak learner is

$$
D_k^{(n)}(G_k)=\frac{1}{n}\sum_{i=1}^n\log g_k(r_i^{(k-1)}).
$$

The fitted sample average log density decomposes as

$$
\frac{1}{n}\sum_{i=1}^n\log f(x_i)=\sum_{k=1}^K D_k^{(n)}(G_k).
$$

At the population level, the KL loss decomposes into improvements relative to the uniform measure. A weak learner with positive (D_k^{(n)}) improves the training objective.

### 7.3 Optimal unregularized tree measure

For a fixed tree (T), the unregularized optimum assigns each leaf its empirical residual mass. The preferred tree maximizes the KL separation between empirical leaf masses and uniform leaf volumes:

$$
T_k\in\arg\max_T\sum_{A\in\mathcal L(T)}
\widetilde F_k^{(n)}(A)
\log\frac{\widetilde F_k^{(n)}(A)}{\mu(A)}.
$$

The actual implementation uses a stochastic top-down approximation and shrinkage.

## 8. Weak-learner tree sampler

### 8.1 Candidate rules

**confirmed from the original code**

At a node (A), candidate split fractions are

$$
L_l=\frac{l}{N},\qquad l=1,\ldots,N-1,
$$

where `N = nbins`. The number of candidate split points is therefore `nbins - 1`.

Candidates are considered over the currently active dimensions. The marginal stage activates one dimension; the dependence stage initially activates all dimensions.

**approved package implementation, 2026-07-14**

For candidate points (s_1<\cdots<s_{N-1}), package binning uses

$$
(-\infty,s_1],\ (s_1,s_2],\ldots,\ (s_{N-1},\infty),
$$

restricted to the active node interval. Thus a value equal to a candidate point
is counted on its left, and a value equal to the node's right endpoint enters
the final bin. Because the grid is uniform, the implementation computes a
provisional index in constant time from

$$
\left\lfloor N\frac{x-a}{b-a}\right\rfloor.
$$

The index is clamped only to make endpoint handling safe, then compared with at
most two actual candidate points. Candidate equality decrements to the left bin
when needed. A final interval-invariant check raises an error if floating-point
rounding cannot be resolved by the adjacent corrections. This produces the
same approved allocation rule as the preceding `std::lower_bound()` lookup.

To handle floating-point drift at node endpoints, define

$$
\varepsilon_A=64\,\varepsilon_{\mathrm{machine}}
\max\{1,|a|,|b|\},
$$

for active interval ([a,b]). Values in ([a-\varepsilon_A,a)) are replaced by
(a), and values in ((b,b+\varepsilon_A]) are replaced by (b). The corrected
residual is retained for later allocation and residualization. Values farther
outside the interval raise an error before indexing.

### 8.2 Tree-structure prior implemented in code

At depth (h\), the code uses split probability

$$
p_{\mathrm{split}}(h)=\alpha(h+1)^{-\beta}.
$$

Conditional on splitting, active dimensions and grid locations have uniform prior weights.

The R comments omit the minus sign on (\beta). The C++ expression above is the implemented behavior.

### 8.3 Auxiliary beta prior

For candidate geometric fraction (L), the code uses

$$
\widetilde\theta_A\sim
\mathrm{Beta}(\tau L,\tau(1-L)),
$$

where `tau = precision`. This auxiliary random measure is used to integrate the node likelihood and choose a tree structure. It is not the final fitted mass (q_A).

For node counts (n_l,n_r), the candidate's likelihood ratio relative to uniformity is proportional to

$$
\frac{B(\tau L+n_l,\tau(1-L)+n_r)}{B(\tau L,\tau(1-L))}
L^{-n_l}(1-L)^{-n_r}.
$$

The code samples stop versus split, and then samples a split rule from normalized posterior weights. This is a one-particle stochastic top-down procedure, not an MCMC chain and not a posterior sampler for the final ensemble measure.

### 8.4 Structural stopping rules

**confirmed from the original code**

A node is not split when its observation count is below `min_obs`. A dimension is suppressed for the node when its width is below (10^{-10}).

The code checks `depth > max_resol` before forcing a stop. Consequently, a node at depth `max_resol` can still split and create leaves at depth `max_resol + 1`.

**unresolved**

Whether this depth convention is intended by the paper's phrase “maximum resolution”. It requires a characterization test before modification.

### 8.5 Variable restriction within a tree

**confirmed from the original code**

`max_n_var` limits the number of distinct selected dimensions within one tree. Once that many dimensions have appeared, other dimensions are deactivated for the remainder of that tree. The experiment scripts describe this as experimental and set it to (d), which removes the restriction.

The paper does not specify this restriction as part of the method.

**approved package decision, 2026-07-14**

The experimental `max_n_var` restriction is removed from the package
implementation. The archived implementation and experiment settings remain
recorded here for provenance.

## 9. Scale-specific shrinkage

### 9.1 Node-specific learning rate

**confirmed from the paper and original code**

For node volume (\operatorname{vol}(A)), define

$$
c(A)=c_0\left(1-\log_2\operatorname{vol}(A)\right)^{-\gamma}.
$$

The final left-child mass added to the ensemble is

$$
q_A=(1-c(A))L_A+c(A)\frac{n_l}{n_l+n_r}.
$$

Thus the fitted mass is a shrinkage estimate toward the uniform mass (L_A), not the beta posterior mean used for selecting the tree.

### 9.2 Parameter interpretation

- (c_0\in(0,1]): global learning rate.
- (\gamma\ge0): stronger shrinkage on small-volume nodes when positive.
- (\gamma=0): one global learning rate.

The paper recommends cross-validation for (c_0) and (\gamma), and discusses (c_0=0.1) or (0.01) as practical values.

**possible numerical issue**

The original R interface does not enforce these ranges. If (c(A)) leaves ((0,1]), or if (c(A)=1) with an empty child, (q_A) can reach or leave the interval ([0,1]), causing singular log-density or inverse-transform calculations.

**approved package decision, 2026-07-14**

The package requires `0 < c0 < 1` and `gamma >= 0`.

## 10. Two-stage marginal and dependence fit

**confirmed from the paper and original code**

The implementation uses this ordered strategy:

1. For (j=1,\ldots,d), fit up to `ntree_max_marginal` trees restricted to dimension (j).
2. Treat the resulting residuals as an empirical copula with approximately uniform margins.
3. Fit up to `ntree_max_dependence` unrestricted dependence trees.

The final ensemble is the ordered composition of all marginal trees followed by dependence trees.

Setting `ntree_max_marginal = 0` skips marginal fitting and produces a one-stage joint fit.

## 11. Treatment of ties

### 11.1 Paper rule

**confirmed from the paper**

When ties at (x) are believed to result from rounding in an otherwise continuous distribution, the paper recommends uniform perturbation bounded by half the gaps to adjacent unique values.

### 11.2 Code rule

**confirmed from the original code**

For an interior tied value (x), with adjacent unique values (x_-) and (x_+), the code draws

$$
\varepsilon\sim\mathrm{Unif}\left(-\frac{x-x_-}{2},\frac{x_+-x}{2}\right)
$$

and replaces the tied values by (x+\varepsilon). At the minimum or maximum unique value, it uses half of the only adjacent gap on both sides.

Jitter is stochastic and changes the number and order of RNG draws.

**possible bug**

A constant column has no adjacent unique value. The current code can generate `NA` during jitter and also creates a zero-width automatic support.

## 12. Adaptive stopping

### 12.1 Paper strategy

**confirmed from the paper**

- Fit each new tree on 90% of the current residuals.
- Evaluate its average log density on the held-out 10%.
- Stop a stage when the mean improvement over the most recent 50 trees is non-positive.

### 12.2 Code strategy

**confirmed from the original code**

If `early_stop` is `NULL`:

- all observations are used for fitting;
- no substantive early stopping is applied.

If `early_stop = c(threshold, wait)`:

- the fitting fraction is fixed internally at 0.9;
- the remaining observations evaluate the new tree;
- a stage stops when the mean of the most recent `wait` held-out tree log densities is below `threshold`;
- the rejected tree is neither stored nor applied to the residuals;
- its evaluation is retained in `improvement_curve`.

The window is initialized with large constants, so it cannot trigger normally until those values have been replaced.

**possible bug**

`wait <= 1` and very small (n) can create invalid or empty Armadillo ranges. No boundary validation exists.

## 13. Density evaluation

### 13.1 Unit-cube density

**confirmed from the paper and original code**

For (r^{(k-1)}=\mathbf G_{k-1}\circ\cdots\circ\mathbf G_1(x)),

$$
f(x)=\prod_{k=1}^K g_k(r^{(k-1)}),
$$

or

$$
\log f(x)=\sum_{k=1}^K\log g_k(r^{(k-1)}).
$$

The code evaluates a tree's log density along the branch containing the current residual, then residualizes the point before evaluating the next tree.

### 13.2 Original-scale Jacobian

For support bounds (m_j<M_j), define

$$
z_j=\frac{x_j-m_j}{M_j-m_j}.
$$

The returned original-scale log density is

$$
\log f_X(x)=\log f_Z(z)-\sum_{j=1}^d\log(M_j-m_j).
$$

### 13.3 Support behavior

**confirmed from the paper**

The density target is defined on the declared support.

**possible bug in the original code**

`eval_density_b()` does not check whether evaluation points lie inside `Omega`. It can return finite density values outside the declared support. The intended value is inferred to be zero density, or log density (-\infty), but this requires explicit project confirmation before implementation.

## 14. Simulation from the fitted measure

**confirmed from the paper and original code**

Draw

$$
U\sim\mathrm{Unif}((0,1]^d)
$$

and compute

$$
X=\mathbf G_1^{-1}\circ\cdots\circ\mathbf G_K^{-1}(U).
$$

The code traverses stored trees from (K) down to 1, which applies the inverse maps in the correct composition order, then maps the result from the unit cube to `Omega`.

For a local inverse, the branch threshold is (a_j+q_A(b_j-a_j)). The inverse expands or contracts the two output intervals by (L_A/q_A) and ((1-L_A)/(1-q_A)), respectively.

## 15. Variable importance

**confirmed from the paper and original code**

For a node (A) split in dimension (j), the empirical contribution is

$$
\frac{n_l}{n}\log\frac{q_A}{L_A}
+\frac{n_r}{n}\log\frac{1-q_A}{1-L_A}.
$$

The importance for dimension (j) is the sum of these terms over all nodes split in (j) and all fitted trees. The code includes marginal-stage and dependence-stage trees.

**unresolved**

With adaptive stopping, the tree is fitted to a 90% subsample but the code divides node counts by the full (n). This scales the contribution relative to the paper's full-empirical-measure formula. Whether this is intended remains unresolved.

## 16. Support construction and preprocessing

### 16.1 User-supplied support

**confirmed from the original code**

`Omega` is expected to be a (d\times2) matrix. Every original observation must lie strictly between its lower and upper bound. Equality to a boundary is rejected.

The code does not otherwise validate shape, finiteness, or positive widths.

### 16.2 Automatic support

For dimension (j), after optional jitter, the code sets

$$
m_j=\min_i x_{ij}-0.1\left(\max_i x_{ij}-\min_i x_{ij}\right),
$$

$$
M_j=\max_i x_{ij}+0.1\left(\max_i x_{ij}-\min_i x_{ij}\right).
$$

This is an implementation convention, not a rule specified in the paper.

**possible bug**

For user-supplied `Omega`, membership is checked on the original data rather than the jittered data. Jitter can therefore move a value outside `Omega` after the check.

## 17. Boundary conventions

**confirmed from the paper**

The mathematical partition uses left-open, right-closed rectangles, and a split point belongs to the left child.

**confirmed from the original code**

- Training allocation uses `< partition_point` for the left child and assigns equality to the right child.
- Density evaluation and residualization use `<= partition_point` and assign equality to the left child.
- Inverse simulation uses `< transformed_threshold` for the left branch.

**possible bug**

The equality convention is inconsistent between fitting and later transforms. This is probability-zero under an ideal continuous distribution but can matter for rounded data, deterministic evaluation grids, and floating-point boundary values.

**approved package decision, 2026-07-14**

The package assigns equality to the left child in fitting, density evaluation,
residualization, and inverse simulation, following the paper. The archived mixed
convention remains covered by the separate characterization suite.

## 18. Public R parameters and archived defaults

| Argument | Archived default | Implemented meaning |
|---|---:|---|
| `add_noise` | `TRUE` | Jitter tied values before fitting |
| `Omega` | `NULL` | Automatic rectangular support when absent |
| `ntree_max_marginal` | `100` | Maximum marginal trees per dimension |
| `ntree_max_dependence` | `1000` | Maximum dependence trees |
| `c0` | `0.1` | Global learning rate |
| `gamma` | `0.1` | Scale-specific shrinkage exponent |
| `max_resol` | `15` | Code permits splits through this depth |
| `min_obs` | `5` | Stop when node count is below this value |
| `early_stop` | `NULL` | No adaptive stopping when absent |
| `alpha` | `0.9` | Depth-zero split probability |
| `beta` | `0.0` | Depth decay exponent in split probability |
| `precision` | `1.0` | Beta-prior precision used for tree selection |
| `nbins` | `8` | Produces 7 candidate split fractions |
| `max_n_var` | `100` | Maximum distinct variables per tree; experimental |

These are archived software defaults. They are not all the settings reported in the final paper.

The package retains these defaults except that `max_n_var` has been removed.
It validates `0 < c0 < 1`, `gamma >= 0`, `0 <= alpha <= 1`, `beta >= 0`, and
`precision > 0`. `max_resol` retains the archived interpretation as the deepest
splittable node, so leaves may occur at `max_resol + 1`.

## 19. Paper and experiment settings

### 19.1 Paper recommendations and general experiment settings

**confirmed from the paper**

- Two-stage fitting is generally used.
- Adaptive stopping generally uses a 90/10 split and a 50-tree non-positive-improvement rule.
- Maximum marginal trees: 100 per dimension unless otherwise stated.
- Maximum dependence trees: 5000 unless otherwise stated.
- Practical global learning rates include 0.1 and 0.01.
- (\gamma) is intended for cross-validation; experiments include 0 and 0.5.

### 19.2 Public experiment script settings

**confirmed from the experiment code**

The density-estimation script uses or documents:

- `set.seed(1)`; seeds 1 through 30 for the Section 3.1 repetitions
- `ntree_max_marginal = 1000`
- `ntree_max_dependence = 5000`
- `c0 = 0.1`
- `gamma = 0.5`
- `max_resol = 15`, or 50 for Section 3.2
- `min_obs = 10`
- `early_stop = c(0, 50)`
- `nbins = 100`, giving 99 code-level candidates
- `max_n_var = d`
- `alpha = 0.9`
- `beta = 0`
- `precision = 1`

The script is not a locked execution environment and writes no result hashes.

## 20. Source conflicts

| Topic | Paper | Original or experiment code | Status |
|---|---|---|---|
| Stop prior | Appendix C states `P(stop) = 0.5` | Code and experiment scripts use `alpha = 0.9`, hence depth-zero `P(stop) = 0.1` | unresolved methodological/numerical-setting conflict |
| Split grid | Appendix C states 127 grid points | Experiment script uses `nbins = 100`, which creates 99 candidates | unresolved setting conflict |
| Marginal tree cap | Main paper states 100 per dimension | Public experiment script sets 1000 | unresolved reproduction-setting conflict |
| Split-depth prior | Appendix C gives constant stopping probability | Code generalizes to `alpha * (depth + 1)^(-beta)` | confirmed code extension; paper mapping incomplete |
| Prior comment | Paper appendix does not use this comment | R comments show a positive `beta` exponent; C++ uses a negative exponent | documentation error in original code |
| Maximum depth | “maximum resolution” | Code can create leaves at `max_resol + 1` | unresolved convention / possible bug |
| Split-point equality | Left child in the paper | Training sends equality right; evaluation sends equality left | possible bug |
| Adaptive variable importance | Full empirical-measure formula | Subsample counts divided by full sample size | unresolved scaling difference |
| Software citation | Final JMLR article and MaStatLab URL | README and Rd cite older arXiv years/titles | documentation drift |

The conflicts above must not be silently resolved. Characterization tests and, where necessary, author confirmation are required.

## 21. Missing values, invalid inputs, and zero probabilities

### 21.1 Missing and non-finite values

The paper does not define missing-value handling. The original code does not validate or impute missing or infinite values.

Project interpretation: missing and non-finite inputs are unsupported unless a future user instruction changes the model. The new R interface should reject them before C++.

### 21.2 Zero counts and empty children

Zero child counts are allowed by the node likelihood. Shrinkage with (c(A)<1) keeps (q_A) inside ((0,1)) when (L_A\in(0,1)). With (c(A)=1), an empty child produces (q_A=0) or 1 and breaks the full-support assumption.

### 21.3 Empty data and degenerate dimensions

The method is not specified for empty data, zero variables, or constant-support
dimensions. The package rejects all three cases. It also checks that jittered
observations remain strictly inside a user-supplied `Omega`.

### 21.4 Evaluation outside the support

**approved package decision, 2026-07-14**

Evaluation points outside `Omega` receive log density (-\infty). If an outside
point is included while computing the cumulative mean log-density path, every
non-empty path entry is likewise (-\infty).

## 22. Output representation

**confirmed from the original code**

The archived fit is an unclassed R list. The package preserves its contents and
adds S3 class `boostPM_fit`. Components include:

- `residuals_boosting`: final residual matrix with shape (d\times n)
- `tree_size_store`: number of nodes per accepted tree
- `max_depth_store`: maximum node depth per accepted tree
- `variable_importance`: length-(d) importance vector
- `tree_list`: serialized accepted trees
- `improvement_curve`: present only when adaptive stopping is active
- `Omega`: original-scale support
- `time`: elapsed fitting time

Each serialized tree stores preorder vectors:

- `d`: split dimension, or `-1` for a leaf
- `l`: geometric split fraction, or `-1` for a leaf
- `theta`: shrunk left-child mass (q_A), or `-1` for a leaf

The tree list and its order are part of the numerical model and must be preserved when introducing a future S3 class.

## 23. Random-number generation and reproducibility

**confirmed from the original code**

Randomness enters through:

- tie jitter
- observation permutations and 90% subsamples
- stochastic stop/split choices
- stochastic split-rule choices
- simulation from the fitted model

R and Rcpp random functions are used for most draws. Armadillo `randperm()` is used for permutations.

**unresolved**

- Exact fixed-seed reproducibility across RcppArmadillo versions.
- Exact cross-platform reproducibility.
- Exact correspondence to the runtime used for paper results.

Current supported claim: none yet. Characterization tests must separately establish exact, numerical, or inferential reproducibility.

Elapsed time is inherently non-reproducible and should not be included in equality comparisons of statistical results.

## 24. Computational complexity

**confirmed from the paper**

For fitted trees of depth at most (R), density evaluation and sampling are described as (O(RK)) per point in the worst case.

**inferred from the original code**

Training cost also depends on repeated node counts across active dimensions, split candidates, observations, and accepted trees. No validated complexity constant or benchmark exists. Profiling is required before optimization.

## 25. Statistical invariants for the new package

Unless the user explicitly approves a methodological change, the new implementation must preserve:

1. Ordered tree-CDF composition as the definition of addition.
2. Fine-to-coarse residualization within each tree.
3. Reverse-order inverse transforms for simulation.
4. The product/sum decomposition of density/log density.
5. The stochastic top-down tree-selection probabilities implemented in the archived code, including chosen defaults until conflicts are resolved.
6. Scale-specific shrinkage and its node-volume definition.
7. The two-stage marginal-then-dependence ordering.
8. The meaning and accumulation rule of variable importance.
9. Support normalization and Jacobian correction.
10. The order and number of random draws when exact reproducibility is the target.
11. Tree serialization order and accepted-tree ordering.

Input validation, clearer errors, structured classes, quiet output, portable headers, and memory-safety improvements may be added if they do not alter these statistical quantities.

## 26. Required characterization tests before core changes

Current characterization status:

1. [x] One local move and its inverse for left and right branches.
2. [x] One-tree density factors against hand calculations.
3. [x] Two-tree residual composition order.
4. [x] Fixed-seed fitting for a small univariate sample.
5. [x] Fixed-seed fitting for a small two-dimensional sample.
6. [x] Marginal-stage followed by dependence-stage tree ordering.
7. [x] Variable-importance contribution for a hand-calculated split.
8. [x] Automatic support normalization and Jacobian correction.
9. [x] Tie jitter with interior and endpoint ties.
10. [x] Exact split-point equality behavior.
11. [x] `max_resol` maximum resulting depth.
12. [x] Adaptive stopping and rejected-tree behavior.
13. [x] Density evaluation outside `Omega`.
14. [x] Non-finite input, empty/small samples, constant columns, invalid controls,
    and jitter escaping a supplied support.
15. [x] Original-versus-package density and simulation comparisons for retained
    interior behavior. Approved boundary differences are tested separately.

Results and reproducibility levels are recorded in `docs/numerical-validation.md`.

## 27. Open decisions

The following require user or author confirmation before changing behavior:

- Whether the paper's `P(stop)=0.5` or the released code's `alpha=0.9` is the intended published setting.
- Whether the intended split grid has 127, 99, or another number of candidate points.
- Whether the Section 3 marginal-tree cap is 100 or 1000.
- Whether adaptive-stopping variable importance should be normalized by full or training-subsample size.
