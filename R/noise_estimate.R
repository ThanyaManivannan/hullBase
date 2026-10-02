#' Estimate a Spectrum's Own Noise Level
#'
#' Estimates the standard deviation of the measurement noise directly from
#' the spectrum, using the median absolute deviation (MAD) of the second
#' differences of `y`.
#'
#' @param x Numeric vector of wavenumbers. Used to sort the spectrum
#'   before differencing.
#' @param y Numeric vector of absorbance values, the same length as `x`.
#'
#' @return A single number: the estimated noise standard deviation.
#'
#' @details
#' The second difference `y[i+1] - 2*y[i] + y[i-1]` removes any straight
#' line trend exactly, and turns a smooth curved baseline into an almost
#' constant value, which the MAD removes when it subtracts the median.
#' What remains is noise. Each second difference combines three noise
#' values with weights 1, -2 and 1, so its variance is
#' `(1 + 4 + 1) * sigma^2 = 6 * sigma^2`. Dividing the MAD by `sqrt(6)`
#' therefore gives the noise of a single point. The MAD uses medians, so
#' the few large values at peaks do not inflate the estimate. The input
#' is checked and sorted with the same rules as every hullBase function.
#'
#' @references
#' Rousseeuw, P. J. and Croux, C. (1993). Alternatives to the median
#' absolute deviation. Journal of the American Statistical Association,
#' 88(424), 1273 to 1283.
#'
#' @examples
#' noise_estimate(1:7, c(0, 0, 1, 0, 0, 0, 0))
#'
#' sim <- simulate_spectrum(baseline = "concave", noise_sd = 0.02)
#' noise_estimate(sim$x, sim$y)
#'
#' @importFrom stats mad
#' @export
noise_estimate <- function(x, y) {
  spec <- check_spectrum(x, y)

  # second differences: y[i+1] - 2*y[i] + y[i-1]
  d2 <- diff(spec$y, differences = 2)

  # MAD of the second differences, divided by sqrt(6) to get the noise of one point
  mad(d2) / sqrt(6)
}
