test_that("simulate_spectrum returns a data frame with the five columns", {
  sim <- simulate_spectrum()
  expect_s3_class(sim, "data.frame")
  expect_named(sim, c("x", "y", "baseline", "signal", "noise"))
  expect_equal(nrow(sim), 1401)
})

test_that("simulate_spectrum y is exactly signal plus baseline plus noise", {
  set.seed(1)
  sim <- simulate_spectrum(baseline = "mixed")
  expect_equal(sim$y, sim$signal + sim$baseline + sim$noise)
})

test_that("simulate_spectrum with noise_sd = 0 has no noise", {
  sim <- simulate_spectrum(noise_sd = 0)
  expect_equal(sim$y, sim$signal + sim$baseline)
  expect_true(all(sim$noise == 0))
})

test_that("simulate_spectrum peak at 800 has Zhang's height of 4", {
  sim <- simulate_spectrum(noise_sd = 0)
  expect_equal(sim$signal[sim$x == 800], 4, tolerance = 1e-6)
})

test_that("simulate_spectrum concave baseline matches Zhang's sin(pi v / 1200)", {
  sim <- simulate_spectrum(x = 0:1200, baseline = "concave", noise_sd = 0)
  expect_equal(sim$baseline, sin(pi * (0:1200) / 1200))
})

test_that("simulate_spectrum baseline shapes have the right curvature sign", {
  d2 <- function(shape) {
    diff(simulate_spectrum(baseline = shape, noise_sd = 0)$baseline,
         differences = 2)
  }
  expect_true(all(d2("concave") < 0))
  expect_true(all(d2("convex") > 0))
  expect_true(all(abs(d2("linear")) < 1e-12))
  expect_true(all(d2("flat") == 0))
})

test_that("simulate_spectrum noise sd follows the SNR formula", {
  set.seed(2)
  sim <- simulate_spectrum(x = seq(0, 1400, by = 0.1), snr_db = 30)
  expected <- sqrt(mean(sim$signal^2) / 10^(30 / 10))
  expect_equal(attr(sim, "noise_sd"), expected)
  expect_equal(sd(sim$noise), expected, tolerance = 0.05)
})

test_that("simulate_spectrum noise_sd overrides snr_db", {
  sim <- simulate_spectrum(noise_sd = 0.01, snr_db = 5)
  expect_equal(attr(sim, "noise_sd"), 0.01)
})

test_that("simulate_spectrum gives the same spectrum after the same set.seed", {
  set.seed(3)
  a <- simulate_spectrum()
  set.seed(3)
  b <- simulate_spectrum()
  expect_identical(a, b)
})

test_that("simulate_spectrum default peaks stay away from both ends", {
  sim <- simulate_spectrum(noise_sd = 0)
  expect_lt(sim$signal[1], 1e-3)
  expect_lt(sim$signal[nrow(sim)], 1e-3)
})

test_that("simulate_spectrum rejects bad input", {
  expect_error(simulate_spectrum(baseline = "wavy"))
  expect_error(simulate_spectrum(noise_sd = -1), "0 or more")
  expect_error(simulate_spectrum(peaks = data.frame(h = 1)),
               "height, centre and width")
  expect_error(simulate_spectrum(peaks = data.frame(height = 1, centre = 5,
                                                    width = 0)),
               "greater than 0")
})
