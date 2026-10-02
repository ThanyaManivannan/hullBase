#' Baseline Correct a Spectrum
#'
#' Runs the full hullBase baseline correction and returns a
#' `BaselineModel` object. With `method = "adaptive"` (the default) the
#' plain rubberband baseline is computed first, hull segments that hide a
#' concave background are found with [detect_concave_segments()], and each
#' one is corrected by local bending as in [refine_segment()]. With
#' `method = "rubberband"` the plain rubberband baseline is returned.
#'
#' @param x Numeric vector of wavenumbers, or for `correct.data.frame()` a
#'   data frame with columns `x` and `y`.
#' @param y Numeric vector of absorbance values, the same length as `x`.
#' @param peak_width Width, in the units of `x`, of the widest peak or the
#'   widest group of overlapping peaks. Needed for `method = "adaptive"`.
#' @param method Either `"adaptive"` or `"rubberband"`.
#' @param noise Noise standard deviation. If `NULL`, it is estimated with
#'   [noise_estimate()].
#' @param bend_factor Safety factor for the bend strength. See
#'   [refine_segment()].
#' @param max_depth Largest number of bending levels. See
#'   [refine_segment()].
#' @param ... Further arguments passed to `correct.default()`.
#'
#' @return An object of class `BaselineModel`: a list with elements `x`,
#'   `y`, `baseline`, `corrected` (`y - baseline`), `rubberband` (the plain
#'   rubberband baseline), `noise`, `peak_width`, `method`, `segments` (the
#'   table from [detect_concave_segments()], or `NULL` for the plain
#'   method) and `call`. All vectors are in the same order as the input.
#'
#' @examples
#' sim <- simulate_spectrum(baseline = "concave")
#' fit <- correct(sim$x, sim$y, peak_width = 300)
#' fit
#'
#' # a data frame with x and y columns works too
#' fit2 <- correct(sim, peak_width = 300)
#'
#' # plain rubberband for comparison
#' plain <- correct(sim, method = "rubberband")
#'
#' @export
correct <- function(x, ...) {
  UseMethod("correct")
}

#' @rdname correct
#' @export
correct.default <- function(x, y, peak_width = NULL,
                            method = c("adaptive", "rubberband"),
                            noise = NULL, bend_factor = 2, max_depth = 3,
                            ...) {
  method <- match.arg(method)
  spec <- check_spectrum(x, y)

  if (is.null(noise)) {
    noise <- noise_estimate(spec$x, spec$y)
  }

  # plain rubberband baseline, in sorted order
  idx <- lower_hull_cpp(spec$x, spec$y)
  plain <- approx(spec$x[idx], spec$y[idx], xout = spec$x)$y
  base <- plain
  segments <- NULL

  if (method == "adaptive") {
    if (is.null(peak_width)) {
      stop("`peak_width` is needed for method = \"adaptive\".", call. = FALSE)
    }
    segments <- detect_concave_segments(spec$x, spec$y, peak_width, noise)
    m <- attr(segments, "m")
    threshold <- attr(segments, "threshold")

    # replace the baseline inside every flagged segment by the bent version
    for (s in which(segments$flagged)) {
      pts <- segments$left[s]:segments$right[s]
      base[pts] <- bend_segment(spec$x[pts], spec$y[pts], m, threshold,
                                bend_factor, max_depth)
    }
  }

  # put everything back in the order the spectrum was given in
  n <- length(spec$x)
  baseline <- numeric(n)
  rubberband <- numeric(n)
  baseline[spec$ord] <- base
  rubberband[spec$ord] <- plain

  structure(
    list(
      x = x,
      y = y,
      baseline = baseline,
      corrected = y - baseline,
      rubberband = rubberband,
      noise = noise,
      peak_width = peak_width,
      method = method,
      segments = segments,
      call = match.call()
    ),
    class = "BaselineModel"
  )
}

#' @rdname correct
#' @export
correct.data.frame <- function(x, ...) {
  if (!all(c("x", "y") %in% names(x))) {
    stop("The data frame must have columns named x and y.", call. = FALSE)
  }
  correct.default(x$x, x$y, ...)
}
