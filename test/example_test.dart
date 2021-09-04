/// Copyright 2021, domohuhn. 
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license
import '../example/source.dart';
import 'package:test/test.dart';

// This file is an example for a bad test.
// It is used to generate the reports in directory example.

void main() {
  test('polynomial', () {
     expect(poly(2.0,1.0,4.0,0.0),12.0);
  });

  test('conditions first', () {
     expect(conditions(2,2,4),6);
  });

  test('conditions second', () {
     expect(conditions(2,-3,4),5);
  });

  test('conditions third', () {
     expect(conditions(2,3,0),6);
  });
}

