test_that("lower_hull matches a hand worked example", {
  expect_equal(lower_hull(1:5, c(5, 2, 3, 2, 5)), c(5, 2, 2, 2, 5))
})

test_that("lower_hull baseline never goes above the spectrum", {
  set.seed(1)
  for (k in 1:50) {
    x <- seq(0, 100, length.out = 200)
    y <- rnorm(200)
    expect_true(all(lower_hull(x, y) <= y + 1e-12))
  }
})

test_that("lower_hull baseline is convex and touches the data at both ends", {
  set.seed(2)
  x <- seq(0, 100, length.out = 300)
  y <- rnorm(300) - 0.01 * (x - 50)^2
  b <- lower_hull(x, y)
  slopes <- diff(b) / diff(x)
  expect_true(all(diff(slopes) >= -1e-9))
  expect_equal(b[1], y[1])
  expect_equal(b[300], y[300])
})

test_that("lower_hull agrees with the hull from grDevices::chull", {
  set.seed(3)
  for (k in 1:50) {
    n <- 100
    x <- seq(0, 100, length.out = n)
    y <- rnorm(n) + 0.01 * (x - 50)^2
    ch <- grDevices::chull(x, y)
    chord <- approx(c(x[1], x[n]), c(y[1], y[n]), xout = x[ch])$y
    low <- sort(ch[y[ch] <= chord + 1e-12])
    expect_equal(lower_hull(x, y), approx(x[low], y[low], xout = x)$y)
  }
})

test_that("lower_hull R and C++ versions find the same vertices", {
  set.seed(4)
  for (k in 1:50) {
    x <- seq(0, 100, length.out = 150)
    y <- rnorm(150)
    expect_identical(lower_hull_cpp(x, y), lower_hull_r(x, y))
  }
})

test_that("lower_hull follows straight and convex data exactly", {
  x <- seq(0, 10, length.out = 101)
  expect_equal(lower_hull(x, 2 * x + 1), 2 * x + 1)
  expect_equal(lower_hull(x, x^2), x^2)
})

test_that("lower_hull only gives the chord under a concave arch (known limitation)", {
  x <- seq(0, 10, length.out = 101)
  expect_equal(lower_hull(x, sin(pi * x / 10)), rep(0, 101))
})

test_that("lower_hull returns the baseline in the input order", {
  x <- seq(4000, 400, by = -2)
  y <- sin(x / 300) + (x / 4000)^2
  b <- lower_hull(x, y)
  expect_equal(b, rev(lower_hull(rev(x), rev(y))))
  p <- sample(length(x))
  expect_equal(lower_hull(x[p], y[p]), b[p])
})

test_that("lower_hull gives clear errors for bad input", {
  expect_error(lower_hull(1:6, 1:5), "same length")
  expect_error(lower_hull(1:5, c(1, NA, 1, 1, 1)), "NA, NaN or Inf")
  expect_error(lower_hull(c(1, 2, 2, 3, 4), 1:5), "repeated")
  expect_error(lower_hull(1:4, 1:4), "at least 5 points")
})
