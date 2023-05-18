// Copyright 2021, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/commands.dart';
import 'package:mutation_test/src/configuration.dart';
import 'package:mutation_test/src/test_runner.dart';
import 'package:test/test.dart';

void main() async {
  test('Run simple process', () async {
    Configuration config = Configuration(false, false);
    config.commands.add(Command('dart --version', 'dart', ['--version']));
    var runner = TestRunner();
    final report = await runner.run(config, outputOnFailure: true);
    expect(report.result, TestResult.Undetected);
  });

  test('Run simple process 2', () async {
    Configuration config = Configuration(false, false);
    var cmd = Command('dart --version', 'dart', ['--version']);
    cmd.expectedReturnValue = 1;
    config.commands.add(cmd);
    var runner = TestRunner();
    final report = await runner.run(config, outputOnFailure: true);
    expect(report.result, TestResult.Detected);
  });
}
