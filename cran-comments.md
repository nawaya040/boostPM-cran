## Test environments

* Local Windows 11 x64, R 4.5.2, `R CMD check --as-cran`.
* GitHub Actions, Windows, R-release, `R CMD check --as-cran`.
* GitHub Actions, macOS, R-release, `R CMD check --as-cran`.
* GitHub Actions, Ubuntu, R-release, R-devel, and R-oldrel-1,
  `R CMD check --as-cran`.

## R CMD check results

0 errors | 0 warnings | 3 notes

* This is a new submission.
* The local check environment was unable to verify the current time.
* The local HTML-manual check skipped math-rendering verification because the
  optional V8 package was unavailable. The HTML and PDF manuals were generated
  successfully.

All five GitHub Actions jobs completed successfully. The local check also
completed all examples, tests, vignette rebuilding, and manual generation.
