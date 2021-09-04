/// Copyright 2021, domohuhn. 
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license
import 'package:mutation_test/string-helpers.dart';
import 'package:test/test.dart';

void main() {
  var text = '''  This is a long string.
  Another line.
  More!
  MORE!
  MOOOOORE!

  Ok, this may be enough lines.
  ''';
  test('Find line number', () {
    expect(findLineFromPosition(text, 45), 3);
  });

  test('Find start of line', () {
    expect(findBeginOfLineFromPosition(text, 45), 41);
  });

  test('Find end of line', () {
    expect(findEndOfLineFromPosition(text, 45), 48);
  });
}

