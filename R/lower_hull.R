#' Compute a Rubberband (Lower Convex Hull) Baseline
#'
#' Estimates a spectrum's baseline with the classic rubberband method. The
#' baseline is the lower convex hull of the points, joined by straight
#' lines between hull vertices. Peaks lie above the hull, so they are left
#' out of the baseline.
#'
#' @param x Numeric vector of wavenumbers. Need not be sorted.
#' @param y Numeric vector of absorbance values, the same length as `x`.
#'
#' @return A numeric vector the same length as `x`, giving the baseline at
#'   each point, in the same order as the input.
#'
#' @details
#' The input is first checked and sorted with `check_spectrum()`. The hull
#' vertices are then found by Andrew's monotone chain algorithm, run in
#' compiled C++ code for speed. For three points O, A and B, the cross
#' product `(xA - xO) * (yB - yO) - (yA - yO) * (xB - xO)` is positive
#' only when the slope increases from O to A to B. If it is zero or less,
#' A cannot lie on the lower hull and is removed. Between neighbouring
#' vertices L and R, the baseline is the straight line
#' `yL + (yR - yL) * (x - xL) / (xR - xL)`.
#'
#' The result is the highest convex curve that never goes above the data.
#' It follows straight and convex backgrounds exactly, but it cannot
#' follow a concave (dome shaped) background, where it lays a straight
#' chord instead.
#'
#' @references
#' Andrew, A. M. (1979). Another efficient algorithm for convex hulls in
#' two dimensions. Information Processing Letters, 9(5), 216 to 219.
#'
#' @examples
#' lower_hull(c(1, 2, 3, 4, 5), c(5, 2, 3, 2, 5))
#'
#' sim <- simulate_spectrum(baseline = "convex", noise_sd = 0.01)
#' plot(sim$x, sim$y, type = "l")
#' lines(sim$x, lower_hull(sim$x, sim$y), col = "blue")
#'
#' @export
lower_hull <- function(x, y) {
  spec <- check_spectrum(x, y)

  # positions of the hull vertices, found by the compiled C++ code
  idx <- lower_hull_cpp(spec$x, spec$y)

  # straight lines between neighbouring vertices give the baseline at every x
  b <- approx(spec$x[idx], spec$y[idx], xout = spec$x)$y

  # put the baseline back in the order the spectrum was given in
  out <- numeric(length(b))
  out[spec$ord] <- b
  out
}

#' Lower Hull Vertices in Plain R
#'
#' The same monotone chain as `lower_hull_cpp()`, written in R. Kept as a
#' reference so tests can confirm the C++ version gives identical results,
#' and so the speed of the two can be compared.
#'
#' @param x Numeric vector of wavenumbers, already sorted increasing.
#' @param y Numeric vector of absorbance values, in the same order as `x`.
#'
#' @return Integer vector of the positions of the hull vertices, from left
#'   to right.
#'
#' @keywords internal
lower_hull_r <- function(x, y) {
  n <- length(x)
  hull <- integer(0)
  for (i in seq_len(n)) {
    # remove the last vertex while the turn to point i does not go left
    while (length(hull) >= 2) {
      o <- hull[length(hull) - 1]
      a <- hull[length(hull)]
      cross <- (x[a] - x[o]) * (y[i] - y[o]) - (y[a] - y[o]) * (x[i] - x[o])
      if (cross <= 0) {
        hull <- hull[-length(hull)]
      } else {
        break
      }
    }
    hull <- c(hull, i)
  }
  hull
}
