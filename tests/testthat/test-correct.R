test_that("correct returns a BaselineModel with all its fields", {
  set.seed(1)
  sim <- simulate_spectrum(baseline = "concave")
  fit <- correct(sim$x, sim$y, peak_width = 300)
  expect_s3_class(fit, "BaselineModel")
  expect_named(fit, c("x", "y", "baseline", "corrected", "rubberband", "noise",
                      "peak_width", "method", "segments", "call"))
  expect_length(fit$baseline, nrow(sim))
  expect_true(is.call(fit$call))
})

test_that("correct gives corrected plus baseline equal to y", {
  set.seed(2)
  sim <- simulate_spectrum(baseline = "mixed")
  fit <- correct(sim, peak_width = 300)
  expect_equal(fit$corrected + fit$baseline, sim$y)
})

test_that("correct with method rubberband matches a hand worked example", {
  fit <- correct(1:5, c(5, 2, 3, 2, 5), method = "rubberband")
  expect_equal(fit$baseline, c(5, 2, 2, 2, 5))
  expect_equal(fit$corrected, c(0, 0, 1, 0, 0))
  expect_null(fit$segments)
})

test_that("correct keeps the plain rubberband baseline for comparison", {
  set.seed(3)
  sim <- simulate_spectrum(baseline = "concave")
  fit <- correct(sim, peak_width = 300)
  expect_equal(fit$rubberband, lower_hull(sim$x, sim$y))
})

test_that("correct baseline never goes above the spectrum", {
  set.seed(4)
  for (shape in c("concave", "mixed", "flat")) {
    sim <- simulate_spectrum(baseline = shape)
    fit <- correct(sim, peak_width = 300)
    expect_true(all(fit$corrected >= -1e-12))
  }
})

test_that("correct improves a lot on concave and mixed baselines", {
  set.seed(5)
  for (shape in c("concave", "mixed")) {
    sim <- simulate_spectrum(baseline = shape)
    fit <- correct(sim, peak_width = 300)
    rmse_adaptive <- sqrt(mean((fit$baseline - sim$baseline)^2))
    rmse_plain <- sqrt(mean((fit$rubberband - sim$baseline)^2))
    expect_lt(rmse_adaptive, rmse_plain / 5)
  }
})

test_that("correct changes nothing on flat, linear and convex baselines", {
  set.seed(6)
  for (shape in c("flat", "linear", "convex")) {
    sim <- simulate_spectrum(baseline = shape)
    fit <- correct(sim, peak_width = 300)
    expect_equal(fit$baseline, fit$rubberband)
  }
})

test_that("correct returns results in the input order", {
  set.seed(7)
  sim <- simulate_spectrum(baseline = "concave")
  fit <- correct(sim$x, sim$y, peak_width = 300)
  rev_fit <- correct(rev(sim$x), rev(sim$y), peak_width = 300)
  expect_equal(rev_fit$baseline, rev(fit$baseline))
})

test_that("correct data frame method matches the default method", {
  set.seed(8)
  sim <- simulate_spectrum(baseline = "concave")
  expect_equal(correct(sim, peak_width = 300)$baseline,
               correct(sim$x, sim$y, peak_width = 300)$baseline)
  expect_error(correct(data.frame(a = 1:5, b = 1:5)), "columns named x and y")
})

test_that("correct needs peak_width for the adaptive method", {
  sim <- simulate_spectrum(noise_sd = 0.01)
  expect_error(correct(sim), "peak_width")
})

test_that("print shows a short overview and returns the object invisibly", {
  set.seed(9)
  sim <- simulate_spectrum(baseline = "concave")
  fit <- correct(sim, peak_width = 300)
  expect_output(print(fit), "local bending")
  expect_output(print(fit), "concave segments refined: 1 of")
  expect_output(shown <- withVisible(print(fit)))
  expect_false(shown$visible)
})

test_that("summary reports the refined segment and the lift", {
  set.seed(10)
  sim <- simulate_spectrum(baseline = "concave")
  s <- summary(correct(sim, peak_width = 300))
  expect_s3_class(s, "summary.BaselineModel")
  expect_equal(nrow(s$flagged), 1)
  expect_gt(s$max_lift, 0.5)
  expect_gt(s$area_lifted, 0)
  expect_output(print(s), "segments refined")
})

test_that("summary of plain rubberband has no lift", {
  sim <- simulate_spectrum(noise_sd = 0.01)
  s <- summary(correct(sim, method = "rubberband"))
  expect_equal(s$max_lift, 0)
  expect_equal(s$area_lifted, 0)
})

test_that("plot draws both views without error", {
  set.seed(11)
  sim <- simulate_spectrum(baseline = "concave")
  fit <- correct(sim, peak_width = 300)
  grDevices::pdf(NULL)
  expect_no_error(plot(fit))
  expect_no_error(plot(fit, which = "corrected"))
  expect_invisible(plot(fit))
  grDevices::dev.off()
})
test_that("correct rejects bad settings", {
  sim <- simulate_spectrum(noise_sd = 0.01)
  expect_error(correct(sim, peak_width = 300, bend_factor = 0.5), "1 or more")
  expect_error(correct(sim, peak_width = 300, max_depth = 0), "1 or more")
  expect_error(correct(sim, method = "rubberband", noise = -1), "0 or more")
})
