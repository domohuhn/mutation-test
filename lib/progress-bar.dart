/// Copyright 2021, domohuhn. 
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license

import 'package:mutation_test/errors.dart';

/// Renders a progress bar as string.
class ProgressBar {
  ProgressBar(this.maximum, {this.width = 30, this.widthIncludesText = true,
  this.showPercent = true, this.showTotal = true, this.totalSuffix = '',
  this.left = '[', this.right=']', this.bar='=', this.blank=' ', this.partial='>'});
  int current = 0;
  int maximum;
  int width;
  bool widthIncludesText;
  String left = '[';
  String bar = '=';
  String blank = ' ';
  String partial = '>';
  String right = ']';
  String totalSuffix = '';
  bool showPercent = true;
  bool showTotal = true;

  void update(int count) {
    current += count;
  }

  double get progress => (current.toDouble()/maximum.toDouble()).clamp(0.0, 1.0);

  @override 
  String toString() {
    var rv = left;
    var percent = 100*progress;
    
    var suffix = right;
    var textLength = rv.length+suffix.length;
    if (showPercent) {
      suffix += '${percent.toStringAsFixed(0)}%'.padLeft(5);
      textLength += 4;
    }
    if (showTotal) {
      var tmp = current!=maximum ? ' ($current/$maximum$totalSuffix)' : ' ($maximum$totalSuffix)';
      textLength += tmp.length;
      suffix += tmp;
    }
    if (widthIncludesText && textLength>=width) {
      throw MutationError('Progress bar is too small! width: $width text width: $textLength');
    }
    final space = widthIncludesText ? width-textLength : width-left.length-right.length;
    var lower = (space*progress).truncate();
    final real = space.toDouble()*progress;
    if(current!=maximum) {
      rv += bar*lower;
      if(lower<real && lower+1<=space) {
        rv += partial;
        lower += 1;
      } else if (lower==real&&lower>0) {
        rv = rv.substring(0,rv.length-1) + partial;
      }
    } else {
      rv += bar*lower;
    }
    var rest = space-lower;
    if(rest>0) {
      rv += blank*rest;
    }
    return rv+suffix;
  }
}


