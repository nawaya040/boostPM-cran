.boostpm_early_stop_controls <- function(early_stop) {
  if (is.null(early_stop)) {
    return(list(
      eta_subsample = 1.0,
      thresh_stop = 1.0,
      ntrees_wait = 100
    ))
  }

  list(
    eta_subsample = 0.9,
    thresh_stop = early_stop[1],
    ntrees_wait = early_stop[2]
  )
}

