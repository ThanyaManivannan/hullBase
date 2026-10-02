#' Check and Prepare a Spectrum
#'
#' Runs the input checks that every hullBase function relies on, and
#' returns the spectrum sorted by x. Used internally by the other
#' functions so the same rules apply everywhere.
#'
#' @param x Numeric vector of wavenumbers.
#' @param y Numeric vector of absorbance values, the same length as `x`.
#'
#' @return A list with four elements: `x` and `y` sorted by increasing
#'   x, `ord` giving the original position of each sorted point, and `h`
#'   giving the typical step between neighbouring x values.
#'
#' @details
#' The checks run in this order. `x` and `y` must be numeric, the same
#' length, and have at least 5 points. They must not contain `NA`, `NaN`
#' or `Inf`. The points are then sorted by x, and no two points may share
#' the same x value. Finally the spacing is checked. The typical step `h`
#' is the median of `diff(x)`, and a warning is given if any step differs
#' from `h` by more than 1 percent, since later steps assume even spacing.
#'
#' @importFrom stats median
#' @keywords internal
check_spectrum <- function(x, y) {
  # P1: type, length and size
  if (!is.numeric(x) || !is.numeric(y)) {
    stop("`x` and `y` must both be numeric vectors.", call. = FALSE)
  }
  if (length(x) != length(y)) {
    stop(sprintf("`x` and `y` must be the same length (x has %d, y has %d).",
                 length(x), length(y)), call. = FALSE)
  }
  if (length(x) < 5) {
    stop("Need at least 5 points in the spectrum.", call. = FALSE)
  }

  # P2: no missing or infinite values
  if (any(!is.finite(x)) || any(!is.finite(y))) {
    stop("`x` and `y` must not contain NA, NaN or Inf values.", call. = FALSE)
  }

  # P3: sort by x and remember the original order
  ord <- order(x)
  x <- x[ord]
  y <- y[ord]

  # P4: every x value must be different
  dx <- diff(x)
  if (any(dx == 0)) {
    stop("`x` contains repeated values. Each wavenumber must appear once.",
         call. = FALSE)
  }

  # P5: check the spacing against the typical step h
  h <- median(dx)
  if (max(abs(dx - h)) / h > 0.01) {
    warning("`x` is not evenly spaced. Results assume roughly equal steps.",
            call. = FALSE)
  }

  list(x = x, y = y, ord = ord, h = h)
}
