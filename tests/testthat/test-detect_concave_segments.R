test_that("erode matches a hand worked moving minimum", {
  expect_equal(erode(c(5, 1, 4, 3, 6, 2), m = 1), c(1, 1, 1, 3, 2, 2))
})

test_that("detect_concave_segments flags the arch of a concave baseline", {
  set.seed(1)
  sim <- simulate_spectrum(baseline = "concave")
  d <- detect_concave_segments(sim$x, sim$y, peak_width = 300)
  expect_equal(sum(d$flagged), 1)
  expect_lt(d$x_left[d$flagged], 100)
  expect_gt(d$x_right[d$flagged], 1300)
})

test_that("detect_concave_segments flags nothing on flat, linear or convex baselines", {
  set.seed(2)
  for (shape in c("flat", "linear", "convex")) {
    for (snr in c(30, 25)) {
      for (k in 1:10) {
        sim <- simulate_spectrum(baseline = shape, snr_db = snr)
        d <- detect_concave_segments(sim$x, sim$y, peak_width = 300)
        expect_equal(sum(d$flagged), 0)
      }
    }
  }
})

test_that("detect_concave_segments finds only the dome half of a mixed baseline", {
  set.seed(3)
  sim <- simulate_spectrum(baseline = "mixed")
  d <- detect_concave_segments(sim$x, sim$y, peak_width = 300)
  expect_equal(sum(d$flagged), 1)
  expect_lt(d$x_left[d$flagged], 700)
})

test_that("detect_concave_segments ignores a single peak narrower than peak_width", {
  set.seed(4)
  x <- 0:1000
  y <- exp(-((x - 500) / 20)^2) + rnorm(1001, 0, 0.01)
  d <- detect_concave_segments(x, y, peak_width = 150)
  expect_equal(sum(d$flagged), 0)
})

test_that("detect_concave_segments works on noise free data", {
  sim <- simulate_spectrum(baseline = "flat", noise_sd = 0)
  d <- detect_concave_segments(sim$x, sim$y, peak_width = 300)
  expect_equal(sum(d$flagged), 0)
})

test_that("detect_concave_segments never flags a segment shorter than 2m + 3 points", {
  set.seed(5)
  sim <- simulate_spectrum(baseline = "concave")
  d <- detect_concave_segments(sim$x, sim$y, peak_width = 300)
  short <- d$n_points < 2 * attr(d, "m") + 3
  expect_true(any(short))
  expect_false(any(d$flagged[short]))
})

test_that("detect_concave_segments segment ends are hull vertices", {
  set.seed(6)
  sim <- simulate_spectrum(baseline = "concave")
  d <- detect_concave_segments(sim$x, sim$y, peak_width = 300)
  b <- lower_hull(sim$x, sim$y)
  expect_equal(sim$y[d$left], b[d$left])
  expect_equal(sim$y[d$right], b[d$right])
})

test_that("detect_concave_segments uses the stated threshold and window", {
  set.seed(7)
  sim <- simulate_spectrum(baseline = "flat")
  d <- detect_concave_segments(sim$x, sim$y, peak_width = 300, noise = 0.05)
  expect_equal(attr(d, "threshold"), 2 * 0.05 * sqrt(2 * log(1401)))
  expect_equal(attr(d, "m"), 150)
})

test_that("detect_concave_segments estimates the noise itself when not given", {
  set.seed(8)
  sim <- simulate_spectrum(baseline = "concave")
  expect_equal(
    detect_concave_segments(sim$x, sim$y, peak_width = 300),
    detect_concave_segments(sim$x, sim$y, peak_width = 300,
                            noise = noise_estimate(sim$x, sim$y))
  )
})

test_that("detect_concave_segments gives the same answer for reversed input", {
  set.seed(9)
  sim <- simulate_spectrum(baseline = "concave")
  d1 <- detect_concave_segments(sim$x, sim$y, peak_width = 300)
  d2 <- detect_concave_segments(rev(sim$x), rev(sim$y), peak_width = 300)
  expect_equal(d1, d2)
})

test_that("detect_concave_segments rejects bad input", {
  sim <- simulate_spectrum(noise_sd = 0.01)
  expect_error(detect_concave_segments(sim$x, sim$y, peak_width = 0),
               "greater than 0")
  expect_error(detect_concave_segments(sim$x, sim$y, peak_width = "wide"),
               "greater than 0")
  expect_error(detect_concave_segments(sim$x, sim$y, peak_width = 300,
                                       noise = -1), "0 or more")
  expect_error(detect_concave_segments(1:4, 1:4, peak_width = 2),
               "at least 5 points")
})
