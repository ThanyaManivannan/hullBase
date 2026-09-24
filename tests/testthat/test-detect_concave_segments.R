test_that("detect_concave_segments flags a segment with a hidden peak", {
  result <- detect_concave_segments(x = 1:5, y = c(0, 0.5, 0.6, 0.5, 0), noise = 0.1)
  expect_equal(nrow(result), 1)
  expect_equal(result$left_idx, 1)
  expect_equal(result$right_idx, 5)
})

test_that("detect_concave_segments does not flag a small bump within noise", {
  result <- detect_concave_segments(x = 1:5, y = c(0, 0.05, 0.06, 0.05, 0), noise = 0.1)
  expect_equal(nrow(result), 0)
})

test_that("detect_concave_segments returns nothing for two points with no gap between", {
  result <- detect_concave_segments(x = c(1, 2), y = c(0, 0), noise = 0.1)
  expect_equal(nrow(result), 0)
})

test_that("detect_concave_segments flagged boundaries are real hull vertices", {
  x <- 1:5
  y <- c(0, 0.5, 0.6, 0.5, 0)
  result <- detect_concave_segments(x = x, y = y, noise = 0.1)
  baseline <- lower_hull(x, y)
  expect_equal(y[result$left_idx], baseline[result$left_idx])
  expect_equal(y[result$right_idx], baseline[result$right_idx])
})

test_that("detect_concave_segments errors on fewer than two points", {
  expect_error(detect_concave_segments(x = 1, y = 1, noise = 0.1))
})
