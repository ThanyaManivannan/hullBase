# Peer Assessment Plan: hullBase Package

**Assessor:** Jennifer Hanna

## 1. Repository Link and Installation

Repository: https://github.com/ThanyaManivannan/hullBase

Install and load the package with the following commands. The package
contains C++ code, so installing on Windows needs
[Rtools](https://cran.r-project.org/bin/windows/Rtools/).

```r
install.packages("devtools")
devtools::install_github("ThanyaManivannan/hullBase", build_vignettes = TRUE)
```

The unit tests are not part of the installed package. To run them, clone
or download the repository, open `hullBase.Rproj` in RStudio, and use the
commands in Step B given below.

## 2. Overview of Implemented Functions

hullBase performs baseline correction of spectra such as FTIR spectra with
the rubberband (lower convex hull) method. The rubberband baseline cannot
follow a concave (dome shaped) baseline, so the package adds an automatic
local bending step that finds and corrects those regions. All functions
are implemented.

**Main function and S3 methods**

* `correct()` runs the full correction and returns a `BaselineModel`
  object. It has a default method for `x` and `y` vectors and a method for
  data frames with `x` and `y` columns. `method = "rubberband"` gives the
  plain rubberband baseline for comparison.
* `print()`, `summary()` and `plot()` are methods for `BaselineModel`
  objects.

**Steps of the method**

* `noise_estimate()` estimates the noise standard deviation as the MAD of
  the second differences divided by the square root of 6.
* `lower_hull()` computes the plain rubberband baseline with the monotone
  chain algorithm.
* `detect_concave_segments()` finds hull segments that hide a concave
  baseline, using a moving minimum (erosion) and a noise based threshold.
* `refine_segment()` corrects one segment by bending it, taking the lower
  hull, and unbending it.

**Test data**

* `simulate_spectrum()` builds a spectrum with a known baseline from
  Gaussian peaks, a baseline shape (`"concave"`, `"linear"`, `"convex"`,
  `"flat"`, `"mixed"`) and Gaussian noise.

**Compiled code (internal)**

* `lower_hull_cpp()` and `erode_cpp()` are written in C++ with Rcpp. Plain R
  versions `lower_hull_r()` and `erode()` are kept for comparison. These are
  not exported, so they are reached with `hullBase:::`.

## 3. Package Testing Plan

### Step A: Package Structure and Documentation

1. Check the repository contains `DESCRIPTION`, `NAMESPACE`, `LICENSE`,
   `R/`, `src/`, `man/`, `tests/` and `vignettes/`.
2. Open the help pages and check that the arguments, return values and
   examples are documented.

```r
help(package = "hullBase")
?correct
?detect_concave_segments
?refine_segment
```

3. Open the vignette, which explains the method, formulas, results and
   limitations.

```r
vignette("hullBase")
```

4. Run the help page examples.

```r
example(correct)
example(refine_segment)
```

### Step B: Run the Package Tests

From the cloned repository in RStudio:

```r
devtools::test()
# Expected: [ FAIL 0 | WARN 0 | SKIP 0 | PASS 450 ]

devtools::check()
# Expected: 0 errors | 0 warnings | 0 notes
```

### Step C: Check the Individual Functions

Each result below can be checked by hand or against a known value.

```r
# Plain rubberband on a small example
lower_hull(1:5, c(5, 2, 3, 2, 5))
# Expected: 5 2 2 2 5

# Noise estimate on a hand worked example and on a noise free curve
noise_estimate(1:7, c(0, 0, 1, 0, 0, 0, 0))
# Expected: 0.6052689  (equal to 1.4826 / sqrt(6))
noise_estimate(1:10, (1:10)^2)
# Expected: 0

# Simulated spectrum with a concave baseline
set.seed(1)
sim <- simulate_spectrum(baseline = "concave")
head(sim)
attr(sim, "noise_sd")
# Expected: 0.03223082

# Concave segment detection
detect_concave_segments(sim$x, sim$y, peak_width = 300)
# Expected: one segment flagged TRUE, from x = 13 to x = 1396

# Local bending recovers a parabola shaped dome exactly
x <- seq(0, 10, length.out = 201)
dome <- 2 * (1 - ((x - 5) / 5)^2)
max(abs(refine_segment(x, dome, peak_width = 0.5, noise = 0) - dome))
# Expected: 0
```

### Step D: Check the S3 Methods

```r
fit <- correct(sim, peak_width = 300)
fit
summary(fit)
plot(fit)
plot(fit, which = "corrected")

# Compare with the plain rubberband baseline using the known true baseline
plain <- correct(sim, method = "rubberband")
sqrt(mean((plain$baseline - sim$baseline)^2))
# Expected: 0.7370946
sqrt(mean((fit$baseline - sim$baseline)^2))
# Expected: 0.05416515
```

`print` should show the method, number of points, noise level and number
of refined segments. `summary` should list the refined segment. The plot
should show the plain rubberband baseline as a red dashed line, the
corrected baseline in blue, and the refined segment shaded.

### Step E: Check the Compiled Code

The C++ functions should give exactly the same results as the R versions.

```r
set.seed(2)
g <- rnorm(500)
identical(hullBase:::erode_cpp(g, 20), hullBase:::erode(g, 20))
# Expected: TRUE
identical(hullBase:::lower_hull_cpp(1:500, g), hullBase:::lower_hull_r(1:500, g))
# Expected: TRUE
```

### Step F: Injecting Errors

Please try the following inputs and report whether each one gives a clear
error or warning message.

```r
# 1. Fewer than 5 points
lower_hull(1:4, 1:4)

# 2. x and y of different lengths
lower_hull(1:6, 1:5)

# 3. Missing or infinite values
lower_hull(1:5, c(1, NA, 1, 1, 1))
noise_estimate(1:5, c(1, 1, Inf, 1, 1))

# 4. Repeated x values
lower_hull(c(1, 2, 2, 3, 4), 1:5)

# 5. Text instead of numbers
lower_hull(letters[1:5], 1:5)

# 6. Unevenly spaced x (should give a warning, not an error)
noise_estimate(c(1, 2, 3, 5, 6, 7), 1:6)

# 7. Missing or invalid peak_width
correct(sim)
correct(sim, peak_width = 0)
correct(sim, peak_width = "wide")

# 8. Invalid settings
correct(sim, peak_width = 300, noise = -1)
correct(sim, peak_width = 300, bend_factor = 0.5)
correct(sim, peak_width = 300, max_depth = 0)
correct(sim, peak_width = 300, method = "spline")

# 9. A data frame without x and y columns
correct(data.frame(a = 1:5, b = 1:5))

# 10. Invalid simulation settings
simulate_spectrum(baseline = "wavy")
simulate_spectrum(noise_sd = -1)
simulate_spectrum(peaks = data.frame(height = 1, centre = 5, width = 0))

# 11. Invalid plot option
plot(fit, which = "both")
```

## 4. Known Limitations

These are expected behaviours, described in the vignette.

* `peak_width` must cover the widest peak or group of overlapping peaks.
  If it is too small, overlapping peaks can be mistaken for a concave
  baseline, for example `peak_width = 100` on the simulated spectrum.
* A peak wider than `peak_width` is partly removed as background.
* Like any rubberband baseline, the result sits slightly below the true
  baseline because the hull rests on the lowest noise values.
