test_that("server assembles params and runs a small Monte Carlo", {
  # Source app.R to define `ui` and `server`. The trailing shinyApp() call just
  # returns an (unlaunched) app object.
  source(file.path("..", "..", "app.R"), local = TRUE)
  shiny::testServer(server, {
    session$setInputs(
      tau = 1, gamma_z = 1, gamma_w = 1, delta = 1, lambda = 0,
      alpha_z = 1, beta_w = 1, alpha_x = 0.5, beta_x = 0.5, a_xu = 1,
      n = 200, M = 20
    )
    expect_equal(params()$tau, 1)
    session$setInputs(run = 1)
    expect_equal(nrow(mc()$metrics), 5)
  })
})

test_that("SWEEP_CHOICES includes n alongside the parameter labels", {
  source(file.path("..", "..", "app.R"), local = TRUE)
  expect_true("n" %in% names(SWEEP_CHOICES))
  for (k in names(PARAM_LABELS)) {
    expect_true(k %in% names(SWEEP_CHOICES), info = k)
  }
})
