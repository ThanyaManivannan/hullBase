#include <Rcpp.h>
#include <deque>
using namespace Rcpp;

//' Moving Minimum (Erosion) in C++
//'
//' Same result as `erode()`, computed with a monotone queue so the work
//' does not grow with the window size. The queue holds positions whose
//' values increase from front to back. A new value removes every larger
//' value from the back, positions that have left the window are removed
//' from the front, and the front is the minimum of the current window.
//'
//' @param g Numeric vector.
//' @param m Window half width, in number of points.
//'
//' @return A numeric vector the same length as `g`.
//'
//' @references
//' Lemire, D. (2006). Streaming maximum-minimum filter using no more than
//' three comparisons per element. Nordic Journal of Computing, 13(4),
//' 328 to 339.
//'
//' @keywords internal
// [[Rcpp::export]]
NumericVector erode_cpp(NumericVector g, int m) {
  int n = g.size();
  NumericVector out(n);
  std::deque<int> window;  // positions of the candidates for the minimum
  int next = 0;            // next position still to be added

  for (int i = 0; i < n; i++) {
    // add every point up to the right edge of this window
    int hi = std::min(n - 1, i + m);
    while (next <= hi) {
// a larger value at the back can never be the minimum again
      while (!window.empty() && g[window.back()] >= g[next]) {
        window.pop_back();
      }
      window.push_back(next);
      next++;
    }

// drop positions that are now left of the window
    int lo = std::max(0, i - m);
    while (window.front() < lo) {
      window.pop_front();
    }

    out[i] = g[window.front()];
  }
  return out;
}
