test_that("fit_all returns five estimators with finite estimate and se", {
  set.seed(1)
  d <- simulate_data(2000, default_params())
  fa <- fit_all(d)
  expect_equal(nrow(fa), 5)
  expect_setequal(fa$estimator,
    c("Proximal (P2SLS)", "Standard, full", "Standard, minimal", "Oracle", "Crude"))
  expect_true(all(is.finite(fa$estimate)))
  expect_true(all(is.finite(fa$se) & fa$se > 0))
})

test_that("oracle recovers tau at large n", {
  set.seed(2)
  p <- modifyList(default_params(), list(tau = 1.3, delta = 1, lambda = 1))
  d <- simulate_data(2e5, p)
  fa <- fit_all(d)
  oracle <- fa$estimate[fa$estimator == "Oracle"]
  expect_lt(abs(oracle - p$tau), 0.03)
})
