# Headwater Science brand palette
HEADWATER <- list(
  pedestal = "#73F0E9", aqua = "#0FB5D2", ocean = "#0888A8",
  azure = "#4166FF", navy = "#140298", pearl = "#F0F0F0",
  silver = "#ADADAD", graphite = "#575757",
  orange = "#FD8524", crimson = "#A5052D", forest = "#495102",
  # Coral used for the side panel background.
  coral = "#FFAB91"
)

# One color per estimator, reused across plots and the metrics table.
ESTIMATOR_COLORS <- c(
  "Proximal (P2SLS)"  = HEADWATER$navy,
  "Standard, full"    = HEADWATER$crimson,
  "Standard, minimal" = HEADWATER$orange,
  "Oracle"            = HEADWATER$forest,
  "Crude"             = HEADWATER$silver
)

# DAG edge colors by semantic type.
EDGE_COLORS <- c(
  structural = HEADWATER$ocean,
  ace        = HEADWATER$navy,
  residual   = HEADWATER$orange,
  invalid    = HEADWATER$crimson
)

# bslib Bootstrap 5 theme. Fonts are handled in www/custom.css to avoid a
# network dependency on Google Fonts.
headwater_bs_theme <- function() {
  bslib::bs_theme(
    version = 5,
    primary = HEADWATER$ocean,
    secondary = HEADWATER$navy
  )
}

# Shared ggplot theme.
headwater_ggtheme <- function() {
  ggplot2::theme_minimal(base_size = 13) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", color = HEADWATER$graphite),
      legend.position = "bottom",
      legend.title = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank()
    )
}
