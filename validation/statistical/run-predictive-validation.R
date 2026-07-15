#!/usr/bin/env Rscript

# This is intentionally outside routine CRAN tests. It follows the paper's
# predictive-score evaluation and adds probability-measure consistency checks.
local({
  root <- normalizePath(
    Sys.getenv("BOOSTPM_PROJECT_ROOT", unset = getwd()),
    winslash = "/",
    mustWork = TRUE
  )
  if (!file.exists(file.path(root, "DESCRIPTION"))) {
    stop("Run this script from the package project root.")
  }

  copy_source <- function(from, to) {
    dir.create(to, recursive = TRUE, showWarnings = FALSE)
    entries <- list.files(
      from, all.files = TRUE, recursive = TRUE, full.names = FALSE,
      include.dirs = TRUE, no.. = TRUE
    )
    normalized <- gsub("\\\\", "/", entries)
    entries <- entries[!vapply(normalized, function(path) {
      top <- strsplit(path, "/", fixed = TRUE)[[1L]][[1L]]
      top %in% c(".agents", ".codex", ".git", ".sandbox", ".github",
                 "benchmarks", "docs", "original", "validation") ||
        grepl("\\.Rcheck$", top) || grepl("^boostPM_.*\\.tar\\.gz$", top)
    }, logical(1))]
    for (entry in entries) {
      source <- file.path(from, entry)
      target <- file.path(to, entry)
      if (dir.exists(source)) {
        dir.create(target, recursive = TRUE, showWarnings = FALSE)
      } else {
        dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
        if (!file.copy(source, target, overwrite = TRUE, copy.mode = TRUE)) {
          stop("Failed to copy: ", source)
        }
      }
    }
  }

  work <- tempfile("boostpm-statistical-")
  on.exit(unlink(work, recursive = TRUE, force = TRUE), add = TRUE)
  source_copy <- file.path(work, "source")
  library_path <- file.path(work, "library")
  dir.create(library_path, recursive = TRUE)
  copy_source(root, source_copy)

  install_output <- system2(
    file.path(R.home("bin"), "R"),
    c("CMD", "INSTALL", "--preclean", "--clean",
      shQuote(paste0("--library=", library_path)), shQuote(source_copy)),
    stdout = TRUE,
    stderr = TRUE
  )
  install_status <- attr(install_output, "status")
  if (!is.null(install_status) && install_status != 0L) {
    stop(paste(install_output, collapse = "\n"))
  }

  output <- file.path(work, "predictive-validation.csv")
  worker <- file.path(root, "validation", "statistical", "fit-worker.R")
  worker_output <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(shQuote(worker), shQuote(library_path), shQuote(output)),
    stdout = TRUE,
    stderr = TRUE
  )
  worker_status <- attr(worker_output, "status")
  if (!is.null(worker_status) && worker_status != 0L) {
    stop(paste(worker_output, collapse = "\n"))
  }

  result <- utils::read.csv(output, stringsAsFactors = FALSE)
  summary <- stats::aggregate(
    result[c("train_predictive_score", "test_predictive_score",
             "monte_carlo_integral", "simulated_mean_l1_error")],
    result["scenario"],
    mean
  )
  cat("PREDICTIVE_VALIDATION\n")
  print(summary, row.names = FALSE)
  cat("checks: finite interior densities; Monte Carlo integral within 0.20 of one; simulated values inside support\n")
})
