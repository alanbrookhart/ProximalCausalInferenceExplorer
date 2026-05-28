test_that("render_dag returns a ggplot for default and extreme params", {
  expect_s3_class(render_dag(default_params()), "ggplot")
  extreme <- modifyList(default_params(),
    list(tau = -3, gamma_z = 0, gamma_w = 3, delta = 3, lambda = 3))
  expect_s3_class(render_dag(extreme), "ggplot")
})

test_that("render_dag can be built without error", {
  p <- render_dag(default_params())
  expect_silent(ggplot2::ggplot_build(p))
})
