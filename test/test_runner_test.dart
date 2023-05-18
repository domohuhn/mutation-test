// Copyright 2021, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/commands.dart';
import 'package:mutation_test/src/configuration.dart';
import 'package:mutation_test/src/test_runner.dart';
import 'package:test/test.dart';

import 'mock_system_interactions.dart';

void main() async {
  final mock = MockSystemInteractions();
  test('Run simple process', () async {
    Configuration config = Configuration(false, false);
    config.commands.add(Command('dart --version', 'dart', ['--version']));
    var runner = TestRunner();
    final report = await runner.run(config, mock, outputOnFailure: true);
    expect(report.result, TestResult.Undetected);
    expect(mock.argLine.length, 0);
  });

  test('Run simple process 2', () async {
    Configuration config = Configuration(false, false);
    var cmd = Command('dart --version', 'dart', ['--version']);
    cmd.expectedReturnValue = 1;
    config.commands.add(cmd);
    var runner = TestRunner();
    final report = await runner.run(config, mock, outputOnFailure: true);
    expect(report.result, TestResult.Detected);
    expect(mock.argLine.length, 5);
    expect(mock.argLine[0], 'FAILED: Command: "dart --version"');
    expect(mock.argLine[1].startsWith('Timeout: false (elapsed time:'), true);
    expect(mock.argLine[2], 'Exit code: 0 (expected 1)');
    expect(mock.argLine[3].startsWith('stdout: "'), true);
    expect(mock.argLine[4], 'stderr: ""');
  });
}
