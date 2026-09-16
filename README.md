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

- Checks the result against a worked example, to confirm the function gives the exact right answer on a case that can be checked by hand, not just a plausible looking one.
- Checks the corrected values are never negative, since a baseline correction that overshoots would be a bug, the corrected spectrum should not dip below the baseline it was just measured against.
- Checks unsorted x input gets sorted before use, since a real spectrum is not guaranteed to arrive already ordered by wavenumber, and this confirms the function does not silently give the wrong answer if it is not.
- Checks an error is raised for fewer than 2 points, since a hull needs at least two points to mean anything, and this confirms the function fails clearly instead of crashing or returning nonsense.

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
