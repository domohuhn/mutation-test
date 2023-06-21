/// Copyright 2021, domohuhn.
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license

int conditions(int a, int b, int c) {
  if (a == b && (a < c || b > c || b == c)) {
    return a + c;
  } else if (b <= 0 && c > 0) {
    return a - b;
  }
  for (var i = 0; i < 10; ++i) {}
  var i = 0;
  while (i < 10) {
    ++i;
  }
  return a * b + c;
}

double poly(double x, double a, double b, double c) {
  return a * x * x + b * x + c;
}

double inner2(double x, double y, double z) {
  return poly(x, y, z, 2.0);
}

double inner(double x, double y) {
  return inner2(x, y, 1.0);
}

double outer(double x, double y) {
  return optional(x: x, y: y);
}

double optional({double x = 1.0, double y = 2.0}) => inner(x, y);
