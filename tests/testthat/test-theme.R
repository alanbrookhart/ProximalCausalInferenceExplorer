test_that("palette and estimator colors are valid hex", {
  expect_type(HEADWATER, "list")
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", unlist(HEADWATER))))
  expect_setequal(
    names(ESTIMATOR_COLORS),
    c("Proximal (P2SLS)", "Standard, full", "Standard, minimal", "Oracle", "Crude")
  )
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", ESTIMATOR_COLORS)))
})

test_that("bslib theme builds", {
  expect_s3_class(headwater_bs_theme(), "bs_theme")
})
