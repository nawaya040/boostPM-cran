#ifndef BOOST_H
#define BOOST_H

// [[Rcpp::depends(RcppArmadillo)]]
#include <RcppArmadillo.h>
#include <vector>
#include "helpers.h"

struct Node
{
  unsigned int node_id; //1(=root),2,3,...
  
  int depth;
  
  arma::vec left_points;
  arma::vec right_points;
  
  int dim_selected; 
  
  double location; // the value of "L"
  double partition_point; //The partition point in the selected dimension
  
  unsigned int counts;
  
  double theta_old;
  double theta;

  std::vector<int> indices; //indices of observations included in this node
  
  Node* parent = nullptr;
  Node* left = nullptr;
  Node* right = nullptr;
};

class class_boosting{
  
public:
  
  //Constructor
  class_boosting(
                      arma::mat X,
                      double prior_split_prob,
                      double gamma,
                      int max_resol,
                      int num_each_dim,
                      int num_second,
                      double learn_rate,
                      int min_obs,
                      int nbins,
                      double eta_subsample,
                      double thresh_stop,
                      int ntrees_wait,
                      bool show_progress
  );
  
  //Input information
  arma::mat X; //n x d 
  double prior_split_prob;
  double gamma;
  double rho; //what is rho?
  int max_resol;
  int num_each_dim;
  int num_second;

  double learn_rate;
  int min_obs;
  int nbins;
  
  double eta_subsample;
  double thresh_stop;
  int ntrees_wait;
  bool show_progress;

  int parameter_for_test;

  //variables
  int n;
  int d;
  //int n_eval;
  
  int num_trees;
  arma::ivec active_vars;
  

  ///////////////////////////////////////////////////////////////////////////
  // variables for boosting
  arma::mat residuals_current; //Note: this matrix is d x n
  
  int num_grid_points_L;
  arma::vec L_candidates;
  
  int current_dim_first;
  arma::mat log_like_matrix;
  
  Node** root_nodes;
  
  std::vector<int> tree_size_store;
  std::vector<int> max_depth_store;
  std::vector<int> tree_stage;
  
  arma::mat residuals_last_boosting;

  arma::vec importances;
  
  bool is_first_stage;
  
  int size_subsample;
  
  arma::uvec indices_used;
  arma::uvec indices_not_used;
  
  std::vector<double> improvement_curve;
  std::vector<int> improvement_stage;
  std::vector<bool> improvement_accepted;
  
  //variables to store the information of generated trees
  std::vector<int> d_store;
  std::vector<double> l_store;
  std::vector<double> theta_store;
  Rcpp::List tree_list;
  
  //use only a part of variables
  arma::ivec is_selected_vec;
  
  //Variables to store the information of the old tree and measure
  int dim_selected_old;
  double location_old;
  double partition_point_old;
  double theta_old;

  //Initialization
  void init();

  //tree functions
  Node* get_root_node();
  Node* get_new_node(Node* parent, bool this_is_left, int dim_selected, double location);

  void add_children(Node* node, int dim_selected, double location);

  void count_total_nodes(Node* node, int& count);
  
  Node* find_terminal_node(Node* root, arma::vec& x);

  double evaluate_density(Node* root, arma::vec& x);
  
  //Boosting functions
  void boosting();
  void construct_tree(Node* node);
  bool split_node(Node* node);
  
  //utilities for boosting
  arma::ivec make_left_count_vector(Node* node, int dim);
  double get_split_prob(Node* node);
  void check_max_depth( Node* node, int& depth_max);
  void print_progress_boosting(int step);

  arma::vec residualize(Node* root, arma::vec& x);
  
  double local_move(double x, double left_point, double right_point, 
                    double theta, double area_ratio, bool left);
  double evaluate_log_prior(Node* node);

  //print the progress of mcmc sampling
  void print_progress(int index_MCMC);
  
  //output
  Rcpp::List output();
  
  //destructor
  ~class_boosting();
  void clear_node(Node* root) noexcept;
  
  //miscellaneous functions
  double compute_splitting_prob(int depth);

};
  
#endif
