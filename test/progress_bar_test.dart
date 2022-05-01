/// Copyright 2021, domohuhn.
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license

import 'package:mutation_test/src/progress_bar.dart';
import 'package:test/test.dart';

void main() {
  test('Progress bar - Empty ', () {
    var bar = ProgressBar(80);
    bar.totalSuffix = 'MB';
    expect(bar.toString(), '[               ]   0% (0/80MB)');
  });

  test('Progress bar - Start ', () {
    var bar = ProgressBar(80);
    bar.totalSuffix = 'MB';
    bar.update(1);
    expect(bar.toString(), '[>              ]   1% (1/80MB)');
  });

  test('Progress bar - Half ', () {
    var bar = ProgressBar(80, width: 50);
    bar.totalSuffix = 'MB';
    bar.update(40);
    expect(bar.toString(), '[================>                 ]  50% (40/80MB)');
  });

  test('Progress bar - Almost full ', () {
    var bar = ProgressBar(80, width: 50);
    bar.totalSuffix = 'MB';
    bar.update(79);
    expect(bar.toString(), '[=================================>]  99% (79/80MB)');
  });

  test('Progress bar - Full ', () {
    var bar = ProgressBar(80, width: 50);
    bar.totalSuffix = 'MB';
    bar.update(80);
    expect(bar.toString(), '[=====================================] 100% (80MB)');
  });

  test('Progress bar - No total ', () {
    var bar = ProgressBar(80, width: 50);
    bar.showTotal = false;
    bar.totalSuffix = 'MB';
    bar.update(40);
    expect(bar.toString(), '[=====================>                      ]  50%');
  });

  test('Progress bar - No percent ', () {
    var bar = ProgressBar(80, width: 50);
    bar.showPercent = false;
    bar.totalSuffix = 'MB';
    bar.update(40);
    expect(bar.toString(), '[==================>                   ] (40/80MB)');
  });

  test('Progress bar - No text ', () {
    var bar = ProgressBar(80, width: 30);
    bar.showPercent = false;
    bar.showTotal = false;
    bar.update(40);
    expect(bar.toString(), '[=============>              ]');
  });

  test('Progress bar - Ignore text for width', () {
    var bar = ProgressBar(80, widthIncludesText: false);
    bar.totalSuffix = 'MB';
    bar.update(40);
    expect(bar.toString(), '[=============>              ]  50% (40/80MB)');
  });
}
