# Performance notes

Current equality-aware binning derives a provisional bin from the uniform grid
in constant time, then verifies it against adjacent candidate points. The
current optimization and its preceding binary-search baseline are recorded
below.

## 2026-07-14 constant-time uniform-grid optimization

The current arithmetic kernel, the preceding `lower_bound` kernel, and the
archived floor kernel were compiled under the environment recorded below.
All kernels agreed on continuous interior inputs. The two equality-left kernels
also agreed on every exact candidate boundary and both endpoints.

### Isolated kernel result

Each cell reports the median time per call over 15 timing repetitions.

| n | nbins | arithmetic (ms) | lower_bound (ms) | arithmetic/lower_bound | arithmetic/floor |
|---:|---:|---:|---:|---:|---:|
| 1,000 | 8 | 0.0184 | 0.00921 | 2.00 | 2.30 |
| 1,000 | 100 | 0.0144 | 0.0123 | 1.17 | 2.16 |
| 10,000 | 8 | 0.176 | 0.229 | 0.77 | 2.93 |
| 10,000 | 100 | 0.144 | 0.446 | 0.32 | 3.59 |
| 100,000 | 8 | 1.875 | 2.540 | 0.74 | 3.13 |
| 100,000 | 100 | 1.270 | 4.800 | 0.26 | 2.54 |

For 10,000 or more values, arithmetic lookup was 23% to 74% faster than
binary search. At 1,000 values, fixed call and validation costs dominate this
microbenchmark, and the arithmetic kernel was slower. The full fitting result
below is the more relevant package-level comparison.

### End-to-end fitting result

Four independently installed builds used common data, fitting seeds, and 10
measured batches after warm-up. Every batch repeated 10--50 fits. Compact
numerical checksums agreed across the current arithmetic build, temporary
`lower_bound` and floor builds, and `original/`.

| case | arithmetic (s) | lower_bound (s) | floor (s) | arithmetic/lower_bound | arithmetic/floor |
|---|---:|---:|---:|---:|---:|
| n=1,000, d=2, nbins=8 | 0.00330 | 0.00360 | 0.00290 | 0.92 | 1.14 |
| n=5,000, d=2, nbins=8 | 0.01475 | 0.01600 | 0.01275 | 0.92 | 1.16 |
| n=5,000, d=2, nbins=100 | 0.03300 | 0.04950 | 0.02950 | 0.67 | 1.12 |
| n=2,000, d=5, nbins=100 | 0.03100 | 0.04500 | 0.02750 | 0.69 | 1.13 |

The optimization reduced full-fit time by about 8% for `nbins = 8` and by
31%--33% for `nbins = 100` relative to `lower_bound`. Boundary validation and
left-equality correction retain a 12%--16% cost relative to the unsafe floor
kernel in these cases.

### Reproduction

- `benchmarks/run-binning-benchmark.R`
- `benchmarks/run-fit-benchmark.R`
- `benchmarks/fit-worker.R`
- `benchmarks/binning-kernels.cpp`

The scripts require a working compiler. They do not modify `original/` and run
package variants in temporary libraries.

## 2026-07-14 boundary-safe `lower_bound` baseline

### Environment

- CPU: Intel Xeon w5-3423, 24 logical processors reported by Windows.
- OS: Windows 11 x64, build 26200.
- R: 4.5.2, x86_64-w64-mingw32.
- Compiler: GCC 14.3.0, GNU++17, package optimization flags from R 4.5.2.
- Rcpp: 1.1.1.1.
- RcppArmadillo: 14.4.1.1.
- Execution: sequential; compilation, installation, and warm-up excluded.
- Memory allocation: not measured. The base-R timer does not capture native C++
  allocations reliably, so no memory claim is made.
- Pure-R fit: not benchmarked because no behavior-equivalent pure-R fitting
  implementation exists in this repository.

### Isolated kernel result

Each cell reports the median time per call and the new-to-old ratio over 15
timing repetitions. Both kernels returned identical cumulative counts on the
continuous interior inputs.

| n | nbins | floor median (ms) | lower_bound median (ms) | ratio |
|---:|---:|---:|---:|---:|
| 1,000 | 8 | 0.00818 | 0.00921 | 1.13 |
| 1,000 | 100 | 0.00600 | 0.01280 | 2.13 |
| 10,000 | 8 | 0.0600 | 0.229 | 3.82 |
| 10,000 | 100 | 0.0490 | 0.500 | 10.20 |
| 100,000 | 8 | 0.547 | 2.750 | 5.03 |
| 100,000 | 100 | 0.400 | 5.000 | 12.50 |

The ratio increases with `n` and `nbins`, as expected when replacing constant-
time arithmetic indexing with binary search. Small-case ratios include a larger
share of R-to-C++ call overhead.

### End-to-end fitting result

The isolated package comparison uses three builds:

- `current`: boundary-safe `lower_bound` implementation;
- `current_floor`: a temporary copy of the same current source with only the
  marked binning block replaced by the archived floor kernel;
- `original`: an independently copied and installed archive.

Every case has one unmeasured warm-up, followed by 10 timing batches. Each batch
contains 10--50 fits and reports seconds per fit. Data and fit seeds are shared.
All compact numerical checksums agreed across all three builds.

| case | current (s) | current_floor (s) | current/floor | current/original |
|---|---:|---:|---:|---:|
| n=1,000, d=2, nbins=8 | 0.00340 | 0.00280 | 1.21 | 1.26 |
| n=5,000, d=2, nbins=8 | 0.01550 | 0.01225 | 1.27 | 1.41 |
| n=5,000, d=2, nbins=100 | 0.04700 | 0.02700 | 1.74 | 1.81 |
| n=2,000, d=5, nbins=100 | 0.04200 | 0.02650 | 1.58 | 0.75 |

The isolated end-to-end cost of boundary-safe binning is therefore about 21% to
74% in these cases. The larger penalties occur at `nbins = 100`. Comparison
with `original` is mixed because it includes all intervening package changes;
it should not be interpreted as the isolated binning cost.

## 2026-07-14 portability and safety change

No performance optimization was attempted. OpenMP flags were removed because
the source contains no OpenMP region. Scope-based cleanup and interrupt checks
may add negligible control overhead; no speed claim is made.

Reproducible profiling and benchmarks remain the next performance phase.
