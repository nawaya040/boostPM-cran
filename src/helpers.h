#ifndef HELPERS_H
#define HELPERS_H

// [[Rcpp::depends(RcppArmadillo)]]
#include <RcppArmadillo.h>

int OneSample(const arma::vec& vw);
int OneSample_uniform(const int size);
double log_beta(const double a, const double b);
double log_sum_vec(const arma::vec& log_x);
double log_sum_mat(const arma::mat& log_x);
arma::vec log_normalize_vec(const arma::vec& log_x);
arma::mat log_normalize_mat(const arma::mat& log_x);
double second_max(arma::vec x);
double second_min(arma::vec x);

#endif
