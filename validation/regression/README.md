# Original-versus-package regression validation

Run from the project root:

```text
Rscript --vanilla validation/regression/run-original-vs-package.R
```

The runner installs copied versions of `original/` and the current package into
separate temporary libraries. It compares valid, strictly interior fixed-seed
fixtures in separate R processes, avoiding namespace conflicts. It checks fitted
objects excluding timing and class metadata, density evaluation, simulation, and
the final R random-number state with `identical()`.

This runner establishes exact reproducibility only for its documented fixtures.
It does not compare intentionally changed boundary behavior, malformed inputs,
or the removed `max_n_var` feature.
