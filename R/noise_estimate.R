noise_estimate <- function(x, y) {
  if (length(y) < 2) {
    stop("Need at least 2 points to estimate noise.")
  }
  # Calculate the difference between each pair of consecutive points in y
  d <- diff(y)
  # Estimate noise using the median absolute deviation (MAD) of these differences
  # Dividing by sqrt(2) corrects for the fact that each difference combines
  # noise from two separate points, not just one
  stats::mad(d) / sqrt(2)
}
