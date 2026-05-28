# Summarize per-replicate estimates into performance metrics, by estimator.
# `estimates` has columns estimator, estimate, se (one row per rep x estimator).
summarise_estimates <- function(estimates, truth, level = 0.95) {
  z <- stats::qnorm(1 - (1 - level) / 2)
  dplyr::summarise(
    dplyr::group_by(estimates, estimator),
    bias = mean(estimate) - truth,
    ese = stats::sd(estimate),
    mean_se = mean(se),
    ser = mean(se) / stats::sd(estimate),
    rmse = sqrt((mean(estimate) - truth)^2 + stats::sd(estimate)^2),
    coverage = mean(abs(estimate - truth) <= z * se),
    .groups = "drop"
  )
}
