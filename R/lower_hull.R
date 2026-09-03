#' Compute a Rubberband (Lower Convex Hull) Baseline
#'
#' Estimates a spectrum's baseline using the classic rubberband method: the
#' baseline is the lower convex hull of the (x, y) points, linearly
#' interpolated between hull vertices. Points that lie above the hull (such
#' as spectral peaks) are correctly excluded from the baseline.
#'
#' @param x Numeric vector of wavenumbers (or any x-axis values). Need not
#'   be sorted; the function sorts internally.
#' @param y Numeric vector of absorbance values, the same length as `x`.
#'
#' @return A numeric vector the same length as `x`, giving the estimated
#'   baseline value at each point, in the same order as the input.
#'
#' @examples
#' x <- c(1, 2, 3, 4, 5)
#' y <- c(5, 2, 3, 2, 5)
#' lower_hull(x, y)
#'
#' @export

lower_hull <- function(x, y) {
  n <- length(x)
  if (n < 2) {
    stop("Need at least 2 points to compute a hull.")
  }

  # sort by x, just in case the spectrum wasn't already in wavenumber order
  ord <- order(x)
  x <- x[ord]
  y <- y[ord]

  # cross() tests whether going O -> A -> B turns left (>0) or not (<=0)
  cross <- function(ox, oy, ax, ay, bx, by) {
    (ax - ox) * (by - oy) - (ay - oy) * (bx - ox)
  }

  hull_idx <- integer(0)  # indices (into sorted x/y) that survive onto the hull

  for (i in seq_len(n)) {
    while (length(hull_idx) >= 2) {
      o <- hull_idx[length(hull_idx) - 1]
      a <- hull_idx[length(hull_idx)]
      if (cross(x[o], y[o], x[a], y[a], x[i], y[i]) <= 0) {
        hull_idx <- hull_idx[-length(hull_idx)]  # drop the last point, it's not on the hull
      } else {
        break
      }
    }
    hull_idx <- c(hull_idx, i)
  }

  # straight-line interpolation between hull points, evaluated at every original x
  baseline_sorted <- approx(x[hull_idx], y[hull_idx], xout = x)$y

  # put the result back into the caller's original point order
  baseline <- numeric(n)
  baseline[ord] <- baseline_sorted
  baseline
}
