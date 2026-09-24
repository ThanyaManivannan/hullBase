#' Flag Hull Segments That Likely Hide a Concave Baseline
#'
#' Looks at every straight segment of the rubberband (lower hull) baseline
#' and flags the ones that are probably hiding a real concave dip in the
#' true baseline, usually because a peak sits on top of that dip and stops
#' any single point from getting low enough to become its own hull vertex.
#'
#' @param x Numeric vector of wavenumbers. Need not be sorted, the
#'   function sorts internally, matching `lower_hull()`.
#' @param y Numeric vector of absorbance values, the same length as `x`.
#' @param noise A single numeric value giving the spectrum's noise level,
#'   normally the result of `noise_estimate()`.
#'
#' @return A data frame with one row per flagged segment, and two
#'   columns, `left_idx` and `right_idx`. These are the positions (after
#'   sorting by x) of the two hull vertices bounding that segment. If no
#'   segment is flagged, the data frame has zero rows.
#'
#' @details
#' A hull vertex is any point where the rubberband baseline touches the
#' spectrum exactly, since that is how `lower_hull()` builds the
#' baseline. For each pair of neighbouring hull vertices, this function
#' looks at every real data point between them and measures how far above
#' the straight chord it sits. If every single point in that gap sits
#' further above the chord than the noise level, this is a sign that
#' something, usually a peak, is hiding a real dip in the true baseline
#' underneath, and the segment gets flagged.
#'
#' A rare limitation worth noting: if a point happens to sit exactly on
#' the straight line between two vertices purely by coincidence, it could
#' be mistaken for a vertex itself. This is unlikely with real noisy
#' data, but is a known edge case rather than a hidden one.
#'
#' @examples
#' detect_concave_segments(x = 1:5, y = c(0, 0.5, 0.6, 0.5, 0), noise = 0.1)
#'
#' @export
detect_concave_segments <- function(x, y, noise) {
  if (length(x) < 2) {
    stop("Need at least 2 points to detect segments.")
  }

  # sort by x first, same as lower_hull does internally
  ord <- order(x)
  x <- x[ord]
  y <- y[ord]

  baseline <- lower_hull(x, y)

  # a hull vertex is a point where the baseline touches the data exactly
  is_vertex <- abs(y - baseline) < 1e-8
  vertex_idx <- which(is_vertex)

  flagged <- data.frame(left_idx = integer(0), right_idx = integer(0))

  if (length(vertex_idx) < 2) {
    return(flagged)
  }

  for (k in seq_len(length(vertex_idx) - 1)) {
    left <- vertex_idx[k]
    right <- vertex_idx[k + 1]

    if (right - left <= 1) {
      next  # no data points between these two hull vertices
    }

    interior <- (left + 1):(right - 1)
    gap <- y[interior] - baseline[interior]
    min_gap <- min(gap)

    if (min_gap > noise) {
      flagged <- rbind(flagged, data.frame(left_idx = left, right_idx = right))
    }
  }

  flagged
}
