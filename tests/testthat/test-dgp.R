test_that("default_params has all required fields", {
  p <- default_params()
  for (k in c("tau","gamma_z","gamma_w","delta","lambda","alpha_z","beta_w",
              "alpha_x","beta_x","a_xu","alpha0","sd_u","sd_z","sd_w","sd_y")) {
    expect_true(k %in% names(p), info = k)
  }
})

test_that("simulate_data returns correct shape and types", {
  set.seed(1)
  d <- simulate_data(500, default_params())
  expect_equal(nrow(d), 500)
  expect_setequal(names(d), c("X","U","Z","W","A","Y"))
  expect_true(all(d$A %in% c(0, 1)))
  expect_type(d$Y, "double")
})

test_that("simulate_data is reproducible under a fixed seed", {
  set.seed(7); d1 <- simulate_data(100, default_params())
  set.seed(7); d2 <- simulate_data(100, default_params())
  expect_identical(d1, d2)
})

test_that("stronger treatment-proxy strength increases cor(Z, U)", {
  set.seed(3)
  weak <- simulate_data(5000, modifyList(default_params(), list(gamma_z = 0.2)))
  strong <- simulate_data(5000, modifyList(default_params(), list(gamma_z = 3)))
  expect_lt(cor(weak$Z, weak$U), cor(strong$Z, strong$U))
})
