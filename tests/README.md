# Package tests

This directory contains the routine testthat suite for the new package.
The tests preserve the archived numerical fixtures and known boundary behavior.
The R-wrapper tests also fix preprocessing, control forwarding, low-level
argument order, and post-processing delegation after refactoring.

The immutable original implementation has a separate standalone suite under
`validation/characterization/`. That suite is excluded from the CRAN source
package because it compiles and installs a second package copy.

Additional non-CRAN validation lives under `validation/regression/` and
`validation/statistical/`. The first compares original and package outputs in
separate R processes; the second follows the paper's predictive-score criterion
on reproducible simulated data.
