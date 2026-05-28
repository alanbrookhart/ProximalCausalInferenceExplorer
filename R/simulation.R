# Vary one association (or n) across a grid of values, holding all else at
# `params`, and return the metrics at each grid point. When sweep_var == "n",
# the grid values set the sample size; otherwise they set params[[sweep_var]].
run_sweep <- function(params, sweep_var, values, n, M_sweep, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  rows <- lapply(values, function(v) {
    p <- params
    nn <- n
    if (sweep_var == "n") nn <- v else p[[sweep_var]] <- v
    m <- run_monte_carlo(p, n = nn, M = M_sweep)$metrics
    m$value <- v
    m
  })
  dplyr::bind_rows(rows)
}

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
