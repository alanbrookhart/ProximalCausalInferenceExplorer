# Named parameter sets for the scenario buttons. Each starts from defaults and
# overrides the "story" knobs.
presets <- function() {
  base <- default_params()
  list(
    "Valid proxies"        = modifyList(base, list(delta = 0, lambda = 0)),
    "Residual confounding" = modifyList(base, list(delta = 1, lambda = 0)),
    "Invalid proxy"        = modifyList(base, list(delta = 1, lambda = 1)),
    "Weak proxies"         = modifyList(base, list(gamma_z = 0.3, gamma_w = 0.3,
                                                   delta = 1, lambda = 0))
  )
}
