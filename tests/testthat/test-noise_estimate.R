test_that("noise_estimate matches a hand-worked alternating pattern", {
  y <- c(0, 2, 0, 2, 0, 2, 0)
  x <- seq_along(y)
  expect_equal(noise_estimate(x, y), 2.096713, tolerance = 1e-6)
})

test_that("a perfectly linear, noise-free spectrum gives zero", {
  x <- 1:10
  y <- 2 * x + 5
  expect_equal(noise_estimate(x, y), 0)
})

test_that("a curved, noise-free spectrum inflates the estimate - known limitation", {
  x <- 1:10
  y <- x^2
  # No real noise here at all, yet the estimator reports a clearly nonzero
  # value, because diff() of a curved function isn't constant.
  expect_gt(noise_estimate(x, y), 1)
})

test_that("fewer than 2 points raises an error", {
  expect_error(noise_estimate(1, 5), "at least 2 points")
})
