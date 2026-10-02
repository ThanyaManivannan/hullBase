test_that("erode_cpp matches a hand worked moving minimum", {
  expect_equal(erode_cpp(c(5, 1, 4, 3, 6, 2), 1), c(1, 1, 1, 3, 2, 2))
})

test_that("erode_cpp gives exactly the same result as the R version", {
  set.seed(1)
  for (k in 1:100) {
    g <- round(rnorm(sample(1:300, 1)), 1)
    m <- sample(0:400, 1)
    expect_identical(erode_cpp(g, m), erode(g, m))
  }
})

test_that("erode_cpp handles the edge cases", {
  expect_equal(erode_cpp(c(3, 1, 2), 0), c(3, 1, 2))
  expect_equal(erode_cpp(c(3, 1, 2), 10), c(1, 1, 1))
  expect_equal(erode_cpp(7, 2), 7)
})
