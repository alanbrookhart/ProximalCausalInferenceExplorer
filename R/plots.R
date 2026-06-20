# ==============================================================================
# Script: R/plots.R
# Author: Alan Brookhart (alan.brookhart@duke.edu)
# Date: June 2026
# Version: 1.0.0
#
# Description:
#   ggplot builders for the simulation result views. Produces the Snapshot plot
#   (overlaid sampling distributions of the estimators) and the Sweep plot (bias
#   and ESE/RMSE versus a swept parameter). All geoms are ggiraph-interactive for
#   hover tooltips and cross-plot highlighting in the Shiny app.
#
# Core Architecture:
#   - plot_snapshot(mc): density curves of per-replicate estimates by estimator.
#   - plot_sweep(sweep_df, sweep_var, metric): two stacked panels (bias, then
#     ESE or RMSE) versus the swept value, one line per estimator.
#   - Depends on ESTIMATOR_COLORS / PALETTE and headwater_ggtheme() (R/theme.R).
#
# Usage:
#   Sourced automatically by Shiny at runtime; not run directly.
# ==============================================================================

# Overlaid sampling distributions of the per-replicate estimates, one curve per
# estimator, with a dashed line at the true effect. Uses ggiraph's interactive
# density so the Shiny app can show per-curve tooltips on hover.
plot_snapshot <- function(mc) {
  est <- mc$estimates
  est$estimator <- factor(est$estimator, levels = names(ESTIMATOR_COLORS))
  ggplot2::ggplot(est, ggplot2::aes(x = estimate, colour = estimator, fill = estimator)) +
    ggiraph::geom_density_interactive(
      ggplot2::aes(tooltip = estimator, data_id = estimator),
      alpha = 0.12, linewidth = 0.9
    ) +
    ggplot2::geom_vline(xintercept = mc$truth, linetype = "dashed",
                        colour = PALETTE$graphite) +
    ggplot2::annotate("text", x = mc$truth, y = Inf, label = "true τ",
                      vjust = 1.4, hjust = -0.1, colour = PALETTE$graphite, size = 3.6) +
    ggplot2::scale_colour_manual(values = ESTIMATOR_COLORS, drop = FALSE) +
    ggplot2::scale_fill_manual(values = ESTIMATOR_COLORS, drop = FALSE) +
    ggplot2::labs(x = "estimated ACE", y = "density") +
    headwater_ggtheme()
}

# Two stacked panels: bias vs the swept value, and ESE (or RMSE) vs the swept
# value. One line per estimator. Points are interactive with per-point tooltips.
plot_sweep <- function(sweep_df, sweep_var, metric = c("ese", "rmse")) {
  metric <- match.arg(metric)
  sweep_df$estimator <- factor(sweep_df$estimator, levels = names(ESTIMATOR_COLORS))
  sweep_df$tip_bias <- sprintf(
    "%s\n%s = %.2g\nbias = %.3f",
    sweep_df$estimator, sweep_var, sweep_df$value, sweep_df$bias
  )
  sweep_df$tip_var <- sprintf(
    "%s\n%s = %.2g\n%s = %.3f",
    sweep_df$estimator, sweep_var, sweep_df$value, toupper(metric), sweep_df[[metric]]
  )
  common_scales <- list(
    ggplot2::scale_colour_manual(values = ESTIMATOR_COLORS, drop = FALSE),
    headwater_ggtheme()
  )
  p_bias <- ggplot2::ggplot(sweep_df, ggplot2::aes(value, bias, colour = estimator)) +
    ggplot2::geom_hline(yintercept = 0, colour = PALETTE$gray) +
    ggiraph::geom_line_interactive(
      ggplot2::aes(data_id = estimator), linewidth = 1
    ) +
    ggiraph::geom_point_interactive(
      ggplot2::aes(tooltip = tip_bias, data_id = estimator), size = 2.2
    ) +
    common_scales + ggplot2::labs(x = NULL, y = "Bias")
  p_var <- ggplot2::ggplot(sweep_df, ggplot2::aes(value, .data[[metric]], colour = estimator)) +
    ggiraph::geom_line_interactive(
      ggplot2::aes(data_id = estimator), linewidth = 1
    ) +
    ggiraph::geom_point_interactive(
      ggplot2::aes(tooltip = tip_var, data_id = estimator), size = 2.2
    ) +
    common_scales + ggplot2::labs(x = sweep_var, y = toupper(metric))
  patchwork::wrap_plots(p_bias, p_var, ncol = 1, guides = "collect") &
    ggplot2::theme(legend.position = "bottom")
}
