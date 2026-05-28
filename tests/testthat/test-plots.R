test_that("plot_snapshot returns a ggplot", {
  mc <- run_monte_carlo(default_params(), n = 200, M = 30, seed = 1)
  expect_s3_class(plot_snapshot(mc), "ggplot")
})

test_that("plot_sweep returns a patchwork/ggplot for both metric choices", {
  s <- run_sweep(default_params(), "delta", c(0, 1, 2), n = 200, M_sweep = 15, seed = 1)
  expect_s3_class(plot_sweep(s, "delta", metric = "ese"), "ggplot")
  expect_s3_class(plot_sweep(s, "delta", metric = "rmse"), "ggplot")
})
