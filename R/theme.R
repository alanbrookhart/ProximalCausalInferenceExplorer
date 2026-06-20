# ==============================================================================
# Script: R/theme.R
# Author: Alan Brookhart (alan.brookhart@duke.edu)
# Date: June 2026
# Version: 1.0.0
#
# Description:
#   Visual theme for the Proximal Causal Inference Explorer: the application
#   color palette and the derived color maps used across the app. Defines the
#   bslib Bootstrap theme and the shared ggplot theme so the page chrome and the
#   plots use one consistent navy / steel-blue / gold palette.
#
# Core Architecture:
#   - PALETTE: named application colors (navy, sidebar, steel, gold, ...).
#   - ESTIMATOR_COLORS / EDGE_COLORS: semantic color maps consumed by plots.R,
#     dag.R, and ui_text.R (keep the DAG legend in ui_text.R in sync with
#     EDGE_COLORS).
#   - headwater_bs_theme(): bslib BS5 theme; page chrome colors live in
#     www/custom.css to avoid a network dependency on web fonts.
#   - headwater_ggtheme(): shared ggplot2 theme (sans-serif, bottom legend).
#
# Usage:
#   Sourced automatically by Shiny at runtime; not run directly.
# ==============================================================================

# Application palette (navy / steel-blue / gold).
PALETTE <- list(
  navy      = "#003366",  # header bar, headings, hero estimator, A->Y edge
  sidebar   = "#001A57",  # dark sidebar background
  steel     = "#4682B4",  # accents, active tabs, links, structural edges, Oracle
  gold      = "#C99700",  # primary buttons, Standard-full, residual edge
  gold_dark = "#A67600",  # button hover, Standard-minimal
  gray      = "#8A8D91",  # Crude estimator, zero-reference lines
  firebrick = "#B22222",  # invalid-proxy edge (semantically "bad")
  graphite  = "#333333",  # body text, node labels
  light     = "#F8F9FA"   # content-area background
)

# One color per estimator, reused across plots and the metrics table.
ESTIMATOR_COLORS <- c(
  "Proximal (P2SLS)"  = PALETTE$navy,
  "Standard, full"    = PALETTE$gold,
  "Standard, minimal" = PALETTE$gold_dark,
  "Oracle"            = PALETTE$steel,
  "Crude"             = PALETTE$gray
)

# DAG edge colors by semantic type.
EDGE_COLORS <- c(
  structural = PALETTE$steel,
  ace        = PALETTE$navy,
  residual   = PALETTE$gold,
  invalid    = PALETTE$firebrick
)

# bslib Bootstrap 5 theme. Fonts and chrome colors are handled in
# www/custom.css to avoid a network dependency on Google Fonts.
headwater_bs_theme <- function() {
  bslib::bs_theme(
    version = 5,
    primary = PALETTE$gold,
    secondary = PALETTE$navy
  )
}

# Shared ggplot theme.
headwater_ggtheme <- function() {
  ggplot2::theme_minimal(
    base_size = 13,
    base_family = "Helvetica"
  ) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", color = PALETTE$navy),
      legend.position = "bottom",
      legend.title = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank()
    )
}
