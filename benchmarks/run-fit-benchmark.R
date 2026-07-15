#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
output <- if (length(args) >= 1L) args[[1L]] else "fit-benchmark.csv"

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script <- normalizePath(sub("^--file=", "", script_arg[[1L]]), mustWork = TRUE)
benchmark_dir <- dirname(script)
root <- normalizePath(file.path(benchmark_dir, ".."), mustWork = TRUE)

workspace <- tempfile("boostpm-benchmark-")
dir.create(workspace, recursive = TRUE)
on.exit(unlink(workspace, recursive = TRUE, force = TRUE), add = TRUE)

copy_source <- function(from, to, excluded_top_level = character()) {
  dir.create(to, recursive = TRUE, showWarnings = FALSE)
  entries <- list.files(
    from,
    all.files = TRUE,
    recursive = TRUE,
    full.names = FALSE,
    include.dirs = TRUE,
    no.. = TRUE
  )
  normalized <- gsub("\\\\", "/", entries)
  excluded <- vapply(
    normalized,
    function(path) {
      top <- strsplit(path, "/", fixed = TRUE)[[1L]][[1L]]
      top %in% excluded_top_level || grepl("\\.Rcheck$", top) ||
        grepl("^boostPM_.*\\.tar\\.gz$", top)
    },
    logical(1)
  )

  for (entry in entries[!excluded]) {
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

current_source <- file.path(workspace, "current-source")
floor_source <- file.path(workspace, "current-floor-source")
lower_source <- file.path(workspace, "current-lower-bound-source")
original_source <- file.path(workspace, "original-source")
copy_source(
  root,
  current_source,
  excluded_top_level = c(
    ".agents", ".codex", ".git", ".sandbox", "benchmarks", "docs",
    "original", "validation"
  )
)
copy_source(
  file.path(root, "original"),
  original_source,
  excluded_top_level = ".git"
)
copy_source(current_source, floor_source)
copy_source(current_source, lower_source)

replace_binning_kernel <- function(source, kernel) {
  cpp_path <- file.path(source, "src", "class_boosting.cpp")
  cpp <- readLines(cpp_path, warn = FALSE)
  start <- grep("BOOSTPM_BENCHMARK_BINNING_BEGIN", cpp, fixed = TRUE)
  end <- grep("BOOSTPM_BENCHMARK_BINNING_END", cpp, fixed = TRUE)
  if (length(start) != 1L || length(end) != 1L || start >= end) {
    stop("Could not locate the temporary binning replacement markers.")
  }
  cpp <- c(cpp[seq_len(start - 1L)], kernel, cpp[(end + 1L):length(cpp)])
  writeLines(cpp, cpp_path, useBytes = TRUE)
}
floor_kernel <- c(
  "  double bin_width = (right - left) / (double) nbins;",
  "  for(int i=0; i<size; i++){",
  "    double x_temp = residuals_current(dim, indices_temp[i]);",
  "    int ind = floor((x_temp - left) / bin_width);",
  "    if(ind < 0 || ind >= nbins){",
  "      Rcpp::stop(\"Temporary floor benchmark produced an invalid bin.\");",
  "    }",
  "    count_vec(ind) = count_vec(ind) + 1;",
  "  }"
)
lower_kernel <- c(
  "  vector<double> split_points(num_grid_points_L);",
  "  for(int i=0; i<num_grid_points_L; i++){",
  "    split_points[i] = left + (right - left) * L_candidates(i);",
  "  }",
  "  const double interval_scale = std::max({1.0, std::abs(left), std::abs(right)});",
  "  const double boundary_tolerance =",
  "    64.0 * std::numeric_limits<double>::epsilon() * interval_scale;",
  "  for(int i=0; i<size; i++){",
  "    const int observation_index = indices_temp[i];",
  "    double x_temp = residuals_current(dim, observation_index);",
  "    if(!std::isfinite(x_temp) ||",
  "       x_temp < left - boundary_tolerance ||",
  "       x_temp > right + boundary_tolerance){",
  "      Rcpp::stop(\"Temporary lower-bound benchmark input is outside the interval.\");",
  "    }",
  "    if(x_temp < left){",
  "      x_temp = left;",
  "      residuals_current(dim, observation_index) = left;",
  "    }else if(x_temp > right){",
  "      x_temp = right;",
  "      residuals_current(dim, observation_index) = right;",
  "    }",
  "    const auto position = std::lower_bound(",
  "      split_points.begin(), split_points.end(), x_temp",
  "    );",
  "    const int ind = static_cast<int>(",
  "      std::distance(split_points.begin(), position)",
  "    );",
  "    if(ind < 0 || ind >= nbins){",
  "      Rcpp::stop(\"Temporary lower-bound benchmark produced an invalid bin.\");",
  "    }",
  "    count_vec(ind) = count_vec(ind) + 1;",
  "  }"
)
replace_binning_kernel(floor_source, floor_kernel)
replace_binning_kernel(lower_source, lower_kernel)

current_lib <- file.path(workspace, "current-lib")
floor_lib <- file.path(workspace, "current-floor-lib")
lower_lib <- file.path(workspace, "current-lower-bound-lib")
original_lib <- file.path(workspace, "original-lib")
dir.create(current_lib)
dir.create(floor_lib)
dir.create(lower_lib)
dir.create(original_lib)

r_binary <- file.path(R.home("bin"), "R")
rscript_binary <- file.path(R.home("bin"), "Rscript")
install_one <- function(source, library) {
  status <- system2(
    r_binary,
    c("CMD", "INSTALL", paste0("--library=", shQuote(library)), shQuote(source)),
    stdout = TRUE,
    stderr = TRUE
  )
  if (!is.null(attr(status, "status")) && attr(status, "status") != 0L) {
    stop(paste(status, collapse = "\n"))
  }
}

install_one(current_source, current_lib)
install_one(floor_source, floor_lib)
install_one(lower_source, lower_lib)
install_one(original_source, original_lib)

worker <- file.path(benchmark_dir, "fit-worker.R")
current_output <- file.path(workspace, "current.csv")
floor_output <- file.path(workspace, "current-floor.csv")
lower_output <- file.path(workspace, "current-lower-bound.csv")
original_output <- file.path(workspace, "original.csv")

run_worker <- function(library, label, worker_output) {
  status <- system2(
    rscript_binary,
    c(shQuote(worker), shQuote(library), label, shQuote(worker_output)),
    stdout = TRUE,
    stderr = TRUE
  )
  if (!is.null(attr(status, "status")) && attr(status, "status") != 0L) {
    stop(paste(status, collapse = "\n"))
  }
}

run_worker(original_lib, "original", original_output)
run_worker(floor_lib, "current_floor", floor_output)
run_worker(lower_lib, "current_lower_bound", lower_output)
run_worker(current_lib, "current", current_output)

raw <- rbind(
  utils::read.csv(original_output, stringsAsFactors = FALSE),
  utils::read.csv(floor_output, stringsAsFactors = FALSE),
  utils::read.csv(lower_output, stringsAsFactors = FALSE),
  utils::read.csv(current_output, stringsAsFactors = FALSE)
)
dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
utils::write.csv(raw, output, row.names = FALSE)

summaries <- lapply(split(raw, interaction(raw$implementation, raw$case)), function(x) {
  data.frame(
    implementation = x$implementation[[1L]],
    case = x$case[[1L]],
    median_seconds = stats::median(x$elapsed_seconds),
    q25_seconds = stats::quantile(x$elapsed_seconds, 0.25, names = FALSE),
    q75_seconds = stats::quantile(x$elapsed_seconds, 0.75, names = FALSE),
    checksum_count = length(unique(x$checksum)),
    stringsAsFactors = FALSE
  )
})
summary <- do.call(rbind, summaries)
summary <- summary[order(summary$case, summary$implementation), ]
rownames(summary) <- NULL

cat("FIT_SUMMARY\n")
print(summary, row.names = FALSE)

current <- summary[summary$implementation == "current", ]
floor <- summary[summary$implementation == "current_floor", ]
lower <- summary[summary$implementation == "current_lower_bound", ]
original <- summary[summary$implementation == "original", ]
ratio <- merge(
  current[, c("case", "median_seconds")],
  original[, c("case", "median_seconds")],
  by = "case",
  suffixes = c("_current", "_original")
)
ratio <- merge(
  ratio,
  floor[, c("case", "median_seconds")],
  by = "case"
)
names(ratio)[names(ratio) == "median_seconds"] <- "median_seconds_floor"
ratio <- merge(
  ratio,
  lower[, c("case", "median_seconds")],
  by = "case"
)
names(ratio)[names(ratio) == "median_seconds"] <-
  "median_seconds_lower_bound"
ratio$current_over_original <-
  ratio$median_seconds_current / ratio$median_seconds_original
ratio$current_over_floor <-
  ratio$median_seconds_current / ratio$median_seconds_floor
ratio$current_over_lower_bound <-
  ratio$median_seconds_current / ratio$median_seconds_lower_bound
cat("FIT_RATIO\n")
print(ratio, row.names = FALSE)

if (grepl("\\.csv$", output)) {
  utils::write.csv(
    summary,
    sub("\\.csv$", "-summary.csv", output),
    row.names = FALSE
  )
  utils::write.csv(
    ratio,
    sub("\\.csv$", "-ratios.csv", output),
    row.names = FALSE
  )
}

for (case in unique(raw$case)) {
  checks <- split(raw$checksum[raw$case == case], raw$implementation[raw$case == case])
  if (!identical(checks$current, checks$original) ||
      !identical(checks$current, checks$current_floor) ||
      !identical(checks$current, checks$current_lower_bound)) {
    stop("Numerical checksum mismatch in case: ", case)
  }
}
