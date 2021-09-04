/// Copyright 2021, domohuhn. 
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license
import 'mutations.dart';
import 'commands.dart';
import 'configuration.dart';
import 'string-helpers.dart';
import 'dart:io';
import 'dart:convert';

/// Result of running a test command
enum TestResult {
  Timeout,
  Detected,
  Undetected
}

/// Runs the tests for mutations and stores the results.
class TestRunner {
  /// statistics which command group caught how many mutations
  final Map<String,int> _groupStatistics = {};
  /// statistics which command caught how many mutations
  final Map<String,int> _commandStatistics = {};
  
  /// stores the undetected mutations
  final Map<String,List<MutatedLine>> _undetectedMutations = {};

  /// all files that were added as rules
  List<String> xmlFiles = [];

  /// Creates a test runner and adds [inputFile] to the xml input file list.
  TestRunner(String inputFile) {
    xmlFiles.add(inputFile);
  }

  int _totalFound = 0;
  int _totalRuns = 0;
  int _totalTimeouts = 0;
  
  /// Prepares the testrunner to run the tests specified in [config]
  void prepare(Configuration config) {
    for (final cmd in config.commands) {
      if (cmd.group.isNotEmpty) {
        _groupStatistics[cmd.group] = 0;
      }
      if (cmd.name.isNotEmpty) {
        _commandStatistics[cmd.name] = 0;
      }
    }
  }

  /// Runs all test commands from [config] in document order.
  /// 
  /// The method will return true in case all tests pass (the mutation was not detected).
  /// If [outputOnFailure] is true, the complete command output will be printed.
  Future<bool> run(Configuration config, {bool outputOnFailure=false}) async {
    _totalRuns += 1;
    for (final cmd in config.commands) {
      var result = await _start(cmd, outputOnFailure: outputOnFailure);
      switch(result) {
        case TestResult.Timeout:
          _totalTimeouts += 1;
          return false;
        case TestResult.Detected:
          if (config.verbose) {
            print('Found mutation with command "${cmd.name}" (group: "${cmd.group}")');
          }
          if (cmd.group.isNotEmpty) {
            _groupStatistics.update(cmd.group, (v) => v+1, ifAbsent: () => 1);
          }
          if (cmd.name.isNotEmpty) {
            _commandStatistics.update(cmd.name, (v) => v+1, ifAbsent: () => 1);
          }
          _totalFound += 1;
          return false;
        case TestResult.Undetected:
          break;
      }
    }
    if (config.verbose) {
      print('Undetected mutation! All tests passed!');
    }
    return true;
  }

  /// Starts the process and checks its results.
  Future<TestResult> _start(Command cmd, {bool outputOnFailure=false}) async {
    var timedout = false;
    var stopwatch = Stopwatch();
    stopwatch.start();
    var future = await Process.start(cmd.command, cmd.arguments, workingDirectory: cmd.directory);
    
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

  /// Prints the statistics at the end of the execution.
  void printResults() {
    var fixedTotal = _totalRuns-1;
    print('  --- Results ---');
    print('Test command statistics:');
    _commandStatistics.forEach((k, v) => print('  Command : $k, Found mutations: $v'));
    print('Test group statistics:');
    _groupStatistics.forEach((k, v) => print('  Group : $k, Found mutations: $v'));
    print('\nTotal tests: $fixedTotal\nUndetected Mutations: ${fixedTotal-_totalFound} (${asPercentString(fixedTotal-_totalFound,fixedTotal)})');
    print('Timeouts: $_totalTimeouts');
  }

  /// Sorts mutations by lines.
  void sort() {
    _undetectedMutations.forEach((key, value) {
      value.sort((lhs,rhs) => lhs.line.compareTo(rhs.line));
    });
  }

  /// Checks if all mutations were found.
  bool get foundAll => _totalRuns-1-_totalFound == 0;

  /// Adds the undetected [mutation] from [file] to the list.
  void addMutation(String file, MutatedLine mutation) {
    if (_undetectedMutations.containsKey(file)) {
      var list = _undetectedMutations[file];
      if(list == null) {
        _undetectedMutations[file] = [mutation];
      }
      else {
        list.add(mutation);
      }
    }
    else {
      _undetectedMutations[file] = [mutation];
    }
  }

  /// Writes the results of the tests to a xml file in directory [outpath].
  /// The report will be named like the [input], but ending with "-report.xml".
  void writeXMLReport(String outpath, String input) {
    var text = '<?xml version="1.0" encoding="UTF-8"?>\n<undetected-mutations>\n';
    text += '<rules>\n';
    xmlFiles.forEach((element) { text += '<ruleset name="$element"/>'; });
    text += '</rules>\n';
    _undetectedMutations.forEach((key, value) {
      text += '<file name="$key">\n';
      for (final mut in value) {
        text += '<mutation line="${mut.line}">\n';
        text += '<original>${convertToXML(mut.original)}</original>\n';
        text += '<modified>${convertToXML(mut.mutated)}</modified>\n';
        text += '</mutation>\n';
      }
      text += '</file>\n';
    });
    text += '</undetected-mutations>\n';
    final name = createReportFileName(input,outpath,'xml');
    File(name).writeAsStringSync(text);
  }

  /// Writes the results of the tests to a markdown file in directory [outpath].
  /// The report will be named like the [input], but ending with "-report.md".
  void writeMarkdownReport(String outpath, String input) {
    var text = _createMarkdownHeader();
    _undetectedMutations.forEach((key, value) {
      text += '## Undetected mutations in file : $key\n';
      for (final mut in value) {
        text += mut.toMarkdown().replaceAll('*', '\*');
      }
      text += '\n\n';
    });
    final name = createReportFileName(input,outpath,'md');
    File(name).writeAsStringSync(text);
  }

  /// Writes the results of the tests to a html file in directory [outpath].
  /// The report will be named like the [input], but ending with "-report.html".
  void writeHTMLReport(String outpath, String input) {
    var text = _createHTMLHeader();
    _undetectedMutations.forEach((key, value) {
      text += '<h2>Undetected mutations in file : $key</h2>\n';
      for (final mut in value) {
        text += mut.toHTML().replaceAll('*', '\*');
      }
      text += '\n\n';
    });
    final name = createReportFileName(input,outpath,'html');
    File(name).writeAsStringSync(text);
  }

  String _createMarkdownHeader() {
    var fixedTotal = _totalRuns-1;
    var rv = '''# Mutation report
This is a mutation report generated by mutation-test.

${DateTime.now()}

| Key           | Value                     |
| ------------- | ------------------------- |
'''; 
  xmlFiles.forEach((element) { rv += '| Rules         | $element           |'; });
  rv += '''
| Mutations     | $fixedTotal                        |
| Timeouts      | $_totalTimeouts                        |
| Undetected    | ${fixedTotal-_totalFound}                        |
| Undetected%   | ${asPercentString(fixedTotal-_totalFound, fixedTotal)}                        |


## Detections ordered by test groups

| Group         | Count      |
| ------------- | ---------- |
''';
    _groupStatistics.forEach((k, v){rv += '| $k            | $v         |\n';});
    rv += '''


## Detections ordered by test commands

| Command       | Count      |
| ------------- | ---------- |
''';
    _commandStatistics.forEach((k, v){rv += '| $k            | $v         |\n';});
    return rv+'\n\n';
  }

  String _createHTMLHeader() {
    var fixedTotal = _totalRuns-1;
    var rv = '''<style>
table { border-collapse:collapse; }
table thead th { border-bottom: 2px solid #000; }
table tbody tr { border-bottom: 1px solid lightgray; }
table tbody tr td { min-width:100px; padding: 7px; }
</style>
<h1>Mutation report</h1>
<p>This is a mutation report generated by mutation-test.</p>
<p>${DateTime.now()}</p>
<table>
<thead><tr><th>Key</th><th>Value</th></tr></thead>
<tbody>\n''';
  xmlFiles.forEach((element) { rv += '<tr><td>Rules</td><td>$element</td></tr>\n'; });
  rv += '''<tr><td>Mutations</td><td>$fixedTotal</td></tr>
<tr><td>Timeouts</td><td>$_totalTimeouts</td></tr>
<tr><td>Undetected</td><td>${fixedTotal-_totalFound}</td></tr>
<tr><td>Undetected%</td><td>${asPercentString(fixedTotal-_totalFound, fixedTotal)}</td></tr>
</tbody>
</table>
<h2>Detections ordered by test groups</h2>
<table>
<thead>
<tr><th>Group</th><th>Count</th></tr>
</thead>
<tbody>''';
    _groupStatistics.forEach((k, v){rv += '<tr><td>$k</td><td>$v</td></tr>\n';});
    rv += '\n</tbody>\n</table>\n<h2>Detections ordered by test commands</h2>\n<table>\n<thead>\n<tr><th>Command</th><th>Count</th></tr>\n</thead>\n<tbody>';
    _commandStatistics.forEach((k, v){rv += '<tr><td>$k</td><td>$v</td></tr>\n';});
    rv += '\n</tbody>\n</table>';
    return rv;
  }

}




