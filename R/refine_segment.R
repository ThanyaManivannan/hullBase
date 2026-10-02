#' Correct One Concave Segment by Automatic Local Bending
#'
#' Corrects the baseline under one hull segment that hides a concave
#' (dome shaped) background. A bowl shaped curve is added so the dome
#' becomes convex, the lower hull is taken, and the bowl is removed again.
#' How strongly to bend is worked out from the data.
#'
#' @param x Numeric vector of wavenumbers for the segment. The first and
#'   last points (after sorting) are the two hull vertices that bound it.
#' @param y Numeric vector of absorbance values, the same length as `x`.
#' @param peak_width Width, in the units of `x`, of the widest peak or the
#'   widest group of overlapping peaks.
#' @param noise Noise standard deviation. If `NULL`, it is estimated with
#'   `noise_estimate()`.
#' @param bend_factor Safety factor `k` applied to the estimated dome
#'   height. Defaults to 2. Must be at least 1.
#' @param max_depth Largest number of bending levels. Defaults to 3.
#'
#' @return A numeric vector the same length as `x`: the corrected baseline
#'   for the segment, in the same order as the input. The two end values
#'   are unchanged and the baseline never goes above `y`.
#'
#' @details
#' The bowl is `q = (x - xL) * (x - xR) / (W / 2)^2`, where `W = xR - xL`.
#' It is zero at both ends, -1 in the middle, and has constant curvature
#' `8 / W^2`. The dome height is estimated as the largest value of
#' `e / -q` over the middle half of the segment, where `e` is the gap
#' above the chord after erosion with the same window as
#' `detect_concave_segments()`. The bend strength is `bend_factor` times
#' this height. The bent data `y + c * q` is hulled and `c * q` is
#' subtracted again. For a parabolic dome any strength at least equal to
#' its height gives the exact dome. Other shapes need more, for example
#' `pi^2 / 8` times the height for a sine arch, which is why the default
#' factor is 2. The value 2 was chosen by simulation as a margin that
#' covers these shapes without removing peaks.
#'
#' After bending, any part of the segment where the remaining gap still
#' passes the test of `detect_concave_segments()` is bent again, and the
#' extra correction is added on top, up to `max_depth` levels.
#'
#' @references
#' Beleites, C. (2015). Fitting baselines to spectra. hyperSpec package
#' vignette.
#'
#' @examples
#' x <- seq(0, 10, length.out = 201)
#' dome <- 2 * sin(pi * x / 10)
#' y <- dome + 1.5 * exp(-((x - 5) / 0.4)^2)
#' b <- refine_segment(x, y, peak_width = 2, noise = 0)
#' plot(x, y, type = "l")
#' lines(x, b, col = "blue")
#'
#' @export
refine_segment <- function(x, y, peak_width, noise = NULL, bend_factor = 2,
                           max_depth = 3) {
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
  if (!is.numeric(bend_factor) || length(bend_factor) != 1 ||
      bend_factor < 1) {
    stop("`bend_factor` must be a single number of 1 or more.", call. = FALSE)
  }
  if (!is.numeric(max_depth) || length(max_depth) != 1 || max_depth < 1) {
    stop("`max_depth` must be a single whole number of 1 or more.",
         call. = FALSE)
  }

  n <- length(spec$x)
  m <- max(1, round(peak_width / (2 * spec$h)))
  threshold <- 2 * noise * sqrt(2 * log(n))

  b <- bend_segment(spec$x, spec$y, m, threshold, bend_factor, max_depth)

  # put the baseline back in the order the segment was given in
  out <- numeric(n)
  out[spec$ord] <- b
  out
}

#' Bend, Hull and Unbend One Segment
#'
#' The working part of `refine_segment()`. Expects `x` sorted and the
#' first and last points to be the segment anchors.
#'
#' @param x Sorted numeric vector of wavenumbers.
#' @param y Numeric vector of values in the same order.
#' @param m Erosion window half width, in points.
#' @param threshold Smallest eroded gap that counts as concave.
#' @param bend_factor Safety factor applied to the estimated dome height.
#' @param depth Number of bending levels still allowed.
#'
#' @return The baseline for the segment, in sorted order.
#'
#' @keywords internal
bend_segment <- function(x, y, m, threshold, bend_factor, depth) {
  n <- length(x)
  w <- x[n] - x[1]

  # straight chord between the two anchors, and the gap above it
  chord <- y[1] + (y[n] - y[1]) * (x - x[1]) / w
  gap <- y - chord

  # bowl: zero at both anchors, -1 in the middle
  q <- (x - x[1]) * (x - x[n]) / (w / 2)^2

  # dome height from the eroded gap over the middle half, times the safety factor
  e <- erode_cpp(gap, m)
  middle <- q <= -0.5
  c_star <- bend_factor * max(e[middle] / -q[middle])
  if (!is.finite(c_star) || c_star <= 0) {
    return(pmin(chord, y))
  }

  # bend, take the lower hull, then unbend
  bent <- y + c_star * q
  idx <- lower_hull_cpp(x, bent)
  b <- approx(x[idx], bent[idx], xout = x)$y - c_star * q
  b <- pmin(b, y)

  # check what is left between each pair of new vertices and bend again if needed
  if (depth > 1) {
    for (k in seq_len(length(idx) - 1)) {
      left <- idx[k]
      right <- idx[k + 1]
      if (right - left + 1 < 2 * m + 3) {
        next
      }
      pts <- left:right
      rest <- y[pts] - b[pts]
      if (max(erode_cpp(rest, m)) > threshold) {
        b[pts] <- b[pts] + bend_segment(x[pts], rest, m, threshold,
                                        bend_factor, depth - 1)
      }
    }
  }

  pmin(b, y)
}
