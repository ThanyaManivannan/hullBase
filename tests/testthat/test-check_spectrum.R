test_that("check_spectrum sorts by x and keeps y matched to its x", {
  res <- check_spectrum(c(3, 1, 2, 5, 4), c(30, 10, 20, 50, 40))
  expect_equal(res$x, c(1, 2, 3, 4, 5))
  expect_equal(res$y, c(10, 20, 30, 40, 50))
})

test_that("check_spectrum ord puts sorted values back in the original order", {
  x <- seq(4000, 400, by = -2)
  y <- sin(x / 300)
  res <- check_spectrum(x, y)
  back <- numeric(length(x))
  back[res$ord] <- res$y
  expect_equal(back, y)
})

test_that("check_spectrum returns the typical step h", {
  res <- check_spectrum(seq(400, 4000, by = 2), rep(0, 1801))
  expect_equal(res$h, 2)
})

test_that("check_spectrum accepts a real instrument grid without a warning", {
  x <- seq(3999.64, 399.19, length.out = 1868)
  expect_no_warning(check_spectrum(x, rep(0, 1868)))
})

test_that("check_spectrum errors on non numeric input", {
  expect_error(check_spectrum(letters[1:5], 1:5), "numeric")
})

test_that("check_spectrum errors when x and y have different lengths", {
  expect_error(check_spectrum(1:6, 1:5), "same length")
})

test_that("check_spectrum errors on fewer than 5 points", {
  expect_error(check_spectrum(1:4, 1:4), "at least 5 points")
})

test_that("check_spectrum errors on NA, NaN and Inf", {
  expect_error(check_spectrum(1:5, c(1, NA, 1, 1, 1)), "NA, NaN or Inf")
  expect_error(check_spectrum(c(1, 2, NaN, 4, 5), 1:5), "NA, NaN or Inf")
  expect_error(check_spectrum(1:5, c(1, 1, Inf, 1, 1)), "NA, NaN or Inf")
})

test_that("check_spectrum errors on repeated x values", {
  expect_error(check_spectrum(c(1, 2, 2, 3, 4), 1:5), "repeated")
})

test_that("check_spectrum warns when x is unevenly spaced", {
  expect_warning(check_spectrum(c(1, 2, 3, 5, 6), 1:5), "not evenly spaced")
})
