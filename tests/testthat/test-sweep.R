test_that("run_sweep returns one row per (grid value x estimator)", {
  vals <- c(0, 1, 2)
  s <- run_sweep(default_params(), "delta", vals, n = 300, M_sweep = 20, seed = 1)
  expect_equal(nrow(s), length(vals) * 5)
  expect_true(all(c("value","estimator","bias","ese","rmse","coverage") %in% names(s)))
  expect_setequal(unique(s$value), vals)
})

test_that("standard estimator's |bias| grows with delta", {
  vals <- c(0, 1, 2)
  s <- run_sweep(default_params(), "delta", vals, n = 4000, M_sweep = 40, seed = 2)
  b <- s[s$estimator == "Standard, minimal", ]
  b <- b[order(b$value), ]
  expect_true(abs(b$bias[3]) > abs(b$bias[1]))
})

test_that("sweeping n changes sample size, not a parameter", {
  s <- run_sweep(default_params(), "n", c(200, 400), n = 999, M_sweep = 15, seed = 3)
  expect_setequal(unique(s$value), c(200, 400))
})
