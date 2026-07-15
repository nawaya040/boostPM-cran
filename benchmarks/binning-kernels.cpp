// Standalone benchmark kernels. Not part of the installed package.
#include <Rcpp.h>
#include <algorithm>
#include <cmath>
#include <limits>
#include <numeric>
#include <vector>

// [[Rcpp::export]]
Rcpp::IntegerVector bin_counts_floor_cpp(const Rcpp::NumericVector& values,
                                         const int nbins,
                                         const double left = 0.0,
                                         const double right = 1.0) {
  std::vector<int> counts(nbins, 0);
  const double width = (right - left) / static_cast<double>(nbins);

  for (const double value : values) {
    const int index = static_cast<int>(std::floor((value - left) / width));
    if (index < 0 || index >= nbins) {
      Rcpp::stop("floor benchmark input produced an invalid bin index");
    }
    ++counts[index];
  }

  std::partial_sum(counts.begin(), counts.end(), counts.begin());
  return Rcpp::wrap(counts);
}

// [[Rcpp::export]]
Rcpp::IntegerVector bin_counts_lower_bound_cpp(
    Rcpp::NumericVector values,
    const int nbins,
    const double left = 0.0,
    const double right = 1.0) {
  std::vector<int> counts(nbins, 0);
  std::vector<double> split_points(nbins - 1);
  for (int i = 0; i < nbins - 1; ++i) {
    split_points[i] = left + (right - left) *
      static_cast<double>(i + 1) / static_cast<double>(nbins);
  }

  const double scale = std::max({1.0, std::abs(left), std::abs(right)});
  const double tolerance =
    64.0 * std::numeric_limits<double>::epsilon() * scale;

  for (R_xlen_t i = 0; i < values.size(); ++i) {
    double value = values[i];
    if (!std::isfinite(value) ||
        value < left - tolerance || value > right + tolerance) {
      Rcpp::stop("lower-bound benchmark input is outside the interval");
    }
    if (value < left) {
      value = left;
      values[i] = left;
    } else if (value > right) {
      value = right;
      values[i] = right;
    }

    const auto position = std::lower_bound(
      split_points.begin(), split_points.end(), value
    );
    const int index = static_cast<int>(
      std::distance(split_points.begin(), position)
    );
    ++counts[index];
  }

  std::partial_sum(counts.begin(), counts.end(), counts.begin());
  return Rcpp::wrap(counts);
}

// [[Rcpp::export]]
Rcpp::IntegerVector bin_counts_arithmetic_cpp(
    Rcpp::NumericVector values,
    const int nbins,
    const double left = 0.0,
    const double right = 1.0) {
  std::vector<int> counts(nbins, 0);
  const double range = right - left;
  const double scale = std::max({1.0, std::abs(left), std::abs(right)});
  const double tolerance =
    64.0 * std::numeric_limits<double>::epsilon() * scale;

  for (R_xlen_t i = 0; i < values.size(); ++i) {
    double value = values[i];
    if (!std::isfinite(value) ||
        value < left - tolerance || value > right + tolerance) {
      Rcpp::stop("arithmetic benchmark input is outside the interval");
    }
    if (value < left) {
      value = left;
      values[i] = left;
    } else if (value > right) {
      value = right;
      values[i] = right;
    }

    int index = static_cast<int>(std::floor(
      (value - left) / range * static_cast<double>(nbins)
    ));
    index = std::max(0, std::min(index, nbins - 1));

    if (index > 0) {
      const double lower_candidate = left + range *
        static_cast<double>(index) / static_cast<double>(nbins);
      if (value <= lower_candidate) {
        --index;
      }
    }
    if (index < nbins - 1) {
      const double upper_candidate = left + range *
        static_cast<double>(index + 1) / static_cast<double>(nbins);
      if (value > upper_candidate) {
        ++index;
      }
    }

    const double final_lower = left + range *
      static_cast<double>(index) / static_cast<double>(nbins);
    const double final_upper = left + range *
      static_cast<double>(index + 1) / static_cast<double>(nbins);
    if (index < 0 || index >= nbins ||
        (index > 0 && value <= final_lower) ||
        (index < nbins - 1 && value > final_upper)) {
      Rcpp::stop("arithmetic benchmark could not assign a bin safely");
    }
    ++counts[index];
  }

  std::partial_sum(counts.begin(), counts.end(), counts.begin());
  return Rcpp::wrap(counts);
}
