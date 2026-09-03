test_that("lower_hull matches a hand-worked example", {
  x <- c(1, 2, 3, 4, 5)
  y <- c(5, 2, 3, 2, 5)
  expect_equal(lower_hull(x, y), c(5, 2, 2, 2, 5))
})

test_that("the baseline never exceeds the original spectrum", {
  x <- c(1, 2, 3, 4, 5, 6, 7)
  y <- c(5, 2, 6, 1, 4, 2, 5)
  baseline <- lower_hull(x, y)
  expect_true(all(baseline <= y + 1e-8))
})

test_that("two points just return the straight line between them", {
  x <- c(1, 10)
  y <- c(3, 7)
  expect_equal(lower_hull(x, y), c(3, 7))
})

test_that("fewer than 2 points raises an error", {
  expect_error(lower_hull(1, 5), "at least 2 points")
})
