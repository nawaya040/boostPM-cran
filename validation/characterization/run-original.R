#!/usr/bin/env Rscript

# Standalone characterization-test runner for the immutable package archive.
# The project root is not yet an R package, so this runner installs a temporary
# copy of original/ and then executes validation/characterization/testthat/.

local({
  if (!requireNamespace("testthat", quietly = TRUE)) {
    stop("Package 'testthat' is required to run the characterization tests.")
  }

  root <- Sys.getenv("BOOSTPM_PROJECT_ROOT", unset = getwd())
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)

  if (!file.exists(file.path(root, "AGENTS.md")) ||
      !dir.exists(file.path(root, "original"))) {
    stop(
      "Run tests/testthat.R from the project root, or set ",
      "BOOSTPM_PROJECT_ROOT to that directory."
    )
  }

  required <- c("Rcpp", "RcppArmadillo")
  missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) > 0L) {
    stop("Missing required package(s): ", paste(missing, collapse = ", "))
  }

  read_git_head <- function(repository) {
    git_dir <- file.path(repository, ".git")
    head_file <- file.path(git_dir, "HEAD")
    if (!file.exists(head_file)) {
      return(NA_character_)
    }

    head <- trimws(readLines(head_file, n = 1L, warn = FALSE))
    if (!startsWith(head, "ref: ")) {
      return(head)
    }

    reference <- substring(head, 6L)
    loose_reference <- file.path(git_dir, reference)
    if (file.exists(loose_reference)) {
      return(trimws(readLines(loose_reference, n = 1L, warn = FALSE)))
    }

    packed_file <- file.path(git_dir, "packed-refs")
    if (!file.exists(packed_file)) {
      return(NA_character_)
    }
    packed <- readLines(packed_file, warn = FALSE)
    match <- grep(paste0(" ", reference, "$"), packed, value = TRUE)
    if (length(match) != 1L) {
      return(NA_character_)
    }
    sub(" .*", "", match)
  }

  archived_commit <- read_git_head(file.path(root, "original"))

  copy_archive <- function(from, to) {
    dir.create(to, recursive = TRUE, showWarnings = FALSE)

    entries <- list.files(
      from,
      all.files = TRUE,
      full.names = FALSE,
      recursive = TRUE,
      include.dirs = TRUE,
      no.. = TRUE
    )
    normalized <- gsub("\\\\", "/", entries)
    entries <- entries[!grepl("^\\.git(?:/|$)", normalized)]

    for (entry in entries) {
      source <- file.path(from, entry)
      target <- file.path(to, entry)

      if (dir.exists(source)) {
        dir.create(target, recursive = TRUE, showWarnings = FALSE)
      } else {
        dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
        if (!file.copy(source, target, overwrite = TRUE, copy.date = TRUE)) {
          stop("Failed to copy archived file: ", source)
        }
      }
    }
  }

  work <- tempfile("boostPM-characterization-")
  source_copy <- file.path(work, "boostPM")
  library_path <- file.path(work, "library")
  dir.create(library_path, recursive = TRUE)
  on.exit(unlink(work, recursive = TRUE, force = TRUE), add = TRUE)

  copy_archive(file.path(root, "original"), source_copy)

  r_binary <- file.path(R.home("bin"), "R")
  install_args <- c(
    "CMD", "INSTALL",
    shQuote(source_copy),
    shQuote(paste0("--library=", library_path)),
    "--preclean", "--clean"
  )
  install_output <- system2(
    r_binary,
    install_args,
    stdout = TRUE,
    stderr = TRUE
  )
  install_status <- attr(install_output, "status")
  if (is.null(install_status)) {
    install_status <- 0L
  }
  if (install_status != 0L) {
    cat(paste(install_output, collapse = "\n"), "\n", file = stderr())
    stop("Temporary installation of original/ failed with status ", install_status)
  }

  .libPaths(c(library_path, .libPaths()))
  library("boostPM", character.only = TRUE, lib.loc = library_path)

  Sys.setenv(
    BOOSTPM_PROJECT_ROOT = root,
    BOOSTPM_EXPECTED_ORIGINAL_COMMIT = "1732dba73d3788c9c457f958c4e5699f12ff3bab",
    BOOSTPM_ACTUAL_ORIGINAL_COMMIT = archived_commit
  )

  testthat::test_dir(
    file.path(root, "validation", "characterization", "testthat"),
    reporter = "summary",
    stop_on_failure = TRUE,
    stop_on_warning = TRUE
  )
})

