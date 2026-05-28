test_that("ui text helpers return non-empty character strings", {
  expect_type(dag_legend_html(), "character")
  expect_true(nchar(dag_legend_html()) > 0)
  expect_type(methods_html(), "character")
  expect_match(methods_html(), "ivreg|bridge|proximal", ignore.case = TRUE)
})
