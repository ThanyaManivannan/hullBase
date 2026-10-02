#' Find Hull Segments That Hide a Concave Baseline
#'
#' Checks every straight segment of the rubberband baseline and flags the
#' ones whose data never comes back down to the segment within a window as
#' wide as the widest peak. Peaks are narrower than the window and are
#' ignored. A concave (dome shaped) baseline is wider and is flagged.
#'
#' @param x Numeric vector of wavenumbers. Need not be sorted.
#' @param y Numeric vector of absorbance values, the same length as `x`.
#' @param peak_width Width, in the units of `x`, of the widest peak or the
#'   widest group of overlapping peaks in the spectrum.
#' @param noise Noise standard deviation of the spectrum. If `NULL`, it is
#'   estimated with `noise_estimate()`.
#'
#' @return A data frame with one row per hull segment and columns `left`
#'   and `right` (positions of the two hull vertices after sorting by x),
#'   `x_left` and `x_right` (their x values), `n_points`, `max_eroded_gap`
#'   and `flagged`. The threshold used and the window half width `m` are
#'   stored as the attributes `"threshold"` and `"m"`.
#'
#' @details
#' For each segment, the gap `g = y - b` between the data and the straight
#' hull segment is eroded with a moving minimum over `2 * m + 1` points,
#' where `m = round(peak_width / (2 * h))` and `h` is the step between x
#' values. Erosion removes anything narrower than the window, so peaks
#' disappear and a dome remains. The segment is flagged when the largest
#' eroded gap exceeds `2 * noise * sqrt(2 * log(n))`, twice the universal
#' threshold of Donoho and Johnstone (1994), and the segment has at least
#' `2 * m + 3` points.
#'
#' @references
#' Donoho, D. L. and Johnstone, I. M. (1994). Ideal spatial adaptation by
#' wavelet shrinkage. Biometrika, 81(3), 425 to 455.
#'
#' Serra, J. (1982). Image Analysis and Mathematical Morphology.
#' Academic Press.
#'
#' @examples
#' sim <- simulate_spectrum(baseline = "concave")
#' detect_concave_segments(sim$x, sim$y, peak_width = 300)
#'
#' @export
detect_concave_segments <- function(x, y, peak_width, noise = NULL) {
  spec <- check_spectrum(x, y)

  if (!is.numeric(peak_width) || length(peak_width) != 1 ||
      !is.finite(peak_width) || peak_width <= 0) {
    stop("`peak_width` must be a single number greater than 0.", call. = FALSE)
  }
  if (is.null(noise)) {
    noise <- noise_estimate(spec$x, spec$y)
  }
  if (!is.numeric(noise) || length(noise) != 1 || !is.finite(noise) ||
      noise < 0) {
    stop("`noise` must be a single number of 0 or more.", call. = FALSE)
  }

  n <- length(spec$x)
  m <- max(1, round(peak_width / (2 * spec$h)))
  threshold <- 2 * noise * sqrt(2 * log(n))

  # hull vertices and the straight line baseline between them
  idx <- lower_hull_cpp(spec$x, spec$y)
  base <- approx(spec$x[idx], spec$y[idx], xout = spec$x)$y

  out <- data.frame(
    left = idx[-length(idx)],
    right = idx[-1],
    x_left = spec$x[idx[-length(idx)]],
    x_right = spec$x[idx[-1]],
    n_points = diff(idx) + 1,
    max_eroded_gap = 0,
    flagged = FALSE
  )

  for (s in seq_len(nrow(out))) {
    # a segment narrower than one window cannot hide anything wider than a peak
    if (out$n_points[s] < 2 * m + 3) {
      next
    }
    pts <- out$left[s]:out$right[s]
    gap <- spec$y[pts] - base[pts]
    e <- erode(gap, m)
    out$max_eroded_gap[s] <- max(e)
    out$flagged[s] <- max(e) > threshold
  }

  attr(out, "threshold") <- threshold
  attr(out, "m") <- m
  out
}

#' Moving Minimum (Erosion)
#'
#' Replaces every value with the smallest value within `m` positions on
#' either side. Near the two ends the window is cut short.
#'
#' @param g Numeric vector.
#' @param m Window half width, in number of points.
#'
#' @return A numeric vector the same length as `g`.
#'
#' @keywords internal
erode <- function(g, m) {
  n <- length(g)
  out <- numeric(n)
  for (i in seq_len(n)) {
    out[i] <- min(g[max(1, i - m):min(n, i + m)])
  }
  out
}
