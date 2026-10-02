#' Print a BaselineModel
#'
#' Shows a short overview of a baseline correction: the method, the size
#' of the spectrum, the noise level and how many segments were refined.
#'
#' @param x A `BaselineModel` object from [correct()].
#' @param ... Not used.
#'
#' @return `x`, invisibly.
#'
#' @examples
#' sim <- simulate_spectrum(baseline = "concave")
#' fit <- correct(sim, peak_width = 300)
#' print(fit)
#'
#' @export
print.BaselineModel <- function(x, ...) {
  label <- if (x$method == "adaptive") "adaptive (ALB Rubberband)" else "rubberband"
  cat("<BaselineModel>\n")
  cat("  method :", label, "\n")
  cat("  points :", length(x$x), "from", min(x$x), "to", max(x$x), "\n")
  cat("  noise  :", signif(x$noise, 3), "\n")
  if (x$method == "adaptive") {
    cat("  concave segments refined:", sum(x$segments$flagged), "of",
        nrow(x$segments), "\n")
  }
  invisible(x)
}

#' Summarise a BaselineModel
#'
#' Gives the details of a baseline correction: the settings used, the
#' segments that were refined, and how far the final baseline was lifted
#' above the plain rubberband baseline.
#'
#' @param object A `BaselineModel` object from [correct()].
#' @param ... Not used.
#'
#' @return An object of class `summary.BaselineModel`, a list with
#'   elements `method`, `n`, `x_range`, `noise`, `peak_width`, `threshold`,
#'   `n_segments`, `flagged` (the refined rows of the segment table),
#'   `max_lift` (largest value of `baseline - rubberband`) and
#'   `area_lifted` (the area between the two baselines, by the trapezoid
#'   rule).
#'
#' @examples
#' sim <- simulate_spectrum(baseline = "concave")
#' fit <- correct(sim, peak_width = 300)
#' summary(fit)
#'
#' @export
summary.BaselineModel <- function(object, ...) {
  ord <- order(object$x)
  xs <- object$x[ord]
  lift <- (object$baseline - object$rubberband)[ord]
  adaptive <- object$method == "adaptive"

  out <- list(
    method = object$method,
    n = length(object$x),
    x_range = range(object$x),
    noise = object$noise,
    peak_width = object$peak_width,
    threshold = if (adaptive) attr(object$segments, "threshold") else NA,
    n_segments = if (adaptive) nrow(object$segments) else NA,
    flagged = if (adaptive) object$segments[object$segments$flagged, ] else NULL,
    max_lift = max(lift),
    # trapezoid rule: width of each step times the average lift at its two ends
    area_lifted = sum(diff(xs) * (lift[-1] + lift[-length(lift)]) / 2)
  )
  class(out) <- "summary.BaselineModel"
  out
}

#' Print a BaselineModel Summary
#'
#' @param x A `summary.BaselineModel` object from `summary()`.
#' @param ... Not used.
#'
#' @return `x`, invisibly.
#'
#' @export
print.summary.BaselineModel <- function(x, ...) {
  cat("Baseline correction summary\n")
  cat("  method          :", x$method, "\n")
  cat("  points          :", x$n, "from", x$x_range[1], "to", x$x_range[2], "\n")
  cat("  noise estimate  :", signif(x$noise, 3), "\n")
  if (x$method == "adaptive") {
    cat("  peak_width      :", x$peak_width, "\n")
    cat("  threshold       :", signif(x$threshold, 3), "\n")
    cat("  hull segments   :", x$n_segments, "\n")
    cat("  segments refined:", nrow(x$flagged), "\n")
    if (nrow(x$flagged) > 0) {
      print(x$flagged[, c("x_left", "x_right", "n_points", "max_eroded_gap")],
            row.names = FALSE)
    }
    cat("  largest lift above plain rubberband:", signif(x$max_lift, 3), "\n")
    cat("  area between the two baselines     :", signif(x$area_lifted, 3), "\n")
  }
  invisible(x)
}

#' Plot a BaselineModel
#'
#' Draws either the spectrum with its baselines, or the corrected
#' spectrum. In the baseline view, segments refined by local bending are
#' shaded, the plain rubberband baseline is dashed red and the final
#' baseline is blue.
#'
#' @param x A `BaselineModel` object from [correct()].
#' @param which Either `"baseline"` (default) or `"corrected"`.
#' @param ... Further graphical arguments passed to [graphics::plot()].
#'
#' @return `x`, invisibly.
#'
#' @examples
#' sim <- simulate_spectrum(baseline = "concave")
#' fit <- correct(sim, peak_width = 300)
#' plot(fit)
#' plot(fit, which = "corrected")
#'
#' @importFrom graphics plot lines rect legend abline par
#' @export
plot.BaselineModel <- function(x, which = c("baseline", "corrected"), ...) {
  which <- match.arg(which)
  ord <- order(x$x)
  xs <- x$x[ord]

  if (which == "baseline") {
    plot(xs, x$y[ord], type = "l", col = "grey40", xlab = "Wavenumber",
         ylab = "Absorbance", ...)

    # shade the refined segments, then redraw the spectrum on top
    if (x$method == "adaptive" && any(x$segments$flagged)) {
      f <- x$segments[x$segments$flagged, ]
      usr <- par("usr")
      rect(f$x_left, usr[3], f$x_right, usr[4], col = "lightyellow",
           border = NA)
      lines(xs, x$y[ord], col = "grey40")
    }

    lines(xs, x$rubberband[ord], col = "red", lty = 2, lwd = 2)
    lines(xs, x$baseline[ord], col = "blue", lwd = 2)
    legend("topright", legend = c("spectrum", "plain rubberband", "baseline"),
           col = c("grey40", "red", "blue"), lty = c(1, 2, 1),
           lwd = c(1, 2, 2), bty = "n")
  } else {
    plot(xs, x$corrected[ord], type = "l", xlab = "Wavenumber",
         ylab = "Corrected absorbance", ...)
    abline(h = 0, col = "grey60", lty = 2)
  }

  invisible(x)
}
