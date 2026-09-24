# Peer Assessment Plan

Package: hullBase
Repository: https://github.com/ThanyaManivannan/hullBase

## Installation

```r
devtools::install_github("ThanyaManivannan/hullBase")
```

## Functions implemented so far

### lower_hull(x, y)
Computes the plain rubberband baseline. Builds the lower convex hull of the spectrum using a hand-written monotone chain algorithm (not R's built-in `chull()`). Returns the baseline value at every input point.

Check by running:
```r
library(hullBase)
lower_hull(c(1, 2, 3, 4, 5), c(5, 2, 3, 2, 5))
#> [1] 5 2 2 2 5
```

### noise_estimate(x, y)
Estimates a spectrum's own noise level from the median absolute deviation of consecutive differences, divided by sqrt(2).

Check by running:
```r
noise_estimate(1:7, c(0, 2, 0, 2, 0, 2, 0))
#> [1] 2.096713
```

### rubberband_baseline(x, y) and correct(model)
`rubberband_baseline()` builds an S3 object holding a spectrum's sorted x and y values. `correct()` is an S3 method for this class; it calls a compiled Rcpp function, `lower_hull_cpp()` (in `src/lower_hull_cpp.cpp`), to find the hull, then returns the baseline-corrected spectrum (y minus baseline). This is the object-oriented, Rcpp-backed function in the package.

Check by running:
```r
model <- rubberband_baseline(c(1, 2, 3, 4, 5), c(5, 2, 3, 2, 5))
correct(model)
#> [1] 0 0 1 0 0
```

### detect_concave_segments(x, y, noise)
Looks at every straight segment of the rubberband baseline and flags the ones likely hiding a real concave dip. A segment gets flagged when it contains a genuine notch: a point that sits lower than both of its immediate neighbours while still sitting further above the chord than the noise level. This tells a real hidden dip apart from an ordinary single peak, which does not create a notch shape.

Check by running:
```r
x <- 1:11
y <- c(0, 0, 0, 0.3, 0.5, 0.2, 0.5, 0.3, 0, 0, 0)
detect_concave_segments(x, y, noise = 0.1)
#>   left_idx right_idx
#> 1        3         9
```

### refine_segment(x, y, noise)
Pulls the baseline down inside one flagged segment so it follows the shape of the spectrum there, instead of staying a straight line. Each pass replaces every interior point with the smaller of its own value and the average of its two neighbours, and stops once the change between passes drops below the spectrum's noise level.

Check by running:
```r
refine_segment(x = 1:5, y = c(0, 2, 3, 2, 0), noise = 0.6)
#> [1] 0.0 1.0 1.5 1.0 0.0
```

## Automated tests

All five functions above have testthat tests. Run the full suite after cloning the repository:
```r
devtools::test()
```
Expected: 27 tests, 0 failures.

## Not yet implemented

`detect_concave_segments()` and `refine_segment()` are each tested and working correctly on their own, but they are not yet wired into `correct()`. Calling `correct()` right now still only returns the plain rubberband result, it does not yet automatically detect and refine concave segments as one pipeline. Connecting the two into a single automatic correction is the next step.

Also not yet built: the `print()`, `summary()`, and `plot()` methods, a `simulate_spectrum()` synthetic data generator for repeatable comparative testing, a compiled C++ version of `refine_segment()`, and validation against real spectroscopy data.
