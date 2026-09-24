test_that("refine_segment shrinks a symmetric hump correctly", {
  result <- refine_segment(x = 1:5, y = c(0, 2, 3, 2, 0), noise = 0.6)
  expect_equal(result, c(0, 1, 1.5, 1, 0))
})

test_that("refine_segment never exceeds the original spectrum", {
  y <- c(0, 2, 3, 2, 0)
  result <- refine_segment(x = 1:5, y = y, noise = 0.01)
  expect_true(all(result <= y))
})

test_that("refine_segment keeps the two anchor points fixed", {
  y <- c(0, 2, 3, 2, 0)
  result <- refine_segment(x = 1:5, y = y, noise = 0.01)
  expect_equal(result[1], y[1])
  expect_equal(result[length(result)], y[length(y)])
})

test_that("refine_segment respects the max_iter safety cap", {
  result <- refine_segment(x = 1:5, y = c(0, 2, 3, 2, 0), noise = 0, max_iter = 1)
  expect_equal(result, c(0, 1.5, 2.0, 1.5, 0))
})

test_that("refine_segment does nothing to a two point segment", {
  result <- refine_segment(x = c(1, 2), y = c(0, 0), noise = 0.01)
  expect_equal(result, c(0, 0))
})
