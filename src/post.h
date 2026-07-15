#ifndef post_H
#define post_H

// [[Rcpp::depends(RcppArmadillo)]]
#include <RcppArmadillo.h>

struct PostNode
{
  arma::vec left_points;
  arma::vec right_points;
  
  int dim_selected; 
  
  double location; // the value of "L"
  double partition_point; //The partition point in the selected dimension
  
  double theta;
  
  PostNode* parent = nullptr;
  PostNode* left = nullptr;
  PostNode* right = nullptr;
};

//Main functions
arma::mat simulation(Rcpp::List tree_list, int size_simulation, arma::mat support);
arma::vec update_vec(PostNode* node, arma::vec& x);
Rcpp::List evaluate_log_density(Rcpp::List tree_list, arma::mat eval_points, arma::mat support);

//Tree functions

PostNode* get_root_node(int dimension);
PostNode* get_new_node(PostNode* parent, bool this_is_left, int dim_selected, double location);

void construct_tree(PostNode* node, Rcpp::List tree_current);

double evaluate_density(PostNode* root, arma::vec& x);
arma::vec residualize(PostNode* root, arma::vec& x);

PostNode* find_terminal_node(PostNode* root, arma::vec& x);

double local_move(double x, double left_point, double right_point, 
                  double theta, double area_ratio, bool left);
  
//for cleaning
void clear_node(PostNode* root) noexcept;

#endif
