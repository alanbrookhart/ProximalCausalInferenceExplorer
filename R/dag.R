# Render the proximal-CI DAG as a ggplot (using ggiraph interactive geoms so it
# can be wrapped with ggiraph::girafe() for hover tooltips in the Shiny app).
# Edge linewidth is proportional to |coefficient|; color encodes edge type;
# residual/invalid edges are dashed.
.NODE_ROLE <- c(
  U = "unmeasured confounder",
  X = "measured confounder",
  Z = "treatment proxy",
  W = "outcome proxy",
  A = "treatment",
  Y = "outcome"
)

render_dag <- function(params) {
  nodes <- data.frame(
    name = c("U", "X", "Z", "W", "A", "Y"),
    x    = c(4.0, 4.0, 1.2, 6.8, 1.6, 6.4),
    y    = c(5.0, 3.3, 2.2, 2.2, 0.5, 0.5),
    latent = c(TRUE, FALSE, FALSE, FALSE, FALSE, FALSE),
    stringsAsFactors = FALSE
  )
  e <- function(from, to, param, type) data.frame(from, to, param, type, stringsAsFactors = FALSE)
  edges <- rbind(
    e("X", "U", "a_xu", "structural"),
    e("X", "A", "alpha_x", "structural"),
    e("X", "Y", "beta_x", "structural"),
    e("U", "Z", "gamma_z", "structural"),
    e("U", "W", "gamma_w", "structural"),
    e("Z", "A", "alpha_z", "structural"),
    e("W", "Y", "beta_w", "structural"),
    e("U", "A", "delta", "residual"),
    e("U", "Y", "delta", "residual"),
    e("Z", "Y", "lambda", "invalid"),
    e("A", "Y", "tau", "ace")
  )
  edges$coef <- vapply(edges$param, function(p) params[[p]], numeric(1))
  edges$x    <- nodes$x[match(edges$from, nodes$name)]
  edges$y    <- nodes$y[match(edges$from, nodes$name)]
  edges$xend <- nodes$x[match(edges$to, nodes$name)]
  edges$yend <- nodes$y[match(edges$to, nodes$name)]

  # Trim endpoints so arrowheads sit on the node boundary, not the center.
  r <- 0.34
  d <- sqrt((edges$xend - edges$x)^2 + (edges$yend - edges$y)^2)
  ux <- (edges$xend - edges$x) / d
  uy <- (edges$yend - edges$y) / d
  edges$x <- edges$x + r * ux; edges$y <- edges$y + r * uy
  edges$xend <- edges$xend - r * ux; edges$yend <- edges$yend - r * uy

  edges$lw  <- 0.4 + 1.8 * pmin(abs(edges$coef), 3) / 3
  edges$lty <- ifelse(edges$type %in% c("residual", "invalid"), "dashed", "solid")
  edges$col <- unname(EDGE_COLORS[edges$type])
  edges$mx  <- (edges$x + edges$xend) / 2
  edges$my  <- (edges$y + edges$yend) / 2
  edges$tooltip <- sprintf("%s &nbsp;%s &rarr; %s &nbsp;coef = %.2g &nbsp;(%s)",
                           edges$param, edges$from, edges$to, edges$coef, edges$type)

  nodes$fill   <- ifelse(nodes$latent, "#F2F2F2", "#D8F3F9")
  nodes$stroke <- ifelse(nodes$latent, HEADWATER$graphite, HEADWATER$ocean)
  nodes$tooltip <- sprintf("%s &mdash; %s%s", nodes$name,
                           .NODE_ROLE[nodes$name],
                           ifelse(nodes$latent, " (unmeasured)", ""))

  ggplot2::ggplot() +
    ggiraph::geom_segment_interactive(
      data = edges,
      ggplot2::aes(x = x, y = y, xend = xend, yend = yend,
                   linewidth = lw, colour = col, linetype = lty,
                   tooltip = tooltip, data_id = param),
      arrow = ggplot2::arrow(length = grid::unit(0.18, "cm"), type = "closed")
    ) +
    ggplot2::geom_text(
      data = edges, ggplot2::aes(x = mx, y = my, label = sprintf("%.2g", coef),
                                 colour = col),
      fontface = "bold", size = 3.1, vjust = -0.4
    ) +
    ggiraph::geom_point_interactive(
      data = nodes,
      ggplot2::aes(x = x, y = y, fill = fill, colour = stroke,
                   tooltip = tooltip, data_id = name),
      size = 17, shape = 21, stroke = 1.3
    ) +
    ggplot2::geom_text(
      data = nodes, ggplot2::aes(x = x, y = y, label = name),
      fontface = "bold", size = 5, colour = HEADWATER$graphite
    ) +
    ggplot2::scale_colour_identity() +
    ggplot2::scale_fill_identity() +
    ggplot2::scale_linewidth_identity() +
    ggplot2::scale_linetype_identity() +
    ggplot2::coord_equal(clip = "off") +
    ggplot2::scale_x_continuous(limits = c(0.2, 7.8), expand = c(0, 0)) +
    ggplot2::scale_y_continuous(limits = c(-0.2, 5.6), expand = c(0, 0)) +
    ggplot2::theme_void()
}
