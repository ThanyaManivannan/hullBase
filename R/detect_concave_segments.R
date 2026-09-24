#' Flag Hull Segments That Likely Hide a Concave Baseline
#'
#' Looks at every straight segment of the rubberband (lower hull) baseline
#' and flags the ones that are probably hiding a real concave dip in the
#' true baseline, usually because two or more peaks sit on top of that
#' dip and stop any single point from getting low enough to become its
#' own hull vertex.
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
#' looks for a genuine notch among the points in between: a point that
#' sits lower than both of its immediate neighbours, while still sitting
#' further above the straight chord than the noise level. A notch like
#' this is a sign that two or more peaks are sitting on top of a real dip
#' in the baseline, hiding it. A single ordinary peak does not create a
#' notch, since it only rises and falls once, so it is correctly left
#' alone. Segments with fewer than 3 points between their two anchors are
#' never flagged, since a genuine notch needs at least 3 points to show a
#' dip shape at all.
#'
#' @examples
#' x <- 1:11
#' y <- c(0, 0, 0, 0.3, 0.5, 0.2, 0.5, 0.3, 0, 0, 0)
#' detect_concave_segments(x, y, noise = 0.1)
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

    n_interior <- right - left - 1
    if (n_interior < 3) {
      next  # need at least 3 points to tell a genuine notch from a single peak
    }

    interior <- left + seq_len(n_interior)
    gap <- y[interior] - baseline[interior]

    # look for a genuine notch: a point that dips below both of its
    # immediate neighbours, while still sitting above the noise floor
    m <- length(gap)
    is_notch <- rep(FALSE, m)
    for (j in 2:(m - 1)) {
      if (gap[j] < gap[j - 1] && gap[j] < gap[j + 1] && gap[j] > noise) {
        is_notch[j] <- TRUE
      }
    }

    if (any(is_notch)) {
      flagged <- rbind(flagged, data.frame(left_idx = left, right_idx = right))
    }
  }

  flagged
}
