# Peer Assessment Plan: hullBase Package

## 1. Repository Link and Installation Instructions

The package is hosted at:

https://github.com/ThanyaManivannan/hullBase

Install and load it as follows:

```r
install.packages("devtools")
devtools::install_github("ThanyaManivannan/hullBase")
```

```r
library(hullBase)
```

## 2. Overview of Implemented Functions

- **`lower_hull(x, y)`**: computes the rubberband baseline directly, using a hand-written monotone chain algorithm to build the lower convex hull of the spectrum. This does not call R's built-in `chull()`, in line with the project requirement that the core method not depend on an existing implementation.
- **`noise_estimate(x, y)`**: estimates a spectrum's own noise level from the median absolute deviation of the differences between consecutive points, divided by `sqrt(2)`.
- **`rubberband_baseline(x, y)` and `correct(model)`**: `rubberband_baseline()` builds an S3 object holding a spectrum's sorted `x` and `y` values. `correct()` is the S3 method for this class. It calls a compiled Rcpp function, `lower_hull_cpp()`, to find the hull, then returns the spectrum with the baseline subtracted.
- **`detect_concave_segments(x, y, noise)`**: examines each straight segment of the rubberband baseline and flags segments containing a genuine concave notch, distinguishing this from an ordinary single peak by checking whether an interior point sits below both of its neighbours while remaining above the noise threshold relative to the segment's chord.
- **`refine_segment(x, y, noise)`**: locally corrects one flagged segment by iteratively replacing each interior point with the smaller of its own value and the average of its neighbours, stopping once the change between iterations falls below the estimated noise level.

## 3. Not Yet Implemented

`detect_concave_segments()` and `refine_segment()` are each tested and working independently, but are not yet connected into `correct()` as a single automatic pipeline. `correct()` currently returns only the plain rubberband result.

Also not yet built:

- `print()`, `summary()`, and `plot()` S3 methods
- A `simulate_spectrum()` synthetic data generator
- A compiled C++ version of `refine_segment()`
- Validation against real spectroscopy data

## 4. Package Testing Plan (How to Check the Functions)

### Step A: Documentation

Confirm that documentation is complete by running `?lower_hull`, `?noise_estimate`, `?rubberband_baseline`, `?correct`, `?detect_concave_segments`, and `?refine_segment`, and checking that each function's arguments, return value, and purpose are described. No vignette is available at this stage.

### Step B: Baseline and Noise Functions

```r
# Rubberband baseline on a hand-worked example
lower_hull(c(1, 2, 3, 4, 5), c(5, 2, 3, 2, 5))

# Noise estimate on a known alternating sequence
noise_estimate(1:7, c(0, 2, 0, 2, 0, 2, 0))
```

### Step C: S3 Object and Rcpp-backed Correction

```r
model <- rubberband_baseline(c(1, 2, 3, 4, 5), c(5, 2, 3, 2, 5))
correct(model)
```

### Step D: Concave Segment Detection and Refinement

```r
# Detect a concave dip within a flat baseline segment
x <- 1:11
y <- c(0, 0, 0, 0.3, 0.5, 0.2, 0.5, 0.3, 0, 0, 0)
detect_concave_segments(x, y, noise = 0.1)

# Refine a flagged segment so the baseline follows the dip
refine_segment(x = 1:5, y = c(0, 2, 3, 2, 0), noise = 0.6)
```

### Step E: Automated Test Suite

```r
devtools::test()
```

Expected result: 27 tests, 0 failures.

### Step F: Deliberately Breaking the Functions

The steps above check that the functions work correctly on well-formed input. This step does the opposite. It feeds each function input it was never designed to handle, to see whether it fails safely with a clear error message or fails quietly in a way that would leave a user confused about what went wrong.

```r
# 1. Fewer than two points: a baseline needs at least two points to exist
lower_hull(1, 1)
noise_estimate(1, 1)

# 2. x and y of different lengths: every x value needs a matching y value
lower_hull(c(1, 2, 3), c(1, 2))

# 3. A noise value of zero or negative: noise is a threshold, and a threshold
# of zero or below does not correspond to anything physically meaningful
detect_concave_segments(1:5, c(0, 1, 2, 1, 0), noise = 0)
detect_concave_segments(1:5, c(0, 1, 2, 1, 0), noise = -1)

# 4. Repeated x values: two points sharing the same x is not something any
# existing test covers, and it is unclear whether the hull algorithm and the
# interpolation step handle this cleanly or just fail quietly
lower_hull(c(1, 2, 2, 4, 5), c(5, 3, 1, 3, 5))
```

The first two lines are already covered by the automated test suite and are expected to produce a clear error. Running them here is just independent confirmation that they behave as documented. The remaining three are not covered by any existing test, so whatever happens here is genuinely new information, and it will show exactly which functions still need input checks added before the package is finished.
