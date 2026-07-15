#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
output <- if (length(args) >= 1L) args[[1L]] else ""

if (!requireNamespace("Rcpp", quietly = TRUE)) {
  stop("Rcpp is required for this benchmark.")
}

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script <- normalizePath(sub("^--file=", "", script_arg[[1L]]), mustWork = TRUE)
benchmark_dir <- dirname(script)
kernel_copy <- tempfile(fileext = ".cpp")
if (!file.copy(
  file.path(benchmark_dir, "binning-kernels.cpp"),
  kernel_copy,
  overwrite = TRUE
)) {
  stop("Failed to prepare the temporary benchmark kernel.")
}
on.exit(unlink(kernel_copy, force = TRUE), add = TRUE)
Rcpp::sourceCpp(kernel_copy)

cases <- expand.grid(
  n = c(1000L, 10000L, 100000L),
  nbins = c(8L, 100L),
  KEEP.OUT.ATTRS = FALSE
)
repetitions <- 15L

time_calls <- function(fun, iterations) {
  start <- proc.time()[["elapsed"]]
  for (i in seq_len(iterations)) {
    fun()
  }
  (proc.time()[["elapsed"]] - start) / iterations
}

calibrate_iterations <- function(fun, target_seconds = 0.05) {
  iterations <- 1L
  repeat {
    seconds_per_call <- time_calls(fun, iterations)
    elapsed <- seconds_per_call * iterations
    if (elapsed >= target_seconds) {
      return(iterations)
    }
    if (elapsed <= 0) {
      iterations <- iterations * 10L
    } else {
      iterations <- max(
        iterations + 1L,
        as.integer(ceiling(iterations * target_seconds / elapsed * 1.25))
      )
    }
  }
}

set.seed(20260714)
methods <- c("floor", "arithmetic", "lower_bound")
raw <- vector("list", nrow(cases) * repetitions * length(methods))
row <- 0L

for (case_index in seq_len(nrow(cases))) {
  case <- cases[case_index, ]
  values <- stats::runif(case$n, min = 1e-10, max = 1 - 1e-10)

  floor_fun <- function() bin_counts_floor_cpp(values, case$nbins)
  arithmetic_fun <- function() bin_counts_arithmetic_cpp(values, case$nbins)
  lower_fun <- function() bin_counts_lower_bound_cpp(values, case$nbins)

  stopifnot(
    identical(floor_fun(), arithmetic_fun()),
    identical(arithmetic_fun(), lower_fun())
  )
  boundaries <- seq.int(0L, case$nbins) / case$nbins
  stopifnot(identical(
    bin_counts_arithmetic_cpp(boundaries, case$nbins),
    bin_counts_lower_bound_cpp(boundaries, case$nbins)
  ))
  invisible(floor_fun())
  invisible(arithmetic_fun())
  invisible(lower_fun())
  iterations <- c(
    floor = calibrate_iterations(floor_fun),
    arithmetic = calibrate_iterations(arithmetic_fun),
    lower_bound = calibrate_iterations(lower_fun)
  )

  for (repetition in seq_len(repetitions)) {
    orders <- list(
      c("floor", "arithmetic", "lower_bound"),
      c("lower_bound", "floor", "arithmetic"),
      c("arithmetic", "lower_bound", "floor")
    )
    order <- orders[[(repetition - 1L) %% length(orders) + 1L]]

    for (method in order) {
      row <- row + 1L
      fun <- switch(
        method,
        floor = floor_fun,
        arithmetic = arithmetic_fun,
        lower_bound = lower_fun
      )
      elapsed <- time_calls(
        fun,
        iterations[[method]]
      )
      raw[[row]] <- data.frame(
        n = case$n,
        nbins = case$nbins,
        repetition = repetition,
        method = method,
        inner_iterations = iterations[[method]],
        seconds_per_call = elapsed,
        stringsAsFactors = FALSE
      )
    }
  }
}

raw <- do.call(rbind, raw)
keys <- interaction(raw$n, raw$nbins, raw$method, drop = TRUE)
summary_rows <- lapply(split(raw, keys), function(x) {
  data.frame(
    n = x$n[[1L]],
    nbins = x$nbins[[1L]],
    method = x$method[[1L]],
    median_ms = 1000 * stats::median(x$seconds_per_call),
    q25_ms = 1000 * stats::quantile(x$seconds_per_call, 0.25, names = FALSE),
    q75_ms = 1000 * stats::quantile(x$seconds_per_call, 0.75, names = FALSE),
    inner_iterations = x$inner_iterations[[1L]],
    repetitions = nrow(x),
    stringsAsFactors = FALSE
  )
})
summary <- do.call(rbind, summary_rows)
summary <- summary[order(summary$n, summary$nbins, summary$method), ]
rownames(summary) <- NULL

median_table <- reshape(
  summary[c("n", "nbins", "method", "median_ms")],
  idvar = c("n", "nbins"),
  timevar = "method",
  direction = "wide"
)
names(median_table) <- sub("^median_ms\\.", "", names(median_table))
ratio_table <- median_table[c("n", "nbins")]
ratio_table$arithmetic_over_floor <-
  median_table$arithmetic / median_table$floor
ratio_table$lower_bound_over_floor <-
  median_table$lower_bound / median_table$floor
ratio_table$arithmetic_over_lower_bound <-
  median_table$arithmetic / median_table$lower_bound
ratio_table <- ratio_table[order(ratio_table$n, ratio_table$nbins), ]

cat("BINNING_SUMMARY\n")
print(summary, row.names = FALSE)
cat("BINNING_RATIO\n")
print(ratio_table, row.names = FALSE)

if (nzchar(output)) {
  dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(summary, output, row.names = FALSE)
  ratio_output <- sub("\\.csv$", "-ratios.csv", output)
  utils::write.csv(ratio_table, ratio_output, row.names = FALSE)
}
