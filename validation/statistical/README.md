# Statistical validation

Run from the project root:

```text
Rscript --vanilla validation/statistical/run-predictive-validation.R
```

The validation follows the paper's Section 3 criterion: held-out average
log-density, called the predictive score. It evaluates uniform, beta, and
Gaussian-copula data on the unit support using three fixed data seeds.

For every fitted object it also checks finite interior densities, Monte Carlo
normalization within 0.20 of one, and simulated values inside the declared
support. The simulated mean error is reported as a diagnostic, not a pass/fail
criterion. The script is intentionally excluded from CRAN checks.
