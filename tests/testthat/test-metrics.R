test_that("summarise_estimates computes bias/ESE/RMSE/coverage correctly", {
  estimates <- tibble::tibble(
    estimator = rep("Crude", 4),
    estimate  = c(2, 4, 2, 4),   # mean 3
    se        = c(1, 1, 1, 1)
  )
  m <- summarise_estimates(estimates, truth = 2)  # bias = 1
  expect_equal(m$bias, 1)
  expect_equal(m$ese, sd(c(2,4,2,4)))
  expect_equal(m$rmse, sqrt(1^2 + sd(c(2,4,2,4))^2))
  # 95% CI half-width = 1.96; covers 2 when estimate in [0.04, 3.96] -> the 2's do, the 4's don't
  expect_equal(m$coverage, 0.5)
})
