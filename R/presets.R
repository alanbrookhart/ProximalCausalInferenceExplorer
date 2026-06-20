# ==============================================================================
# Script: R/presets.R
# Author: Alan Brookhart (alan.brookhart@duke.edu)
# Date: June 2026
# Version: 1.0.0
#
# Description:
#   Named parameter sets for the sidebar scenario buttons. Each preset starts
#   from default_params() and overrides the "story" knobs (residual confounding
#   delta and proxy invalidity lambda, plus proxy strengths) to illustrate a
#   teaching scenario. Includes the three Zivich et al. 2023 simulation
#   scenarios, whose data-generating process maps one-to-one onto this app's.
#
# Core Architecture:
#   - presets(): returns a named list of parameter lists; the UI auto-generates
#     a button and observer for each entry.
#   - Depends on default_params() (R/dgp.R).
#
# Usage:
#   Sourced automatically by Shiny at runtime; not run directly.
# ==============================================================================

# Named parameter sets for the scenario buttons. Each starts from defaults and
# overrides the "story" knobs.
presets <- function() {
  base <- default_params()

  # Zivich et al. 2023 ("Introducing Proximal Causal Inference for
  # Epidemiologists", Web Appendix 2). Their DGP maps one-to-one onto this
  # app's: X~N(0,1), U=X+N, Z=U+N, W=U+N, A=logit(Z+X+ΔU), Y=-A+W+X+ΔU+ΛZ+N.
  # So tau=-1, all proxy/edge strengths and X effects = 1; scenarios vary only
  # Δ (residual confounding, delta) and Λ (invalid proxy, lambda).
  zivich <- modifyList(base, list(
    tau = -1, gamma_z = 1, gamma_w = 1, alpha_z = 1, beta_w = 1,
    alpha_x = 1, beta_x = 1, a_xu = 1
  ))

  list(
    "Valid proxies"        = modifyList(base, list(delta = 0, lambda = 0)),
    "Residual confounding" = modifyList(base, list(delta = 1, lambda = 0)),
    "Invalid proxy"        = modifyList(base, list(delta = 1, lambda = 1)),
    "Weak proxies"         = modifyList(base, list(gamma_z = 0.3, gamma_w = 0.3,
                                                   delta = 1, lambda = 0)),
    "Zivich S1"            = modifyList(zivich, list(delta = 0, lambda = 0)),
    "Zivich S2"            = modifyList(zivich, list(delta = 1, lambda = 0)),
    "Zivich S3"            = modifyList(zivich, list(delta = 1, lambda = 1))
  )
}
