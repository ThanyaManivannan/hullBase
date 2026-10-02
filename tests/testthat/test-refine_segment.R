x <- seq(0, 10, length.out = 201)

test_that("refine_segment recovers a parabola dome exactly", {
  dome <- 2 * (1 - ((x - 5) / 5)^2)
  expect_equal(refine_segment(x, dome, peak_width = 0.5, noise = 0), dome)
})

test_that("refine_segment recovers a sine arch with the default bend_factor", {
  dome <- 2 * sin(pi * x / 10)
  expect_equal(refine_segment(x, dome, peak_width = 0.5, noise = 0), dome)
})

test_that("refine_segment with bend_factor 1 leaves part of a sine arch", {
  dome <- 2 * sin(pi * x / 10)
  b <- refine_segment(x, dome, peak_width = 0.5, noise = 0, bend_factor = 1,
                      max_depth = 1)
  expect_gt(max(abs(b - dome)), 0.05)
})

test_that("refine_segment extra levels reduce what is left", {
  dome <- 2 * sin(pi * x / 10)
  err <- function(depth) {
    b <- refine_segment(x, dome, peak_width = 0.5, noise = 0,
                        bend_factor = 1, max_depth = depth)
    max(abs(b - dome))
  }
  expect_lt(err(3), err(1))
})

test_that("refine_segment keeps a peak on top of the dome", {
  dome <- 2 * sin(pi * x / 10)
  y <- dome + 1.5 * exp(-((x - 5) / 0.4)^2)
  b <- refine_segment(x, y, peak_width = 2, noise = 0)
  expect_equal(max(y - b), 1.5, tolerance = 0.05)
})

test_that("refine_segment keeps the anchors and stays between chord and data", {
  set.seed(1)
  y <- 2 * sin(pi * x / 10) + exp(-((x - 3) / 0.3)^2) + rnorm(201, 0, 0.02)
  y[1] <- 0
  y[201] <- 0
  b <- refine_segment(x, y, peak_width = 2)
  expect_equal(b[1], y[1])
  expect_equal(b[201], y[201])
  expect_true(all(b <= y + 1e-12))
  expect_true(all(b >= -1e-12))
})

test_that("refine_segment leaves straight and convex data unchanged", {
  expect_equal(refine_segment(x, 0.3 * x + 1, peak_width = 1, noise = 0),
               0.3 * x + 1)
  expect_equal(refine_segment(x, (x - 5)^2, peak_width = 1, noise = 0),
               (x - 5)^2)
})

test_that("refine_segment fixes the flagged segment of a simulated spectrum", {
  set.seed(2)
  sim <- simulate_spectrum(baseline = "concave")
  d <- detect_concave_segments(sim$x, sim$y, peak_width = 300)
  s <- which(d$flagged)
  pts <- d$left[s]:d$right[s]
  plain <- lower_hull(sim$x, sim$y)[pts]
  bent <- refine_segment(sim$x[pts], sim$y[pts], peak_width = 300)
  truth <- sim$baseline[pts]
  expect_lt(sqrt(mean((bent - truth)^2)), sqrt(mean((plain - truth)^2)) / 5)
})

test_that("refine_segment gives the same baseline for reversed input", {
  y <- 2 * sin(pi * x / 10) + exp(-((x - 3) / 0.3)^2)
  b <- refine_segment(x, y, peak_width = 2, noise = 0.01)
  expect_equal(refine_segment(rev(x), rev(y), peak_width = 2, noise = 0.01),
               rev(b))
})

test_that("refine_segment rejects bad input", {
  y <- sin(pi * x / 10)
  expect_error(refine_segment(x, y, peak_width = 0), "greater than 0")
  expect_error(refine_segment(x, y, peak_width = 1, noise = -1), "0 or more")
  expect_error(refine_segment(x, y, peak_width = 1, bend_factor = 0.5),
               "1 or more")
  expect_error(refine_segment(x, y, peak_width = 1, max_depth = 0), "1 or more")
  expect_error(refine_segment(1:4, 1:4, peak_width = 1), "at least 5 points")
})
