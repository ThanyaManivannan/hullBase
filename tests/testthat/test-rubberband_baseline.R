test_that("correct.rubberband_baseline matches a hand-worked example", {
  model <- rubberband_baseline(c(1, 2, 3, 4, 5), c(5, 2, 3, 2, 5))
  # baseline is c(5, 2, 2, 2, 5), so the corrected spectrum is y - baseline
  expect_equal(correct(model), c(0, 0, 1, 0, 0))
})

test_that("the corrected spectrum is never negative", {
  model <- rubberband_baseline(c(1, 2, 3, 4, 5, 6, 7), c(5, 2, 6, 1, 4, 2, 5))
  corrected <- correct(model)
  expect_true(all(corrected >= -1e-8))
})

test_that("rubberband_baseline sorts unsorted input by x", {
  model <- rubberband_baseline(c(3, 1, 2), c(10, 5, 5))
  expect_equal(model$x, c(1, 2, 3))
})

test_that("fewer than 2 points raises an error", {
  expect_error(rubberband_baseline(1, 5), "at least 2 points")
})
