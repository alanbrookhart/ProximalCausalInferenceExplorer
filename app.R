library(shiny)
library(bslib)

# Pure-logic functions in R/*.R are auto-sourced by Shiny at runtime.

PARAM_LABELS <- c(
  tau     = "τ — true effect (A→Y)",
  gamma_z = "γz — treatment-proxy strength (U→Z)",
  gamma_w = "γw — outcome-proxy strength (U→W)",
  delta   = "δ — residual confounding (U→A, U→Y)",
  lambda  = "λ — proxy invalidity (Z→Y)",
  alpha_z = "αz — Z→A",
  beta_w  = "βw — W→Y",
  alpha_x = "αx — X→A",
  beta_x  = "βx — X→Y",
  a_xu    = "a_xu — X→U"
)

SWEEP_CHOICES <- c(PARAM_LABELS, n = "n — sample size")

sidebar_controls <- function() {
  dp <- default_params()
  tagList(
    tags$div(class = "fw-bold mb-1", "Presets"),
    tags$div(
      class = "d-flex flex-wrap gap-1 mb-3",
      lapply(names(presets()), function(nm)
        actionButton(paste0("preset_", make.names(nm)), nm,
                     class = "btn btn-sm btn-outline-primary"))
    ),
    tags$h6("Primary controls"),
    sliderInput("tau", PARAM_LABELS[["tau"]], -3, 3, dp$tau, step = 0.1),
    sliderInput("gamma_z", PARAM_LABELS[["gamma_z"]], 0, 3, dp$gamma_z, step = 0.1),
    sliderInput("gamma_w", PARAM_LABELS[["gamma_w"]], 0, 3, dp$gamma_w, step = 0.1),
    sliderInput("delta", PARAM_LABELS[["delta"]], 0, 3, dp$delta, step = 0.1),
    sliderInput("lambda", PARAM_LABELS[["lambda"]], 0, 3, dp$lambda, step = 0.1),
    tags$details(
      tags$summary("Advanced (structural edges, sample size)"),
      sliderInput("alpha_z", PARAM_LABELS[["alpha_z"]], 0, 3, dp$alpha_z, step = 0.1),
      sliderInput("beta_w", PARAM_LABELS[["beta_w"]], 0, 3, dp$beta_w, step = 0.1),
      sliderInput("alpha_x", PARAM_LABELS[["alpha_x"]], -2, 2, dp$alpha_x, step = 0.1),
      sliderInput("beta_x", PARAM_LABELS[["beta_x"]], -2, 2, dp$beta_x, step = 0.1),
      sliderInput("a_xu", PARAM_LABELS[["a_xu"]], 0, 3, dp$a_xu, step = 0.1),
      sliderInput("n", "sample size n", 100, 5000, 500, step = 50),
      sliderInput("M", "Monte Carlo reps (Snapshot)", 200, 5000, 1000, step = 100)
    ),
    actionButton("run", "Run simulation", class = "btn btn-primary w-100 mt-2")
  )
}

ui <- page_fluid(
  theme = headwater_bs_theme(),
  tags$head(tags$link(rel = "stylesheet", href = "custom.css")),
  tags$div(
    class = "headwater-header",
    tags$img(src = "headwater-logo.png", alt = "Headwater Science"),
    tags$h2(class = "headwater-title", "Proximal Causal Inference Explorer")
  ),
  layout_sidebar(
    sidebar = sidebar(width = 350, sidebar_controls()),
    ggiraph::girafeOutput("dag", height = "320px"),
    uiOutput("dag_legend"),
    navset_tab(
      nav_panel("About", uiOutput("about")),
      nav_panel(
        "Snapshot",
        ggiraph::girafeOutput("snapshot_plot", height = "300px"),
        DT::DTOutput("metrics_table")
      ),
      nav_panel(
        "Sweep",
        layout_columns(
          col_widths = c(4, 2, 2, 2, 2),
          selectInput("sweep_var", "Sweep which association?",
                      choices = stats::setNames(names(SWEEP_CHOICES), SWEEP_CHOICES),
                      selected = "delta"),
          numericInput("sweep_min", "min", value = 0, step = 0.1),
          numericInput("sweep_max", "max", value = 3, step = 0.1),
          numericInput("sweep_k", "grid points", value = 13, min = 3, max = 40),
          radioButtons("sweep_metric", "2nd panel", c("ESE" = "ese", "RMSE" = "rmse"))
        ),
        actionButton("run_sweep", "Run sweep", class = "btn btn-primary mb-3"),
        ggiraph::girafeOutput("sweep_plot", height = "470px")
      ),
      nav_panel("Methods & formulas", withMathJax(uiOutput("methods")))
    )
  )
)

server <- function(input, output, session) {
  params <- reactive({
    list(
      tau = input$tau, gamma_z = input$gamma_z, gamma_w = input$gamma_w,
      delta = input$delta, lambda = input$lambda, alpha_z = input$alpha_z,
      beta_w = input$beta_w, alpha_x = input$alpha_x, beta_x = input$beta_x,
      a_xu = input$a_xu, alpha0 = 0, sd_u = 1, sd_z = 1, sd_w = 1, sd_y = 1
    )
  })

  # Preset buttons update the sliders.
  lapply(names(presets()), function(nm) {
    observeEvent(input[[paste0("preset_", make.names(nm))]], {
      p <- presets()[[nm]]
      for (k in names(PARAM_LABELS)) updateSliderInput(session, k, value = p[[k]])
    })
  })

  # Give sensible defaults when the user sweeps over n (sample size).
  observeEvent(input$sweep_var, {
    if (isTRUE(input$sweep_var == "n")) {
      updateNumericInput(session, "sweep_min", value = 200)
      updateNumericInput(session, "sweep_max", value = 4000)
      updateNumericInput(session, "sweep_k",   value = 8)
    }
  })

  # Interactive plots via ggiraph: girafe() wraps the ggplot into an htmlwidget
  # with hover tooltips and cross-plot highlighting (data_id maps to estimator
  # in the result plots and to edge param / node name in the DAG).
  .girafe_opts <- list(
    ggiraph::opts_tooltip(opacity = 0.95, css = "background:#ffffff;color:#140298;padding:6px 8px;border:1px solid #0888A8;border-radius:4px;font-size:12px;"),
    ggiraph::opts_hover(css = "stroke-width:3px;"),
    ggiraph::opts_hover_inv(css = "opacity:0.25;"),
    ggiraph::opts_toolbar(saveaspng = FALSE)
  )

  output$dag <- ggiraph::renderGirafe(
    ggiraph::girafe(ggobj = render_dag(params()),
                    width_svg = 8, height_svg = 4.5,
                    options = .girafe_opts)
  )
  output$dag_legend <- renderUI(HTML(dag_legend_html()))

  mc <- eventReactive(input$run, {
    withProgress(message = "Running Monte Carlo simulation...", value = 0.5, {
      run_monte_carlo(params(), n = input$n, M = input$M, seed = 1)
    })
  })

  output$snapshot_plot <- ggiraph::renderGirafe({
    req(mc())
    ggiraph::girafe(ggobj = plot_snapshot(mc()),
                    width_svg = 8, height_svg = 4,
                    options = .girafe_opts)
  })

  output$metrics_table <- DT::renderDT({
    req(mc())
    m <- mc()$metrics
    m <- m[match(names(ESTIMATOR_COLORS), m$estimator), ]
    disp <- data.frame(
      Estimator = m$estimator,
      Bias = round(m$bias, 3),
      `Empirical SE` = round(m$ese, 3),
      `SE ratio` = round(m$ser, 2),
      RMSE = round(m$rmse, 3),
      Coverage = scales::percent(m$coverage, accuracy = 1),
      check.names = FALSE
    )
    DT::datatable(disp, rownames = FALSE,
                  options = list(dom = "t", ordering = FALSE, paging = FALSE))
  })

  sweep_res <- eventReactive(input$run_sweep, {
    grid <- seq(input$sweep_min, input$sweep_max, length.out = input$sweep_k)
    if (input$sweep_var == "n") grid <- round(grid)
    withProgress(message = "Running sweep...", value = 0.5, {
      run_sweep(params(), input$sweep_var, grid, n = input$n, M_sweep = 400, seed = 1)
    })
  })

  output$sweep_plot <- ggiraph::renderGirafe({
    req(sweep_res())
    ggiraph::girafe(
      ggobj = plot_sweep(sweep_res(), input$sweep_var, metric = input$sweep_metric),
      width_svg = 8, height_svg = 6,
      options = .girafe_opts
    )
  })

  output$about <- renderUI(includeMarkdown("www/about.md"))
  # withMathJax() inside renderUI() triggers MathJax to re-typeset the
  # dynamically inserted content; the UI-level withMathJax() only loads the
  # script and does not re-typeset on update.
  output$methods <- renderUI(withMathJax(HTML(methods_html())))
}

shinyApp(ui, server)
