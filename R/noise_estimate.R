#' Estimate a Spectrum's Own Noise Level
#'
#' Estimates the standard deviation of measurement noise directly from the
#' spectrum, using the median absolute deviation (MAD) of the point-to-point
#' differences `diff(y)`. A slowly varying real signal barely changes between
#' adjacent points, so the spread of these differences is dominated by noise
#' rather than signal; the median-based MAD estimator is also robust to any
#' peaks (large jumps) that remain.
#'
#' @param x Numeric vector of wavenumbers. Not used directly in the
#'   calculation, but kept as an argument for interface consistency with
#'   `lower_hull(x, y)`, since both will later be called together from
#'   `estimate_baseline()`.
#' @param y Numeric vector of absorbance values.
#'
#' @return A single numeric value: the estimated noise standard deviation.
#'
#' @details
#' This is a simple, first-pass estimator. Because it only looks at
#' point-to-point differences, a smooth but strongly *curved* baseline with
#' zero real noise can inflate the estimate, since the difference of a curved
#' function is not constant. This limitation is deliberately tested rather
#' than hidden — see `test-noise_estimate.R`.
#'
#' @examples
#' noise_estimate(1:7, c(0, 2, 0, 2, 0, 2, 0))
#'
#' @export

noise_estimate <- function(x, y) {
  if (length(y) < 2) {
    stop("Need at least 2 points to estimate noise.")
  }
  d <- diff(y)
  stats::mad(d) / sqrt(2)
}
