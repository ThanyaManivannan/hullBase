#include <Rcpp.h>
using namespace Rcpp;

//' Lower Hull Vertices in C++
//'
//' Andrew's monotone chain for the lower convex hull. For three points O,
//' A and B, A is removed while the cross product
//' `(xA - xO) * (yB - yO) - (yA - yO) * (xB - xO)` is zero or less.
//'
//' @param x Numeric vector of wavenumbers, sorted increasing.
//' @param y Numeric vector of values in the same order.
//'
//' @return Integer vector of the positions (starting at 1) of the hull
//'   vertices, from left to right.
//'
//' @keywords internal
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
