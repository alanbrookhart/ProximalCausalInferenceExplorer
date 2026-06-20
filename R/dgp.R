# ==============================================================================
# Script: R/dgp.R
# Author: Alan Brookhart (alan.brookhart@duke.edu)
# Date: June 2026
# Version: 1.0.0
#
# Description:
#   Data-generating process for the proximal-causal-inference simulation. Defines
#   the default structural parameters and simulates one dataset of i.i.d. units
#   with an unmeasured confounder U, measured confounder X, treatment proxy Z,
#   outcome proxy W, treatment A, and outcome Y.
#
# Core Architecture:
#   - default_params(): the baseline parameter list (effect sizes, edge
#     strengths, and noise SDs).
#   - simulate_data(n, params): draws n units from the structural equations used
#     throughout the app and described on the Methods tab.
#
# Usage:
#   Sourced automatically by Shiny at runtime; not run directly.
# ==============================================================================

# Default parameter set. The app opens on "residual confounding" (delta = 1,
# lambda = 0) so the proximal advantage is visible immediately.
default_params <- function() {
  list(
    tau = 1.0,
    gamma_z = 1.0, gamma_w = 1.0,
    delta = 1.0, lambda = 0.0,
    alpha_z = 1.0, beta_w = 1.0,
    alpha_x = 0.5, beta_x = 0.5,
    a_xu = 1.0, alpha0 = 0.0,
    sd_u = 1.0, sd_z = 1.0, sd_w = 1.0, sd_y = 1.0
  )
}

# Simulate one dataset of n i.i.d. units from the proximal-CI DGP.
simulate_data <- function(n, params) {
  p <- params
  X <- rnorm(n, 0, 1)
  U <- p$a_xu * X + rnorm(n, 0, p$sd_u)
  Z <- p$gamma_z * U + rnorm(n, 0, p$sd_z)
  W <- p$gamma_w * U + rnorm(n, 0, p$sd_w)
  eta <- p$alpha0 + p$alpha_z * Z + p$alpha_x * X + p$delta * U
  A <- rbinom(n, 1, plogis(eta))
  Y <- p$tau * A + p$beta_w * W + p$beta_x * X + p$delta * U +
    p$lambda * Z + rnorm(n, 0, p$sd_y)
  data.frame(X = X, U = U, Z = Z, W = W, A = A, Y = Y)
}
