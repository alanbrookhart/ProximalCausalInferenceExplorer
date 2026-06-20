# ==============================================================================
# Script: R/simulation.R
# Author: Alan Brookhart (alan.brookhart@duke.edu)
# Date: June 2026
# Version: 1.0.0
#
# Description:
#   Monte Carlo simulation engine. Repeatedly simulates datasets, fits every
#   estimator, and summarizes the results; also sweeps one association (or the
#   sample size n) across a grid of values to trace how the estimators behave.
#
# Core Architecture:
#   - run_monte_carlo(params, n, M, seed): M replicates at sample size n,
#     returning per-rep estimates, the metrics summary, and the true effect.
#   - run_sweep(params, sweep_var, values, n, M_sweep, seed): metrics at each
#     grid value of sweep_var (or n).
#   - Depends on simulate_data() (R/dgp.R), fit_all() (R/estimators.R), and
#     summarise_estimates() (R/metrics.R).
#
# Usage:
#   Sourced automatically by Shiny at runtime; not run directly.
# ==============================================================================

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
