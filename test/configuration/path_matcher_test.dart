// Copyright 2026, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/configuration/path_matcher.dart';
import 'package:test/test.dart';

void main() {
  group('parse paths', () {
    test('no wildcard', () {
      final matcher = PathMatcher('this/is/a/path/without/wildcards', false);
      expect(matcher.patterns.length, 1);
      print(matcher.patterns[0]);
      expect(matcher.patterns[0], 'this/is/a/path/without/wildcards');
    });

    test('one wildcard 1', () {
      final matcher = PathMatcher('this/is/a/path/with/*/wildcards', false);
      expect(matcher.patterns.length, 3);
      expect(matcher.patterns[0], 'this/is/a/path/with/');
      expect(matcher.patterns[1], '*');
      expect(matcher.patterns[2], '/wildcards');
    });

    test('one wildcard 2', () {
      final matcher = PathMatcher('this/is/a/path/with/**/wildcards', false);
      expect(matcher.patterns.length, 3);
      expect(matcher.patterns[0], 'this/is/a/path/with/');
      expect(matcher.patterns[1], '**');
      expect(matcher.patterns[2], '/wildcards');
    });

    test('one wildcard 3', () {
      final matcher = PathMatcher('this/is/a/path/with/****/wildcards', false);
      expect(matcher.patterns.length, 3);
      expect(matcher.patterns[0], 'this/is/a/path/with/');
      expect(matcher.patterns[1], '**');
      expect(matcher.patterns[2], '/wildcards');
    });

    test('one wildcard 4', () {
      final matcher = PathMatcher('this/is/a/path/with/*', false);
      expect(matcher.patterns.length, 2);
      expect(matcher.patterns[0], 'this/is/a/path/with/');
      expect(matcher.patterns[1], '*');
    });

    test('one wildcard 5', () {
      final matcher = PathMatcher('this/is/a/path/with/**', false);
      expect(matcher.patterns.length, 2);
      expect(matcher.patterns[0], 'this/is/a/path/with/');
      expect(matcher.patterns[1], '**');
    });

    test('one wildcard 6', () {
      final matcher = PathMatcher('this/is/a/path/with*', false);
      expect(matcher.patterns.length, 2);
      expect(matcher.patterns[0], 'this/is/a/path/with');
      expect(matcher.patterns[1], '*');
    });

    test('one wildcard 7', () {
      final matcher = PathMatcher('this/is/a/path/with/*.dart', false);
      expect(matcher.patterns.length, 3);
      expect(matcher.patterns[0], 'this/is/a/path/with/');
      expect(matcher.patterns[1], '*');
      expect(matcher.patterns[2], '.dart');
    });
  });

  group('match paths', () {
    final inputs = [
      'this/is/a/path/without/wildcards/more/paths/file.dart',
      'this/is/a/path/without/wildcards',
      'this/is/o/path/without/wildcards/more/paths/file.dart',
      'this/is/a/path/without/wildcard/more/paths/file.dart',
      'this/is/a/path/with/other/wildcards/more/paths/file.dart',
      'this/is/a/path/with/first/second/wildcards/more/paths/file.dart',
      'this/is/a/path/with/other/wildcards',
      'this/is/a/path/with/first/second/wildcards',
      'this/is/a/path/with/other/wildcard/more/paths/file.dart',
      'this/is/a/path/with_no_dirs_as_tail.dart',
      'this/is/a/path/with/file.dart',
    ];
    test('no wildcard', () {
      final p = PathMatcher('this/is/a/path/without/wildcards', true);
      final outputs = [
        true,
        true,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false
      ];
      for (final path in inputs.indexed) {
        expect(p.matches(path.$2), outputs[path.$1]);
      }
    });

    test('no wildcard no tail', () {
      final p = PathMatcher('this/is/a/path/without/wildcards', false);
      final outputs = [
        false,
        true,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false
      ];
      for (final path in inputs.indexed) {
        expect(p.matches(path.$2), outputs[path.$1]);
      }
    });

    test('one wildcard 1', () {
      final p = PathMatcher('this/is/a/path/with/*/wildcards', true);

      final outputs = [
        false,
        false,
        false,
        false,
        true,
        false,
        true,
        false,
        false,
        false,
        false
      ];
      for (final path in inputs.indexed) {
        expect(p.matches(path.$2), outputs[path.$1]);
      }
    });

    test('one wildcard 1 no tail', () {
      final p = PathMatcher('this/is/a/path/with/*/wildcards', false);

      final outputs = [
        false,
        false,
        false,
        false,
        false,
        false,
        true,
        false,
        false,
        false,
        false
      ];
      for (final path in inputs.indexed) {
        expect(p.matches(path.$2), outputs[path.$1]);
      }
    });

    test('one wildcard 2', () {
      final p = PathMatcher('this/is/a/path/with/**/wildcards', true);
      final outputs = [
        false,
        false,
        false,
        false,
        true,
        true,
        true,
        true,
        false,
        false,
        false
      ];
      for (final path in inputs.indexed) {
        expect(p.matches(path.$2), outputs[path.$1]);
      }
    });

    test('one wildcard 3', () {
      final p = PathMatcher('this/is/a/path/with/****/wildcards', true);
      final outputs = [
        false,
        false,
        false,
        false,
        true,
        true,
        true,
        true,
        false,
        false,
        false
      ];
      for (final path in inputs.indexed) {
        expect(p.matches(path.$2), outputs[path.$1]);
      }
    });

    test('one wildcard 4', () {
      final p = PathMatcher('this/is/a/path/with/*', true);
      final outputs = [
        false,
        false,
        false,
        false,
        true,
        true,
        true,
        true,
        true,
        false,
        true
      ];
      for (final path in inputs.indexed) {
        expect(p.matches(path.$2), outputs[path.$1]);
      }
    });

    test('one wildcard 5', () {
      final p = PathMatcher('this/is/a/path/with/**', true);
      final outputs = [
        false,
        false,
        false,
        false,
        true,
        true,
        true,
        true,
        true,
        false,
        true
      ];
      for (final path in inputs.indexed) {
        expect(p.matches(path.$2), outputs[path.$1]);
      }
    });

    test('one wildcard 6', () {
      final p = PathMatcher('this/is/a/path/with*', true);
      final outputs = [
        true,
        true,
        false,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true
      ];
      for (final path in inputs.indexed) {
        expect(p.matches(path.$2), outputs[path.$1]);
      }
    });

    test('one wildcard 6b', () {
      final p = PathMatcher('this/is/a/path/with**', true);
      final outputs = [
        true,
        true,
        false,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true
      ];
      for (final path in inputs.indexed) {
        expect(p.matches(path.$2), outputs[path.$1]);
      }
    });

    test('one wildcard 6 no tail', () {
      final p = PathMatcher('this/is/a/path/with*', false);
      final outputs = [
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        true,
        false
      ];
      for (final path in inputs.indexed) {
        expect(p.matches(path.$2), outputs[path.$1]);
      }
    });

    test('one wildcard 7', () {
      final p = PathMatcher('this/is/a/path/with/*.dart', true);
      final outputs = [
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        true
      ];
      for (final path in inputs.indexed) {
        expect(p.matches(path.$2), outputs[path.$1]);
      }
    });
  });
}
