.est <- function(p, n = 2e5) {
  d <- simulate_data(n, p)
  fa <- fit_all(d)
  stats::setNames(fa$estimate, fa$estimator)
}

test_that("presets() exposes the four named scenarios", {
  expect_setequal(
    names(presets()),
    c("Valid proxies", "Residual confounding", "Invalid proxy", "Weak proxies")
  )
})

test_that("valid proxies: proximal/standard/oracle all unbiased, crude biased", {
  set.seed(11)
  p <- presets()[["Valid proxies"]]
  e <- .est(p)
  for (nm in c("Proximal (P2SLS)", "Standard, full", "Standard, minimal", "Oracle")) {
    expect_lt(abs(e[[nm]] - p$tau), 0.05)
  }
  expect_gt(abs(e[["Crude"]] - p$tau), 0.10)
})

test_that("residual confounding: standard biased, proximal & oracle unbiased", {
  set.seed(12)
  p <- presets()[["Residual confounding"]]
  e <- .est(p)
  expect_lt(abs(e[["Proximal (P2SLS)"]] - p$tau), 0.05)
  expect_lt(abs(e[["Oracle"]] - p$tau), 0.05)
  expect_gt(abs(e[["Standard, full"]] - p$tau), 0.15)
  expect_gt(abs(e[["Standard, minimal"]] - p$tau), 0.15)
})

test_that("invalid proxy: proximal biased, oracle still unbiased", {
  set.seed(13)
  p <- presets()[["Invalid proxy"]]
  e <- .est(p)
  expect_gt(abs(e[["Proximal (P2SLS)"]] - p$tau), 0.15)
  expect_lt(abs(e[["Oracle"]] - p$tau), 0.05)
})
