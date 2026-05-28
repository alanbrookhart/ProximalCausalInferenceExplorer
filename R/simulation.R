# Run M Monte Carlo replicates at sample size n for a fixed parameter set.
run_monte_carlo <- function(params, n, M, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  reps <- lapply(seq_len(M), function(i) {
    fa <- fit_all(simulate_data(n, params))
    fa$rep <- i
    fa
  })
  estimates <- dplyr::bind_rows(reps)
  list(
    estimates = estimates,
    metrics = summarise_estimates(estimates, truth = params$tau),
    truth = params$tau
  )
}
