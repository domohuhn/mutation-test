

int conditions(int a, int b, int c) {
  if (a==b && (a<c || b>c || b==c)) {
    return a+c;
  } else if (b<= 0 && c > 0) {
    return a-b;
  }
  for(var i=0;i<10;++i) {
  }
  var i=0;
  while(i<10) {
    ++i;
  }
  return a * b + c;
}

double poly(double x, double a, double b, double c) {
  return a*x*x + b * x + c;
}

