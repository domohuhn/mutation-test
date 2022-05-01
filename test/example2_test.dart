/// Copyright 2021, domohuhn.
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license
import '../example/source2.dart';
import 'package:test/test.dart';

// This file is an example for a bad test.
// It is used to generate the reports in directory example.

void main() {
  var data = TestData();
  test('TestData calc', () {
    expect(data.calc(0.0), 0.0);
  });

  test('TestData format 1', () {
    expect(data.format(0.0), 'default 0.0');
  });

  test('TestData format 2', () {
    expect(data.format(-2.0), 'default -2.0');
  });

  test('TestData format 3', () {
    expect(data.format(2.0), 'default 2.0');
  });
}
