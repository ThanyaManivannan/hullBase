#' Create a Rubberband Baseline Object
#'
#' Constructs an object representing a spectrum's rubberband baseline model,
#' to be used with `correct()`.
#'
#' @param x Numeric vector of wavenumbers (or any x-axis values).
#' @param y Numeric vector of absorbance values, the same length as `x`.
#'
#' @return An object of class `rubberband_baseline`, storing the sorted x and y values.
#'
#' @examples
#' model <- rubberband_baseline(c(1, 2, 3, 4, 5), c(5, 2, 3, 2, 5))
#'
#' @export
rubberband_baseline <- function(x, y) {
  n <- length(x)
  if (n < 2) {
    stop("Need at least 2 points to build a rubberband baseline.")
  }

  # sort by x, same reasoning as in lower_hull()
  ord <- order(x)

  structure(
    list(x = x[ord], y = y[ord]),
    class = "rubberband_baseline"
  )
}

#' Baseline-Correct a Spectrum
#'
#' Generic function for baseline-correcting a spectrum stored in a model object.
#'
#' @param object A model object, such as one created by `rubberband_baseline()`.
#' @param ... Further arguments passed to methods.
#'
#' @return A numeric vector: the baseline-corrected spectrum.
#'
#' @export
correct <- function(object, ...) {
  UseMethod("correct")
}

#' @export
correct.rubberband_baseline <- function(object, ...) {
  # find which points are on the hull using the compiled C++ function
  hull_idx <- lower_hull_cpp(object$x, object$y)

  # connect the hull points with straight lines to get the baseline
  baseline <- approx(object$x[hull_idx], object$y[hull_idx], xout = object$x)$y

  # subtract the baseline to get the corrected spectrum
  object$y - baseline
}
