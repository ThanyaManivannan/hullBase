#include <Rcpp.h>
using namespace Rcpp;

// Computes the lower convex hull of points (x, y), assuming x is already
// sorted in increasing order. Returns the 1-based indices of the points
// that lie on the hull, in left-to-right order.
// [[Rcpp::export]]
IntegerVector lower_hull_cpp(NumericVector x, NumericVector y) {
  int n = x.size();
  std::vector<int> hull;  // 0-based indices of hull points found so far

  for (int i = 0; i < n; i++) {
    // drop the last hull point while the turn (second-last -> last -> i) is not a left turn
    while (hull.size() >= 2) {
      int o = hull[hull.size() - 2];
      int a = hull[hull.size() - 1];
      double cross_val = (x[a] - x[o]) * (y[i] - y[o]) - (y[a] - y[o]) * (x[i] - x[o]);
      if (cross_val <= 0) {
        hull.pop_back();
      } else {
        break;
      }
    }
    hull.push_back(i);
  }

  IntegerVector out(hull.size());
  for (unsigned int i = 0; i < hull.size(); i++) {
    out[i] = hull[i] + 1;  // convert to R's 1-based indexing
  }
  return out;
}
