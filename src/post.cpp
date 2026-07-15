// [[Rcpp::depends(RcppArmadillo)]]
#include <RcppArmadillo.h>
#include <cmath>
#include <memory>
#include <stack>
#include "post.h"

using namespace Rcpp;
using namespace arma;
using namespace std;

namespace {

void validate_support(const arma::mat& support){
  if(support.n_rows == 0 || support.n_cols != 2){
    Rcpp::stop("`support` must have one row per variable and exactly two columns.");
  }
  if(!support.is_finite()){
    Rcpp::stop("`support` must contain only finite values.");
  }
  for(arma::uword j = 0; j < support.n_rows; ++j){
    if(!(support(j, 1) > support(j, 0))){
      Rcpp::stop("Each row of `support` must have a positive width.");
    }
  }
}

}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Main functions
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


// [[Rcpp::export]]
arma::mat simulation(Rcpp::List tree_list, int size_simulation, arma::mat support){
  validate_support(support);
  if(size_simulation < 0){
    Rcpp::stop("`size_simulation` must be non-negative.");
  }
  
  //initialization
  const int dimension = support.n_rows;
  mat current_mat = zeros(dimension, size_simulation);
  
  for(int i=0; i<size_simulation; i++){
    if(i % 1024 == 0){
      Rcpp::checkUserInterrupt();
    }
    vec temp = Rcpp::runif(dimension, 0.0, 1.0);
    current_mat.col(i) = temp;
  }
  
  int num_trees = tree_list.size();

  for(int index_tree = num_trees-1; index_tree>-1; index_tree--){
    Rcpp::checkUserInterrupt();
    //reconstruct a tree
    auto tree_deleter = [](PostNode* node) {
      clear_node(node);
    };
    std::unique_ptr<PostNode, decltype(tree_deleter)> root_guard(
      get_root_node(dimension), tree_deleter
    );
    PostNode* root = root_guard.get();
    construct_tree(root, tree_list[index_tree]);
    
    //update the current values with the top-down algorithm
    vec x_temp;
    for(int i=0; i<size_simulation; i++){
      if(i % 1024 == 0){
        Rcpp::checkUserInterrupt();
      }
      x_temp = current_mat.col(i);
      current_mat.col(i) = update_vec(root, x_temp);
    }

  }
  
  for(int i=0; i<size_simulation; i++){
    if(i % 1024 == 0){
      Rcpp::checkUserInterrupt();
    }
    vec temp = current_mat.col(i);
    for(int j=0; j < dimension; j++){
      temp(j) = support(j,0) + temp(j) * (support(j,1) - support(j,0));
    }

    current_mat.col(i) = temp;
  }
  
  return current_mat.t();
}


vec update_vec(PostNode* node, vec& x){
  vec x_new = x;
  
  PostNode* curr = node;
  
  int dim;
  double a, b, c;
  double theta;
  double thresh;
  double y, z;
  
  while(curr->left != nullptr){
    
    //get the information of the current node
    dim = curr->dim_selected;
    a = curr->left_points(dim);
    b = curr->right_points(dim);
    c = curr->partition_point;
    theta = curr->theta;
    
    //move a value in the chosen dimension
    thresh = a + theta * (b - a);
    y = x_new(dim);
    z = (y - a) / (b - a);

    if(y <= thresh){
      x_new(dim) = a + (c-a) / theta * z;
      
      curr = curr->left;
      
    }else{
      x_new(dim) = c + (b-c) / (1-theta) * (z - theta);
      
      curr = curr->right;
    }
    
  }
  
  return x_new;
}


// [[Rcpp::export]]
Rcpp::List evaluate_log_density(Rcpp::List tree_list, arma::mat eval_points, arma::mat support){
  validate_support(support);
  if(eval_points.n_cols != support.n_rows){
    Rcpp::stop("`eval_points` must have one column per support row.");
  }
  if(!eval_points.is_finite()){
    Rcpp::stop("`eval_points` must contain only finite values.");
  }
  //initialization
  const int dimension = support.n_rows;
  
  vec log_width_store = zeros(dimension);
  
  for(int j=0; j<dimension; j++){
    double m_resize = support(j,0);
    double M_resize = support(j,1);
    
    eval_points.col(j) = (eval_points.col(j) - m_resize) / (M_resize - m_resize);
    
    log_width_store(j) = log(M_resize - m_resize);
  }
  
  double sum_log_width = sum(log_width_store);
  
  int n_eval = eval_points.n_rows;
  mat residuals_eval_points = eval_points.t();
  
  vec log_densities_boosting = zeros(n_eval);
  
  int num_trees = tree_list.size();
  
  vec mean_log_dens_path = zeros(num_trees);
  
  for(int index_tree = 0; index_tree<num_trees; index_tree++){
    Rcpp::checkUserInterrupt();
    //reconstruct a tree
    auto tree_deleter = [](PostNode* node) {
      clear_node(node);
    };
    std::unique_ptr<PostNode, decltype(tree_deleter)> root_guard(
      get_root_node(dimension), tree_deleter
    );
    PostNode* root = root_guard.get();
    construct_tree(root, tree_list[index_tree]);
    
    //evaluate densities
    vec x_temp;
    for(int i=0; i<n_eval; ++i){
      if(i % 1024 == 0){
        Rcpp::checkUserInterrupt();
      }
      x_temp = residuals_eval_points.col(i);
      log_densities_boosting(i) = log_densities_boosting(i) + evaluate_density(root, x_temp);
    }
    
    for(int i=0;i<n_eval;i++){
      if(i % 1024 == 0){
        Rcpp::checkUserInterrupt();
      }
      x_temp = residuals_eval_points.col(i);
      residuals_eval_points.col(i) = residualize(root, x_temp);
    } 
    
    //record progress
    mean_log_dens_path(index_tree) = mean(log_densities_boosting) - sum_log_width;
    
  }
  
  List out;
  
  out = Rcpp::List::create(Rcpp::Named("log_densities") = log_densities_boosting - sum_log_width,
                                Rcpp::Named("mean_log_dens_path") = mean_log_dens_path);
  
  return out;
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Tree functions
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

PostNode* get_root_node(int dimension){
  PostNode* new_node = new PostNode;
  
  new_node->left_points = zeros<vec>(dimension);
  new_node->right_points = ones<vec>(dimension);
  
  new_node->dim_selected = 0; //Not registered 
  new_node->location = 0; //Not registered 
  new_node->partition_point = 0; //Not registered 
  
  new_node->parent = nullptr;
  new_node->left = nullptr;
  new_node->right = nullptr;

  return new_node;
}

PostNode* get_new_node(PostNode* parent, bool this_is_left, int dim_selected, double location){

  double left = parent->left_points(dim_selected);
  double right = parent->right_points(dim_selected);
  
  parent->partition_point = left + location * (right - left);
  
  //Make a new child node
  PostNode* new_node = new PostNode;

  new_node->left_points = parent->left_points;
  new_node->right_points = parent->right_points;
  
  if(this_is_left){
    new_node->right_points(dim_selected) = parent->partition_point;
  }else{
    new_node->left_points(dim_selected) = parent->partition_point;
  }
  

  new_node->dim_selected = 0; //Not registered 
  new_node->location = 0; //Not registered 
  new_node->partition_point = 0; //Not registered 
  
  new_node->parent = parent;
  new_node->left = nullptr;
  new_node->right = nullptr;

  return new_node;
}


void construct_tree(PostNode* node, List tree_current){
  
  ivec d_store = tree_current["d"];
  vec l_store = tree_current["l"];
  vec theta_store = tree_current["theta"];

  const arma::uword num_nodes = d_store.n_elem;
  if(num_nodes == 0 || l_store.n_elem != num_nodes ||
     theta_store.n_elem != num_nodes){
    Rcpp::stop("Serialized tree components must have equal non-zero lengths.");
  }
  
  //Make a stack for nodes
  std::stack<PostNode*> stack_tree;
  
  //current node
  PostNode* curr = node;
  int index_node = 0;
  std::size_t nodes_visited = 0;
  
  while(curr != nullptr || stack_tree.empty() == false){
    
    while(curr != nullptr){
      if(nodes_visited % 1024 == 0){
        Rcpp::checkUserInterrupt();
      }
      ++nodes_visited;
      stack_tree.push(curr);

      if(static_cast<arma::uword>(index_node) >= num_nodes){
        Rcpp::stop("Serialized tree ended before reconstruction was complete.");
      }
      
      //check whether or not to split the current node here
      
      bool is_split = (d_store(index_node) > -1);

      if(d_store(index_node) < -1){
        Rcpp::stop("Serialized tree dimension values must be -1 or non-negative.");
      }
      
      //split the current node if necessary
      if(is_split){
        if(static_cast<arma::uword>(d_store(index_node)) >=
           curr->left_points.n_elem){
          Rcpp::stop("Serialized tree contains a dimension outside the support.");
        }
        if(!std::isfinite(l_store(index_node)) ||
           l_store(index_node) <= 0.0 || l_store(index_node) >= 1.0){
          Rcpp::stop("Serialized tree split locations must lie strictly between 0 and 1.");
        }
        if(!std::isfinite(theta_store(index_node))){
          Rcpp::stop("Serialized tree theta values must be finite.");
        }
        curr->dim_selected = d_store(index_node);
        curr->location = l_store(index_node);
        curr->theta = theta_store(index_node);
        
        curr->left = get_new_node(curr, true, curr->dim_selected, curr->location);
        curr->right = get_new_node(curr, false, curr->dim_selected, curr->location);
      }
      
      index_node++;
      
      curr = curr->left;
    }
    
    //the current node must be nullptr at this point
    curr = stack_tree.top();
    stack_tree.pop();
    
    curr = curr->right;
  }

  if(static_cast<arma::uword>(index_node) != num_nodes){
    Rcpp::stop("Serialized tree contains unused node entries.");
  }

}

double evaluate_density(PostNode* root, vec& x){
  
  //finde a terminal node that x belongs to
  PostNode* curr = find_terminal_node(root, x);
  
  //go up the tree one by one
  PostNode* parent;
  
  double dens_curr = 0.0;
  
  while(curr->parent != nullptr){
    
    parent = curr->parent;
    
    if(parent->left == curr){
      dens_curr  = dens_curr + log(parent->theta) - log(parent->location);
    }else{
      dens_curr  = dens_curr + log(1-parent->theta) - log(1-parent->location);
    }
    
    curr = parent;
  }
  
  return dens_curr;
  
}

vec residualize(PostNode* root, vec& x){
  
  //finde a terminal node that x belongs to
  PostNode* curr = find_terminal_node(root, x);
  
  //go up the tree one by one
  PostNode* parent;
  
  int dim_selected;
  
  double left_point;
  double right_point;
  double theta;
  
  vec resid_curr = x;
  
  while(curr->parent != nullptr){
    
    parent = curr->parent;
    
    dim_selected = parent->dim_selected;
    
    left_point = parent->left_points(dim_selected);
    right_point = parent->right_points(dim_selected);
    theta = parent->theta;
    
    resid_curr(dim_selected) = local_move(resid_curr(dim_selected), left_point, right_point, theta, parent->location, parent->left == curr);
    
    curr = parent;
  }
  
  return resid_curr;
}

PostNode* find_terminal_node(PostNode* root, vec& x){
  
  PostNode* curr = root;
  
  while(curr->left != nullptr){
    int dim_selected = curr->dim_selected;
    
    if(x(dim_selected) <= curr->partition_point){
      curr = curr->left;
    }else{
      curr = curr->right;
    }
    
  }
  
  return curr;
  
}

double local_move(double x, double left_point, double right_point, 
                   double theta, double area_ratio, bool left){
  
  if(left){
    return left_point + theta / area_ratio * (x - left_point);
  }else{
    return right_point + (1-theta) / (1-area_ratio) * (x - right_point);
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// for clearning
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


void clear_node(PostNode* root) noexcept{
  PostNode* curr = root;

  while(curr != nullptr){
    if(curr->left != nullptr){
      curr = curr->left;
      continue;
    }
    if(curr->right != nullptr){
      curr = curr->right;
      continue;
    }

    PostNode* parent = curr->parent;
    if(parent != nullptr){
      if(parent->left == curr){
        parent->left = nullptr;
      }else if(parent->right == curr){
        parent->right = nullptr;
      }
    }
    delete curr;
    curr = parent;
  }
}
