test_that("run_monte_carlo returns estimates, metrics, and truth", {
  res <- run_monte_carlo(default_params(), n = 300, M = 30, seed = 1)
  expect_setequal(names(res), c("estimates", "metrics", "truth"))
  expect_equal(res$truth, default_params()$tau)
  expect_equal(nrow(res$metrics), 5)
  expect_equal(nrow(res$estimates), 5 * 30)
  expect_true(all(c("bias","ese","ser","rmse","coverage") %in% names(res$metrics)))
})

test_that("run_monte_carlo is reproducible under a seed", {
  a <- run_monte_carlo(default_params(), n = 200, M = 20, seed = 5)
  b <- run_monte_carlo(default_params(), n = 200, M = 20, seed = 5)
  expect_equal(a$metrics, b$metrics)
})
