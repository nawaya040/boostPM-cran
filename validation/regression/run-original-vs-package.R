#!/usr/bin/env Rscript

# Compare valid interior fixed-seed fixtures in separate R processes because the
# archived and current packages share the package name.
local({
  root <- normalizePath(
    Sys.getenv("BOOSTPM_PROJECT_ROOT", unset = getwd()),
    winslash = "/",
    mustWork = TRUE
  )
  if (!file.exists(file.path(root, "AGENTS.md")) ||
      !dir.exists(file.path(root, "original"))) {
    stop("Run this script from the project root.")
  }

  copy_source <- function(from, to, excluded_top_level = character()) {
    dir.create(to, recursive = TRUE, showWarnings = FALSE)
    entries <- list.files(
      from, all.files = TRUE, recursive = TRUE, full.names = FALSE,
      include.dirs = TRUE, no.. = TRUE
    )
    normalized <- gsub("\\\\", "/", entries)
    keep <- !vapply(normalized, function(path) {
      top <- strsplit(path, "/", fixed = TRUE)[[1L]][[1L]]
      top %in% excluded_top_level || grepl("\\.Rcheck$", top) ||
        grepl("^boostPM_.*\\.tar\\.gz$", top)
    }, logical(1))

    for (entry in entries[keep]) {
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

  install_one <- function(source, library_path) {
    output <- system2(
      file.path(R.home("bin"), "R"),
      c("CMD", "INSTALL", "--preclean", "--clean",
        shQuote(paste0("--library=", library_path)), shQuote(source)),
      stdout = TRUE,
      stderr = TRUE
    )
    status <- attr(output, "status")
    if (!is.null(status) && status != 0L) {
      stop(paste(output, collapse = "\n"))
    }
  }

  work <- tempfile("boostpm-regression-")
  on.exit(unlink(work, recursive = TRUE, force = TRUE), add = TRUE)
  current_source <- file.path(work, "current-source")
  original_source <- file.path(work, "original-source")
  current_library <- file.path(work, "current-library")
  original_library <- file.path(work, "original-library")
  dir.create(current_library, recursive = TRUE)
  dir.create(original_library, recursive = TRUE)

  copy_source(
    root,
    current_source,
    excluded_top_level = c(
      ".agents", ".codex", ".git", ".sandbox", ".github", "benchmarks",
      "docs", "original", "validation"
    )
  )
  copy_source(file.path(root, "original"), original_source, ".git")
  install_one(current_source, current_library)
  install_one(original_source, original_library)

  worker <- file.path(root, "validation", "regression", "fit-worker.R")
  run_worker <- function(library_path, implementation) {
    output <- tempfile(fileext = ".rds")
    result <- system2(
      file.path(R.home("bin"), "Rscript"),
      c(shQuote(worker), shQuote(library_path), implementation, shQuote(output)),
      stdout = TRUE,
      stderr = TRUE
    )
    status <- attr(result, "status")
    if (!is.null(status) && status != 0L) {
      stop(paste(result, collapse = "\n"))
    }
    readRDS(output)
  }

  original <- run_worker(original_library, "original")
  current <- run_worker(current_library, "package")
  fixture_names <- names(original)
  if (!identical(fixture_names, names(current))) {
    stop("Fixture names differ between implementations.")
  }

  for (fixture in fixture_names) {
    for (component in names(original[[fixture]])) {
      reference <- original[[fixture]][[component]]
      candidate <- current[[fixture]][[component]]
      if (!identical(reference, candidate)) {
        difference <- all.equal(reference, candidate, check.attributes = TRUE)
        stop(
          "Exact reproducibility failed for ", fixture, "/", component,
          ": ", paste(difference, collapse = "; ")
        )
      }
    }
  }

  cat("ORIGINAL_VS_PACKAGE\n")
  cat("fixtures:", paste(fixture_names, collapse = ", "), "\n")
  cat("level: exact reproducibility for valid interior fixed-seed fixtures\n")
  cat("result: all fitted objects, density evaluations, simulations, and RNG states matched\n")
})
