// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/configuration/coverage.dart';
import 'package:mutation_test/src/core/system_interactions.dart';
import 'package:test/test.dart';

void main() {
  var reader = SystemInteractions(true, true);
  group('Dart coverage', () {
    final contents =
        reader.readFile('test/configuration/dart_coverage_lcov.info');

    test('parse without error', () {
      var coverage = ProjectLineCoverage.fromLCOV(contents);
      expect(
          coverage.isCoveredByTests(
              'lib\\src\\configuration\\configuration.dart', 84),
          true);
      expect(
          coverage.isCoveredByTests(
              'lib\\src\\configuration\\configuration.dart', 85),
          false);
      expect(
          coverage.isCoveredByTests(
              'lib\\src\\configuration\\configuration.dart', 84, 84),
          true);
      expect(
          coverage.isCoveredByTests(
              'lib\\src\\configuration\\configuration.dart', 85, 85),
          false);
      expect(
          coverage.isCoveredByTests(
              'lib\\src\\configuration\\configuration.dart', 86),
          true);
      expect(
          coverage.isCoveredByTests(
              'lib\\src\\configuration\\configuration.dart', 87),
          true);

      expect(
          coverage.isCoveredByTests(
              'lib\\src\\configuration\\configuration.dart', 85, 86),
          false);
      expect(
          coverage.isCoveredByTests(
              'lib\\src\\configuration\\configuration.dart', 85, 87),
          true);

      expect(
          coverage.isCoveredByTests(
              'lib\\src\\configuration\\configuration.dart', 85, 86),
          false);

      // path not found - should return true
      expect(coverage.isCoveredByTests('configuration.dart', 85, 86), true);
      expect(
          coverage.isCoveredByTests(
              'lib\\src\\configuration\\configuration.dart', 85, 87),
          true);
    });

    test('no record started', () {
      expect(() => ProjectLineCoverage.fromLCOV('DA:12,1'), throwsException);
    });

    test('no record started 2', () {
      expect(
          () => ProjectLineCoverage.fromLCOV('end_of_record'), throwsException);
    });

    test('no end of record', () {
      expect(
          () => ProjectLineCoverage.fromLCOV('SF:/moo.dart\nSF:/moo2.dart\n'),
          throwsException);
    });

    test('parse error', () {
      expect(
          () => ProjectLineCoverage.fromLCOV(
              'SF:/moo.dart\nDA:125\nend_of_record'),
          throwsException);
    });
    test('parse error 2', () {
      expect(
          () => ProjectLineCoverage.fromLCOV(
              'SF:/moo.dart\nDA:a,b\nend_of_record'),
          throwsException);
    });
  });

  group('Cpp coverage', () {
    final contents = reader.readFile('test/configuration/lcov.info');

    test('parse without error', () {
      try {
        var coverage = ProjectLineCoverage.fromLCOV(contents);
        expect(coverage.isCoveredByTests('/usr/include/c++/9/bits/move.h', 98),
            true);
        expect(coverage.isCoveredByTests('/usr/include/c++/9/bits/move.h', 99),
            true);
      } catch (e) {
        fail('Exception $e was thrown');
      }
    });
  });
}
