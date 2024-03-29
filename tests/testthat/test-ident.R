test_that("zero length inputs return correct clases", {
  expect_s3_class(ident(), "ident")
})

test_that("ident quotes", {
  con <- simulate_dbi()
  x1 <- ident("x")

  expect_equal(escape(x1, con = con), sql('`x`'))
  expect_equal(as.sql(x1), x1)
})

test_that("can format ident", {
  expect_snapshot(ident())
})
