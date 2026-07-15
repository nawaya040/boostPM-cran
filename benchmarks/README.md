# Performance benchmarks

These scripts are development tools and are excluded from the source package.

## Isolated binning benchmark

```text
Rscript benchmarks/run-binning-benchmark.R output.csv
```

This compiles `binning-kernels.cpp` outside the package and compares the
archived floor-index kernel, the previous equality-left `lower_bound` kernel,
and the current equality-left arithmetic kernel. Compilation is excluded from
timing. Continuous interior inputs must agree across all kernels. Exact grid
boundaries must also agree between the two equality-left kernels.

## End-to-end fitting benchmark

```text
Rscript benchmarks/run-fit-benchmark.R output.csv
```

The runner copies and installs `original/` and the current package into separate
temporary libraries. It also creates a temporary copy of the current package in
which only the marked binning block is replaced by either the archived floor
kernel or the previous `lower_bound` kernel. The four implementations run in
separate R processes.
Install and compilation time are excluded. Every case has one unmeasured warm-up
fit followed by ten measured timing batches. Each batch repeats 10--50 fits and
reports elapsed time per fit, reducing clock-resolution noise. The same data and
fit seeds are used for all three implementations, and compact numerical checksums
must agree. Current-versus-temporary-floor and current-versus-`lower_bound`
ratios isolate the binning changes; current-versus-original records end-to-end
package evolution.

A working package compiler toolchain, Rcpp, and RcppArmadillo are required.

Recorded summaries from the 2026-07-14 Windows run are under
`benchmarks/results/`. Raw timing batches are intentionally regenerated rather
than committed.
