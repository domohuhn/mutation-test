// Copyright 2021, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license
import 'package:mutation_test/src/core/commands.dart';
import 'package:mutation_test/src/configuration/configuration.dart';
import 'package:mutation_test/src/core/system_interactions.dart';
import 'dart:io';
import 'dart:convert';

/// Runs the tests for mutations and stores the results.
class TestRunner {
  /// Runs all test commands from [config] in document order.
  ///
  /// The method will report aggregate of the result in and some other data.
  /// If [outputOnFailure] is true, the complete command output will be printed in case of failure.
  Future<TestReport> run(Configuration config, SystemInteractions system,
      {bool outputOnFailure = false}) async {
    for (final cmd in config.commands) {
      var result = await _start(cmd, system, outputOnFailure: outputOnFailure);
      if (result != TestResult.Undetected) {
        return TestReport(result, command: cmd);
      }
    }
    return TestReport(TestResult.Undetected);
  }

  /// Starts the process and checks its results.
  Future<TestResult> _start(Command cmd, SystemInteractions system,
      {bool outputOnFailure = false}) async {
    var timeout = false;
    final stopwatch = Stopwatch();
    stopwatch.start();
    var future = await Process.start(cmd.command, cmd.arguments,
        workingDirectory: cmd.directory, runInShell: Platform.isWindows);
    _pid = future.pid;
    _started = true;
    var stdout = '';
    final awaitableStdout =
        future.stdout.transform(Utf8Decoder(allowMalformed: true)).forEach((e) {
      stdout += e;
    });
    var stderr = '';
    final awaitableStderr =
        future.stderr.transform(Utf8Decoder(allowMalformed: true)).forEach((e) {
      stderr += e;
    });

    var exitFuture = future.exitCode;
    if (cmd.timeout != null) {
      exitFuture = exitFuture.timeout(cmd.timeout!, onTimeout: () {
        system.writeLine(
            'Command time out after: ${stopwatch.elapsed}! Killing process with pid: ${future.pid}.');
        future.kill(ProcessSignal.sigterm);
        timeout = true;
        return -1;
      });
    }

    var exitCode = await exitFuture;
    await awaitableStdout;
    await awaitableStderr;
    _started = false;

    final matchesExpectation = exitCode == cmd.expectedReturnValue;
    if (outputOnFailure && (!matchesExpectation || timeout)) {
      system.writeLine('FAILED: $cmd');
      system.writeLine(
          'Timeout: $timeout (elapsed time: ${stopwatch.elapsed} - exit code may be wrong on timeout)');
      system.writeLine(
          'Exit code: $exitCode (expected ${cmd.expectedReturnValue})');
      system.writeLine('stdout: "$stdout"');
      system.writeLine('stderr: "$stderr"');
    }
    if (timeout) {
      return TestResult.Timeout;
    }
    if (!matchesExpectation) {
      return TestResult.Detected;
    }
    return TestResult.Undetected;
  }

  int _pid = 0;
  bool _started = false;

  /// Kills the current child process
  bool kill() {
    if (!_started) {
      return false;
    }
    return Process.killPid(_pid, ProcessSignal.sigterm);
  }
}
