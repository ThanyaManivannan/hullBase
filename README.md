# Peer Assessment Plan

Package: hullBase
Repository: https://github.com/ThanyaManivannan/hullBase

## Installation

```r
devtools::install_github("ThanyaManivannan/hullBase")
library(hullBase)
```

## Check everything at once

```r
devtools::test()
```
Expect: 27 tests, 0 failures. This runs every test written for every function listed below, and is the fastest way to confirm nothing is broken before checking functions individually.

## Functions to check one by one

### 1. lower_hull(x, y)
What it does: estimates a spectrum's baseline using the classic rubberband method, the straight line connecting the lowest points of the spectrum. Peaks sitting above this line are correctly excluded. Returns the baseline value at every input point, same length as the input.

Run:
```r
lower_hull(c(1, 2, 3, 4, 5), c(5, 2, 3, 2, 5))
```
Expect:
```
[1] 5 2 2 2 5
```
The middle point (value 3) sits above the straight line joining the two low points on either side of it, so it gets pulled down to 2, matching the baseline there.

Should error on: `lower_hull(1, 1)`, since a hull needs at least 2 points. If it silently returns something instead of erroring, that is a bug.

### 2. noise_estimate(x, y)
What it does: estimates how noisy a spectrum is, directly from the data, with no value set by hand. This number is what the two functions further down use to decide how much correction is real versus just noise.

Run:
```r
noise_estimate(1:7, c(0, 2, 0, 2, 0, 2, 0))
```
Expect:
```
[1] 2.096713
```

Should error on: `noise_estimate(1, 1)`, since it needs at least 2 points to measure any variation at all.

### 3. rubberband_baseline(x, y) and correct(model)
What it does: the object oriented version of the plain baseline correction. `rubberband_baseline()` builds an S3 object from the spectrum, and `correct()` is an S3 method that runs a compiled C++ function to find the hull, then returns the corrected spectrum (the original values minus the baseline).

Run:
```r
model <- rubberband_baseline(c(1, 2, 3, 4, 5), c(5, 2, 3, 2, 5))
correct(model)
```
Expect:
```
[1] 0 0 1 0 0
```
The two low points and the two points beside them land exactly on the baseline, so they correct to 0. Only the middle peak (originally 3, baseline 2) is left with a value, 1.

### 4. detect_concave_segments(x, y, noise)
What it does: this is the new part of the project. A plain rubberband baseline draws a straight line across any region where the true background actually curves downward, since it can only connect points with straight segments. This function looks at each straight segment and flags the ones that are probably hiding a real dip like this, by checking for a genuine notch shape, a point lower than both of its immediate neighbours, that still sits higher than the noise level.

Run:
```r
x <- 1:11
y <- c(0, 0, 0, 0.3, 0.5, 0.2, 0.5, 0.3, 0, 0, 0)
detect_concave_segments(x, y, noise = 0.1)
```
Expect:
```
  left_idx right_idx
1        3         9
```
This means the section between point 3 and point 9 (where the small dip at point 6 sits between two bumps) has been flagged as needing correction.

### 5. refine_segment(x, y, noise)
What it does: takes one section flagged by the function above and pulls the baseline down within it, so it follows the real shape of the data there instead of staying a straight line. It stops automatically once further changes are smaller than the noise level, so it does not just keep shrinking forever.

Run:
```r
refine_segment(x = 1:5, y = c(0, 2, 3, 2, 0), noise = 0.6)
```
Expect:
```
[1] 0.0 1.0 1.5 1.0 0.0
```

## Not built yet

`detect_concave_segments()` and `refine_segment()` each work correctly and are tested on their own, but they are not yet connected to `correct()`. Right now `correct()` still only returns the plain rubberband result, it does not yet run detection and refinement automatically. `print()`, `summary()`, `plot()`, and a `simulate_spectrum()` synthetic data generator are also not built yet.
