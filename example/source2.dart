

/* multi line
 * comment
 */
class TestData {
  String text = 'default';
  double number1 = 25.0;
  double number2 = 25.0;

  double calc(double x) {
    return number1*x/number2;
  }

 // just a weird example ...
  String format(double y) {
    if (y<=0.0 && text != '') {
      return '$text $y';
    } else if ( y==0.0
        && text != '') {
      return '$text $y';
    }
    return 'default $y';
  }

}

