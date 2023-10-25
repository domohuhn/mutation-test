// Copyright 2021, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/core/range.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  var text1 = 'smoe\nthing/**s\n*f\nsdf */*x;\n';
  var text2 = 'smoe\nthing// comment ad\n*x;\n';
  var text3 = 'ghbh\nfor(asd;sdf;sd++){\n*x;\n';
  var exclusion1 = TokenRange('/*', '*/');
  var exclusion2 = TokenRange('//', '\n');
  var exclusion3 = LineRange(2, 3);
  var exclusion4 = RegexRange(RegExp(r'\/[*].*?[*]\/', dotAll: true));
  var exclusion5 = RegexRange(RegExp(
    r'//.*\n',
  ));
  var exclusion6 = RegexRange(RegExp(r'[\s]for[\s]*\([\s\S].*?\)[\s]*{'));

  test('exclusion multiline 1', () {
    for (var i = 0; i < text1.length; i++) {
      expect(exclusion1.isInRange(text1, i), i >= 10 && i <= 23);
    }
  });

  test('exclusion multiline 2', () {
    for (var i = 0; i < text2.length; i++) {
      expect(exclusion1.isInRange(text2, i), false);
    }
  });

  test('exclusion single line 1', () {
    for (var i = 0; i < text2.length; i++) {
      expect(exclusion2.isInRange(text2, i), i >= 10 && i <= 23);
    }
  });

  test('exclusion single line 2', () {
    for (var i = 0; i < text1.length; i++) {
      expect(exclusion2.isInRange(text1, i), false);
    }
  });

  var source2 = File('example/source2.dart').readAsStringSync();
  source2 = source2.replaceAll('\r', '');
  test('exclusion single line 3', () {
    expect(exclusion2.isInRange(source2, 314), false);
    expect(exclusion2.isInRange(source2, 315), true);
    expect(exclusion2.isInRange(source2, 316), true);
    expect(exclusion2.isInRange(source2, 317), true);
  });

  test('exclusion multiline source2', () {
    for (var i = 0; i < 150; i++) {
      expect(exclusion1.isInRange(source2, i), 103 <= i && i <= 132);
      expect(exclusion4.isInRange(source2, i), 103 <= i && i <= 132);
    }
  });

  test('exclusion lines 1', () {
    for (var i = 0; i < text1.length; i++) {
      expect(exclusion3.isInRange(text1, i), 5 <= i && i <= 17);
    }
  });

  test('exclusion lines 2', () {
    for (var i = 0; i < text2.length; i++) {
      expect(exclusion3.isInRange(text2, i), 5 <= i);
    }
  });

  group('Regex exclusion', () {
    test('exclusion multiline 1', () {
      for (var i = 0; i < text1.length; i++) {
        expect(exclusion4.isInRange(text1, i), i >= 10 && i <= 23);
      }
    });

    test('exclusion multiline 2', () {
      for (var i = 0; i < text2.length; i++) {
        expect(exclusion4.isInRange(text2, i), false);
      }
    });

    test('exclusion single line 1', () {
      for (var i = 0; i < text2.length; i++) {
        expect(exclusion5.isInRange(text2, i), i >= 10 && i <= 23);
      }
    });

    test('exclusion single line 2', () {
      for (var i = 0; i < text1.length; i++) {
        expect(exclusion5.isInRange(text1, i), false);
      }
    });

    test('exclusion for', () {
      for (var i = 0; i < text3.length; i++) {
        expect(exclusion6.isInRange(text3, i), 4 <= i && i <= 22);
      }
    });
  });

  group('String exclusion', () {
    final exclusionStrDoubleQuote = TokenRange('"', '";');
    final exclusionStrSingleQuote = TokenRange('\'', '\';');

    const textStrSingleQuote =
        'var x = \' moo + meow \';\n// a bunch of additional text\n';
    const textStrDoubleQuote =
        'var x = " moo + meow ";\n// a bunch of additional text\n';

    test('double quote strings', () {
      for (var i = 0; i < textStrSingleQuote.length; i++) {
        expect(exclusionStrDoubleQuote.isInRange(textStrSingleQuote, i), false);
        expect(exclusionStrDoubleQuote.isInRange(textStrDoubleQuote, i),
            8 <= i && i <= 21);
      }
    });
    test('single quote strings', () {
      for (var i = 0; i < textStrSingleQuote.length; i++) {
        expect(exclusionStrSingleQuote.isInRange(textStrSingleQuote, i),
            8 <= i && i <= 21);
        expect(exclusionStrSingleQuote.isInRange(textStrDoubleQuote, i), false);
      }
    });
  });
}
