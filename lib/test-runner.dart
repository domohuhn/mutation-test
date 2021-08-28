import 'package:mutation_test/mutations.dart';

import 'configuration.dart';
import 'string-helpers.dart';
import 'dart:io';

/// Runs the tests for mutations and stores the results.
class TestRunner {
  /// statistics which command group caught how many mutations
  final Map<String,int> _groupStatistics = {};
  /// statistics which command caught how many mutations
  final Map<String,int> _commandStatistics = {};
  
  /// stores the undetected mutations
  final Map<String,List<UndetectedMutation>> _undetectedMutations = {};

  int _totalFound = 0;
  int _totalRuns = 0;
  
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
  bool run(Configuration config, {bool outputOnFailure=false}) {
    _totalRuns += 1;
    for (final cmd in config.commands) {
      var result = Process.runSync(cmd.command, cmd.arguments, workingDirectory: cmd.directory);
      if (result.exitCode != cmd.expectedReturnValue) {
        if (config.verbose) {
          print('Found mutation: Test command failed ${cmd.command} with return code ${result.exitCode}');
        }
        if (outputOnFailure) {
          print('FAILED TEST COMMAND: "${cmd.original}"');
          print('-- stdout: \n ${result.stdout}');
          print('-- stderr: \n ${result.stderr}');
          print('-- return code: \n ${result.exitCode} (expected: ${cmd.expectedReturnValue})');
        }
        if (cmd.group.isNotEmpty) {
          _groupStatistics.update(cmd.group, (v) => v+1, ifAbsent: () => 1);
        }
        if (cmd.name.isNotEmpty) {
          _commandStatistics.update(cmd.name, (v) => v+1, ifAbsent: () => 1);
        }
        _totalFound += 1;
        return false;
      }
    }
    if (config.verbose) {
      print('All Tests ok: Mutation survived');
    }
    return true;
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


  }

  /// Checks if all mutations were found.
  bool get foundAll => _totalRuns-1-_totalFound == 0;

  /// Adds the undetected [mutation] from [file] to the list.
  void addMutation(String file, UndetectedMutation mutation) {
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
    var text = _createMarkdownHeader(input);
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
    var text = _createHTMLHeader(input);
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

  String _createMarkdownHeader(String name) {
    var fixedTotal = _totalRuns-1;
    var rv = '''# Mutation report
This is a mutation report generated by mutation-test.

${DateTime.now()}

| Key           | Value                     |
| ------------- | ------------------------- |
| Input file    | $name                     |
| Mutations     | $fixedTotal                        |
| Undetected    | ${fixedTotal-_totalFound}                        |
| Undetected%   | ${asPercentString(fixedTotal-_totalFound, fixedTotal)}                        |


## Detections ordered by test groups

| Group         | Count      |
| ------------- | ---------- |
''';
    _groupStatistics.forEach((k, v){rv += '| $k            | $v         |\n';});
    rv += '''


## Detection by test commands

| Command       | Count      |
| ------------- | ---------- |
''';
    _commandStatistics.forEach((k, v){rv += '| $k            | $v         |\n';});
    return rv+'\n\n';
  }

  String _createHTMLHeader(String name) {
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
<tbody>
<tr><td>Input file</td><td>$name</td></tr>
<tr><td>Mutations</td><td>$fixedTotal</td></tr>
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
    rv += '\n</tbody>\n</table>\n<h2>Detection by test commands</h2>\n<table>\n<thead>\n<tr><th>Command</th><th>Count</th></tr>\n</thead>\n<tbody>';
    _commandStatistics.forEach((k, v){rv += '<tr><td>$k</td><td>$v</td></tr>\n';});
    rv += '\n</tbody>\n</table>';
    return rv;
  }

}




