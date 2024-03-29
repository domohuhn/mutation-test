// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/mutation_test.dart';
import 'package:mutation_test/src/core/core.dart';
import 'package:test/test.dart';
import 'core/mock_platform_factory.dart';
import 'core/mock_test_runner.dart';

MutationTest createMutationTest(bool addInFile, bool dry) {
  final mutations = MutationTest(
      addInFile ? [configPath] : [], 'out', true, dry, ReportFormat.NONE,
      ruleFiles: [],
      builtinRules: true,
      quiet: true,
      platform: MockPlatformFactory());

  final factory = mutations.platformFactory as MockPlatformFactory;
  final system = factory.system!;
  system.useRealFileSystem = false;
  system.rvFiles = [file1Path, file2Path];
  system.rvFileContents[file1Path] = file1;
  system.rvFileContents[file2Path] = file2;
  system.rvFileContents[configPath] = config;
  system.rvFileContents['pubspec.yaml'] = 'bla';
  final runner = factory.createTestRunner() as MockTestRunner;
  runner.rvReport = TestReport(TestResult.Undetected);
  return mutations;
}

const total_mutations = 74;
const total_writes = total_mutations + 2;
const total_reads = 2 * 2 + 2;

void main() async {
  group('default config', () {
    test('Dry run', () async {
      final mutations = createMutationTest(false, true);
      final factory = mutations.platformFactory as MockPlatformFactory;
      final system = factory.system!;
      bool foundAll = await mutations.runMutationTest();
      expect(foundAll, false);
      // runs count then mutations => every file read twice
      expect(system.reads, total_reads);
      expect(system.writes, 0);
      expect(system.argPaths.length, total_reads + 2);
      expect(system.argPaths[0], 'lib');
      expect(system.argPaths[1], 'pubspec.yaml');
      expect(system.argPaths[2], file1Path);
      expect(system.argPaths[3], file2Path);
      expect(system.argPaths[4], 'lib');
      expect(system.argPaths[5], 'pubspec.yaml');
      expect(system.argPaths[6], file1Path);
      expect(system.argPaths[7], file2Path);
      expect(mutations.total, total_mutations);
    });

    test('Real run', () async {
      final mutations = createMutationTest(false, false);
      final factory = mutations.platformFactory as MockPlatformFactory;
      final system = factory.system!;
      bool foundAll = await mutations.runMutationTest();
      expect(foundAll, false);
      expect(system.reads, total_reads);
      expect(system.writes, total_mutations + 2);
      expect(system.argPaths.length, 84);
      expect(system.argPaths[0], 'lib');
      expect(system.argPaths[1], 'pubspec.yaml');
      expect(system.argPaths[2], file1Path);
      expect(system.argPaths[3], file2Path);
      expect(system.argPaths[4], 'lib');
      expect(system.argPaths[5], 'pubspec.yaml');
      expect(system.argPaths[6], file1Path);
      expect(mutations.total, total_mutations);
    });

    test('abort', () async {
      final mutations = createMutationTest(false, true);
      mutations.abortMutationTest();

      final factory = mutations.platformFactory as MockPlatformFactory;
      expect(factory.system!.argLine.length, 1);
      expect(factory.system!.argLine[0],
          'Abort requested! Waiting for unfinished tasks...');
    });

    test('Count all', () async {
      final mutations = createMutationTest(false, true);
      final factory = mutations.platformFactory as MockPlatformFactory;
      final system = factory.system!;
      int count = await mutations.count();
      expect(system.reads, 3);
      expect(system.writes, 0);
      expect(count, total_mutations);
      expect(system.argPaths.length, 4);
      expect(system.argPaths[0], 'lib');
      expect(system.argPaths[1], 'pubspec.yaml');
      expect(system.argPaths[2], file1Path);
      expect(system.argPaths[3], file2Path);
      expect(mutations.total, total_mutations);
    });
  });

  group('file config', () {
    test('Dry run', () async {
      final mutations = createMutationTest(true, true);
      final factory = mutations.platformFactory as MockPlatformFactory;
      final system = factory.system!;
      bool foundAll = await mutations.runMutationTest();
      expect(foundAll, false);
      // runs count then mutations => every file read twice
      expect(system.argPaths.length, 6);
      expect(system.reads, 6);
      expect(system.writes, 0);
      expect(system.argPaths[0], configPath);
      expect(system.argPaths[1], file1Path);
      expect(system.argPaths[2], file2Path);
      expect(system.argPaths[3], configPath);
      expect(system.argPaths[4], file1Path);
      expect(system.argPaths[5], file2Path);
      expect(mutations.total, total_mutations);
    });

    test('Real run', () async {
      final mutations = createMutationTest(true, false);
      final factory = mutations.platformFactory as MockPlatformFactory;
      final system = factory.system!;
      bool foundAll = await mutations.runMutationTest();
      expect(foundAll, false);
      expect(system.reads, 6);
      expect(system.writes, total_mutations + 2);
      expect(system.argPaths.length, 82);
      expect(system.argPaths[0], configPath);
      expect(system.argPaths[1], file1Path);
      expect(system.argPaths[2], file2Path);
      expect(system.argPaths[3], configPath);
      expect(system.argPaths[4], file1Path);
      expect(mutations.total, total_mutations);
    });

    test('Count all', () async {
      final mutations = createMutationTest(true, true);
      final factory = mutations.platformFactory as MockPlatformFactory;
      final system = factory.system!;
      int count = await mutations.count();
      expect(count, total_mutations);
      expect(system.argPaths.length, 3);
      expect(system.argPaths[0], configPath);
      expect(system.argPaths[1], file1Path);
      expect(system.argPaths[2], file2Path);
      expect(mutations.total, total_mutations);
    });
  });
}

const file1Path = 'source1.dart';
const file1 = '''

int conditions(int a, int b, int c) {
  if (a == b && (a < c || b > c || b == c)) {
    return a + c;
  } else if (b <= 0 && c > 0) {
    return a - b;
  }
  for (var i = 0; i < 10; ++i) {}
  var i = 0;
  while (i < 10) {
    ++i;
  }
  return a * b + c;
}

double poly(double x, double a, double b, double c) {
  return a * x * x + b * x + c;
}

double inner2(double x, double y, double z) {
  return poly(x, y, z, 2.0);
}

double inner(double x, double y) {
  return inner2(x, y, 1.0);
}

double outer(double x, double y) {
  return optional(x: x, y: y);
}

double optional({double x= 1.0, double y = 2.0}) => inner(x, y);
''';

const file2Path = 'source2.dart';
const file2 = r'''

/* a multi line
 * comment
 */
class TestData {
  String text = 'default';
  double number1 = 25.0;
  double number2 = 25.0;
  bool on = false;

  double calc(double x) {
    return number1 * x / number2;
  }

  // just a weird example ...
  String format(double y) {
    if (y <= 0.0 && text != '') {
      return '$text $y';
    } else if (y == 0.0 && text != '') {
      return '$text $y';
    }
    return 'default $y';
  }

  void changeState(dynamic event) {
    if (event.a &&
        event.b &&
        (event.c || event.d || (event.f && event.g)) &&
        event.e) {
      on = true;
    }
  }
}

''';

const configPath = 'input.xml';
const config = '''<?xml version="1.0" encoding="UTF-8"?>
<mutations version="1.0">
  <files>
    <file>$file1Path</file>
    <file>$file2Path</file>
  </files>
  <commands>
    <command group="test" expected-return="0" working-directory=".">dart test</command>
  </commands>
</mutations>''';
