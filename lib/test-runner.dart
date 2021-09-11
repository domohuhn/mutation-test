/// Copyright 2021, domohuhn. 
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license
import 'commands.dart';
import 'configuration.dart';
import 'dart:io';
import 'dart:convert';

/// Result of running a test command
enum TestResult {
  Timeout,
  Detected,
  Undetected
}

class TestReport {
  TestReport(this.result,{this.command});
  TestResult result;
  Command? command;
}

/// Runs the tests for mutations and stores the results.
class TestRunner {

  /// Runs all test commands from [config] in document order.
  /// 
  /// The method will an aggregate of the result in and some other data.
  /// If [outputOnFailure] is true, the complete command output will be printed in case of failure.
  Future<TestReport> run(Configuration config, {bool outputOnFailure=false}) async {
    for (final cmd in config.commands) {
      var result = await _start(cmd, outputOnFailure: outputOnFailure);
      if (result != TestResult.Undetected) {
        return TestReport(result,command: cmd);
      }
    }
    return TestReport(TestResult.Undetected);
  }

  /// Starts the process and checks its results.
  Future<TestResult> _start(Command cmd, {bool outputOnFailure=false}) async {
    var timedout = false;
    var stopwatch = Stopwatch();
    stopwatch.start();
    var future = await Process.start(cmd.command, cmd.arguments, workingDirectory: cmd.directory);
    _pid = future.pid;
    var stdout = '';
    var moo1 = future.stdout.transform(Utf8Decoder(allowMalformed: true)).forEach((e) { stdout += e; });
    var stderr = '';
    var moo2 = future.stderr.transform(Utf8Decoder(allowMalformed: true)).forEach((e) { stderr += e; });

    var exitfuture = future.exitCode;
    if (cmd.timeout != null) {
      exitfuture = exitfuture.timeout(cmd.timeout!,onTimeout: () {
        print('Command time out after: ${stopwatch.elapsed}! Killing process with pid: ${future.pid}.');
        future.kill(ProcessSignal.sigterm);
        timedout = true;
        return -1;
      });
    }

    var exitCode = await exitfuture;
    await moo1;
    await moo2;

    final matchesExpectation = exitCode == cmd.expectedReturnValue;
    if (outputOnFailure && (!matchesExpectation || timedout)) {
      print('FAILED: $cmd');
      print('Timeout: $timedout (elapsed time: ${stopwatch.elapsed} - exit code may be wrong on timeout)');
      print('Exit code: $exitCode (expected ${cmd.expectedReturnValue})');
      print('stdout: "$stdout"');
      print('stderr: "$stderr"');
    }
    if (timedout) {
      return TestResult.Timeout;
    }
    if (!matchesExpectation) {
      return TestResult.Detected;
    }
    return TestResult.Undetected;
  }

  int _pid = 0;

  /// Kills the current child process
  void kill() {
    Process.killPid(_pid,ProcessSignal.sigterm);
  }

}




