# Archived implementation characterization

This suite records behavior of `original/` at commit
`1732dba73d3788c9c457f958c4e5699f12ff3bab`.

Run from the project root:

```text
Rscript --vanilla validation/characterization/run-original.R
```

The runner copies and installs the archive in a temporary directory. It does
not modify `original/`. This suite is intentionally separate from routine CRAN
checks.
