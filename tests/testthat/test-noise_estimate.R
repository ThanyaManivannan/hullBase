test_that("noise_estimate matches a hand worked example", {
  # second differences are 1, -2, 1, 0, 0, so MAD = 1.4826 * 1
  expect_equal(noise_estimate(1:7, c(0, 0, 1, 0, 0, 0, 0)), 1.4826 / sqrt(6))
})

test_that("noise_estimate gives zero on a straight line with no noise", {
  x <- 1:10
  expect_equal(noise_estimate(x, 2 * x + 5), 0)
})

test_that("noise_estimate gives zero on a curved line with no noise", {
  # the old first difference version gave 4.19 here
  x <- 1:10
  expect_equal(noise_estimate(x, x^2), 0)
})

test_that("noise_estimate recovers the sd of pure Gaussian noise", {
  set.seed(1)
  est <- replicate(50, noise_estimate(1:2000, rnorm(2000, 0, 0.1)))
  expect_equal(mean(est), 0.1, tolerance = 0.05)
})

test_that("noise_estimate is not fooled by a curved baseline", {
  set.seed(2)
  x <- seq(0, 10, length.out = 1001)
  y <- 5 * sin(x) + rnorm(1001, 0, 0.01)
  expect_equal(noise_estimate(x, y), 0.01, tolerance = 0.1)
})

test_that("noise_estimate works on every simulated baseline shape", {
  set.seed(3)
  for (shape in c("concave", "linear", "convex", "flat", "mixed")) {
    sim <- simulate_spectrum(baseline = shape, noise_sd = 0.02)
    expect_equal(noise_estimate(sim$x, sim$y), 0.02, tolerance = 0.1)
  }
})

test_that("noise_estimate gives the same answer for shuffled input", {
  set.seed(4)
  sim <- simulate_spectrum(noise_sd = 0.02)
  p <- sample(nrow(sim))
  expect_equal(noise_estimate(sim$x[p], sim$y[p]), noise_estimate(sim$x, sim$y))
})

test_that("noise_estimate errors on fewer than 5 points", {
  expect_error(noise_estimate(1:4, c(1, 2, 3, 4)), "at least 5 points")
})
