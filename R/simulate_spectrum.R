#' Simulate a Spectrum with a Known Baseline
#'
#' Builds a test spectrum as the sum of Gaussian peaks, a baseline of a
#' chosen shape, and Gaussian noise, following the simulation design of
#' Zhang et al. (2020). Because the true baseline is returned as well,
#' any baseline correction can be scored against it.
#'
#' @param x Numeric vector of wavenumbers. Defaults to 0 to 1400 in steps
#'   of 1, which keeps the default peaks away from both ends.
#' @param baseline Shape of the baseline. One of `"concave"` (an arch,
#'   `amplitude * sin(pi * u)`), `"linear"` (`amplitude * u`), `"convex"`
#'   (a bowl, `amplitude * (2 * u - 1)^2`), `"flat"` (zero), or `"mixed"`
#'   (`amplitude * sin(2 * pi * u)`). Here `u` runs from 0 at the first
#'   x value to 1 at the last.
#' @param peaks A data frame with columns `height`, `centre` and `width`,
#'   one row per Gaussian peak. If `NULL`, the eight peaks of Zhang et al.
#'   (2020) are used.
#' @param amplitude Size of the baseline. Defaults to 1.
#' @param snr_db Signal to noise ratio in decibels, used to set the noise
#'   level when `noise_sd` is `NULL`. Defaults to 30.
#' @param noise_sd Standard deviation of the noise. If given, it is used
#'   instead of `snr_db`.
#'
#' @return A data frame with columns `x`, `y`, `baseline`, `signal` and
#'   `noise`, where `y = signal + baseline + noise`. The noise standard
#'   deviation used is stored in the attribute `"noise_sd"`.
#'
#' @details
#' Each peak is `height * exp(-((x - centre) / width)^2)`. When `noise_sd`
#' is not given, it is set from the signal to noise ratio as
#' `sqrt(mean(signal^2) / 10^(snr_db / 10))`. Call `set.seed()` before this
#' function to get the same spectrum again.
#'
#' @references
#' Zhang, F., Tang, X., Tong, A., Wang, B. and Wang, J. (2020). An automatic
#' baseline correction method based on the penalized least squares method.
#' Sensors, 20, 2015.
#'
#' @examples
#' sim <- simulate_spectrum(baseline = "concave")
#' plot(sim$x, sim$y, type = "l")
#' lines(sim$x, sim$baseline, col = "red")
#'
#' @importFrom stats rnorm
#' @export
simulate_spectrum <- function(x = seq(0, 1400, by = 1),
                              baseline = c("concave", "linear", "convex",
                                           "flat", "mixed"),
                              peaks = NULL, amplitude = 1,
                              snr_db = 30, noise_sd = NULL) {
  baseline <- match.arg(baseline)
  x <- check_spectrum(x, numeric(length(x)))$x

  # default peaks are the eight Gaussian peaks from Zhang et al. (2020)
  if (is.null(peaks)) {
    peaks <- data.frame(
      height = c(2, 1, 2, 1, 4, 0.5, 1, 1.5),
      centre = c(100, 200, 400, 500, 800, 1000, 1100, 1200),
      width  = c(20, 20, 40, 30, 50, 15, 20, 20)
    )
  }
  if (!is.data.frame(peaks) ||
      !all(c("height", "centre", "width") %in% names(peaks))) {
    stop("`peaks` must be a data frame with columns height, centre and width.",
         call. = FALSE)
  }
  if (any(peaks$width <= 0)) {
    stop("Every peak width must be greater than 0.", call. = FALSE)
  }

  # signal: add up the Gaussian peaks one at a time
  signal <- numeric(length(x))
  for (k in seq_len(nrow(peaks))) {
    signal <- signal + peaks$height[k] *
      exp(-((x - peaks$centre[k]) / peaks$width[k])^2)
  }

  # baseline: u runs from 0 at the first x to 1 at the last x
  u <- (x - x[1]) / (x[length(x)] - x[1])
  base <- switch(baseline,
                 flat    = rep(0, length(x)),
                 linear  = amplitude * u,
                 concave = amplitude * sin(pi * u),
                 convex  = amplitude * (2 * u - 1)^2,
                 mixed   = amplitude * sin(2 * pi * u)
  )

  # noise: use noise_sd if given, otherwise work it out from snr_db
  if (is.null(noise_sd)) {
    noise_sd <- sqrt(mean(signal^2) / 10^(snr_db / 10))
  }
  if (!is.numeric(noise_sd) || length(noise_sd) != 1 || noise_sd < 0) {
    stop("`noise_sd` must be a single number of 0 or more.", call. = FALSE)
  }
  noise <- rnorm(length(x), mean = 0, sd = noise_sd)

  out <- data.frame(x = x, y = signal + base + noise,
                    baseline = base, signal = signal, noise = noise)
  attr(out, "noise_sd") <- noise_sd
  out
}
