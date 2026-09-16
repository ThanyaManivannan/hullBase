# hullBase

R package for rubberband (convex hull) baseline correction of spectra.

## Installation

```r
devtools::install_github("ThanyaManivannan/hullBase")
```

## OO function using Rcpp

The hull calculation is written in C++ using Rcpp: `lower_hull_cpp()` in `src/lower_hull_cpp.cpp`.

An S3 class `rubberband_baseline` stores a spectrum's x and y values. The method `correct.rubberband_baseline()` in `R/rubberband_baseline.R` calls `lower_hull_cpp()` and returns the baseline-corrected spectrum.

```r
library(hullBase)
model <- rubberband_baseline(c(1, 2, 3, 4, 5), c(5, 2, 3, 2, 5))
correct(model)
#> [1] 0 0 1 0 0
```

## Test function

Tests for `correct.rubberband_baseline()` are in `tests/testthat/test-rubberband_baseline.R`.

Four tests:

- Result verified against a hand calculated example, confirming the function returns the correct baseline.
- Corrected values checked to confirm none are negative, since a correction should not push the spectrum below its own baseline.
- Unsorted x input tested to confirm the function still sorts correctly and returns the right result.
- Input of fewer than two points tested to confirm the function raises an error rather than failing silently or crashing.

## Test results

```r
devtools::test()
```

```
✔ | F W  S  OK | Context
✔ |          4 | lower_hull
✔ |          4 | noise_estimate
✔ |          4 | rubberband_baseline

[ FAIL 0 | WARN 0 | SKIP 0 | PASS 12 ]
```
