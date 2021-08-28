import 'package:mutation_test/range.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  var text1 = 'smoe\nthing/**s df\nsdf */*x;\n';
  var text2 = 'smoe\nthing// comment ad\n*x;\n';
  var exclusion1 = Range('/*', '*/');
  var exclusion2 = Range('//', '\n');
  test('exclusion multiline 1', () {
    for (var i=0;i<text1.length;i++) {
      expect(exclusion1.isInRange(text1, i), i>=10&&i<=23);
    }
  });
  
  test('exclusion multiline 2', () {
    for (var i=0;i<text2.length;i++) {
      expect(exclusion1.isInRange(text2, i), false);
    }
  });

  test('exclusion singleline 1', () {
    for (var i=0;i<text2.length;i++) {
      expect(exclusion2.isInRange(text2, i), i>=10&&i<=23);
    }
  });
  
  test('exclusion singleline 2', () {
    for (var i=0;i<text1.length;i++) {
      expect(exclusion2.isInRange(text1, i), false);
    }
  });

  test('exclusion singleline 3', () {
    final source = File('example/source2.dart').readAsStringSync();
    expect(exclusion2.isInRange(source, 201), false);
    expect(exclusion2.isInRange(source, 202), true);
    expect(exclusion2.isInRange(source, 203), true);
    expect(exclusion2.isInRange(source, 204), true);
  });
}
