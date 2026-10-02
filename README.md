# hullBase

hullBase is an R package for baseline correction of spectra such as FTIR
spectra. It uses the rubberband (lower convex hull) method and adds a fix
for its main limitation.

## The problem

The rubberband baseline can only bend upwards. When the true baseline is
concave (dome shaped), the rubberband draws a straight line underneath it
and part of the background is left in the corrected spectrum.

## The improvement

hullBase finds the parts of the hull that hide a dome and corrects each
one by bending it locally, taking the hull, and unbending it. Where to
bend and how strongly are calculated from the spectrum itself, so the
only setting is the expected peak width.

## Installation

```r
install.packages("devtools")
devtools::install_github("ThanyaManivannan/hullBase", build_vignettes = TRUE)
```

Installing from source compiles C++ code, which on Windows needs
[Rtools](https://cran.r-project.org/bin/windows/Rtools/). The Windows
binary `.zip` on the Releases page installs without Rtools.

## Example

```r
library(hullBase)

set.seed(1)
sim <- simulate_spectrum(baseline = "concave")
fit <- correct(sim, peak_width = 300)
fit
#> <BaselineModel>
#>   method : adaptive (local bending)
#>   points : 1401 from 0 to 1400
#>   noise  : 0.0335
#>   concave segments refined: 1 of 5

summary(fit)
plot(fit)
```

## Functions

* `correct()` runs the full correction and returns a `BaselineModel` object
* `print()`, `summary()` and `plot()` are methods for `BaselineModel` objects
* `simulate_spectrum()` builds a test spectrum with a known baseline
* `noise_estimate()` estimates the noise level from second differences
* `lower_hull()` gives the plain rubberband baseline
* `detect_concave_segments()` finds hull segments that hide a concave baseline
* `refine_segment()` corrects one segment by local bending

The method, formulas and limitations are explained in the vignette.

```r
vignette("hullBase")
```

## Results

Average baseline error (RMSE) over 20 simulated spectra for each baseline
shape and noise level.

```r
#>     shape snr_db rubberband adaptive
#> 1 concave     30      0.745    0.056
#> 2 concave     25      0.796    0.114
#> 3 concave     20      0.895    0.223
#> 4   mixed     30      0.787    0.069
#> 5   mixed     25      0.823    0.105
#> 6   mixed     20      0.904    0.204
#> 7    flat     30      0.089    0.089
#> 8  linear     30      0.086    0.086
#> 9  convex     30      0.057    0.057
```

For concave and mixed baselines the error is 4 to 13 times smaller. For
flat, linear and convex baselines the result is the same as the plain
rubberband.

## References

Beleites, C. (2015). Fitting baselines to spectra. hyperSpec package
vignette.

Zhang, F., Tang, X., Tong, A., Wang, B. and Wang, J. (2020). An automatic
baseline correction method based on the penalized least squares method.
Sensors, 20, 2015.

## License

MIT
