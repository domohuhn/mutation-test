/// Copyright 2021, domohuhn. 
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license

import 'test-runner.dart';
import 'mutations.dart';
import 'mutation-test.dart';
import 'ratings.dart';
import 'dart:io';
import 'string-helpers.dart';

/// Format for the report file
enum ReportFormat {
  XML,
  MARKDOWN,
  HTML,
  ALL,
  NONE
}


/// Creates the [test] report in directory [outputPath] from [inputFile]
/// int the specified [format].
void createReport(ResultsReporter results, String outputPath, String inputFile, ReportFormat format) {
  results.write();
  results.sort();
  switch(format) {
    case ReportFormat.XML:
      results.writeXMLReport(outputPath, inputFile);
      break;
    case ReportFormat.MARKDOWN:
      results.writeMarkdownReport(outputPath, inputFile);
      break;
    case ReportFormat.HTML:
      results.writeHTMLReport(outputPath, inputFile);
      break;
    case ReportFormat.ALL:
      results.writeXMLReport(outputPath, inputFile);
      results.writeMarkdownReport(outputPath, inputFile);
      results.writeHTMLReport(outputPath, inputFile);
      break;
    case ReportFormat.NONE:
      break;
  }
}

class ResultsReporter {
    /// statistics which command group caught how many mutations
  final Map<String,int> _groupStatistics = {};
  
  /// stores the undetected mutations
  final Map<String,List<MutatedLine>> _undetectedMutations = {};

  /// all files that were added as rules
  List<String> xmlFiles = [];
  Ratings quality = Ratings();

  final Stopwatch _timer = Stopwatch();

  Duration get elapsed => _timer.elapsed;

  /// Creates a test runner and adds [inputFile] to the xml input file list.
  ResultsReporter(String inputFile) {
    xmlFiles.add(inputFile);
    _timer.start();
  }

  int _totalFound = 0;
  int _totalRuns = 0;
  int _totalTimeouts = 0;

  /// Adds the [test] report to the accumulated statistics.
  /// This method will print to the command line if [verbose] is true.
  void addTestReport(String file, MutatedLine mutation, TestReport test, bool verbose) {
    _totalRuns += 1;
    switch(test.result) {
      case TestResult.Timeout:
        if (verbose) {
          print('Timeout for ${test.command}');
        }
        _totalTimeouts += 1;
        break;
      case TestResult.Detected:
        if (verbose) {
          print('Found mutation with ${test.command}');
        }
        if (test.command != null && test.command!.group.isNotEmpty) {
          _groupStatistics.update(test.command!.group, (v) => v+1, ifAbsent: () => 1);
        }
        _totalFound += 1;
        break;
      case TestResult.Undetected:
        if (verbose) {
          print('Undetected mutation! All tests passed!');
        }
        addMutation(file,mutation);
        break;
    }
  }

  int get undetectedMutations => _totalRuns-_totalFound;

  double get undetectedFraction => (100.0*undetectedMutations)/_totalRuns;
  double get detectedFraction => 100.0-(100.0*undetectedMutations)/_totalRuns;
  /// Checks if the test run was successful.
  bool get success => quality.isSuccessful(detectedFraction);
  /// Gets the quality rating for this run.
  String get rating => quality.rating(detectedFraction);

  /// Prints the statistics at the end of the execution.
  void write() {
    print('  --- Results ---');
    print('Test group statistics:');
    _groupStatistics.forEach((k, v) => print('  Group : $k, Found mutations: $v'));
    print('\nTotal tests: $_totalRuns\nUndetected Mutations: $undetectedMutations (${asPercentString(undetectedMutations,_totalRuns)})');
    print('Timeouts: $_totalTimeouts');
    print('Elapsed: $elapsed');
    print('Success: $success, Quality rating: $rating');
  }
  
  /// Sorts mutations by lines.
  void sort() {
    _undetectedMutations.forEach((key, value) {
      value.sort((lhs,rhs) => lhs.line.compareTo(rhs.line));
    });
  }

  /// Checks if all mutations were found.
  bool get foundAll => _totalRuns == _totalFound;

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
    text += '<program-version>${mutationTestVersion()}</program-version>\n';
    text += '<elapsed>$elapsed</elapsed>\n';
    text += '<result rating="$rating" success="$success"/>\n';
    text += '<rules>\n';
    xmlFiles.forEach((element) { text += '<ruleset document="$element"/>'; });
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
    var rv = '''# Mutation report
This is a mutation report generated by ${mutationTestVersion()}

${DateTime.now()}

| Key           | Value                     |
| ------------- | ------------------------- |
'''; 
  xmlFiles.forEach((element) { rv += '| Rules         | $element           |\n'; });
  rv += '''
| Mutations     | $_totalRuns                        |
| Elapsed     | $elapsed                        |
| Timeouts      | $_totalTimeouts                        |
| Undetected    | $undetectedMutations                        |
| Undetected%   | ${asPercentString(undetectedMutations, _totalRuns)}                        |
''';
    _groupStatistics.forEach((k, v){rv += '| Detected by: $k            | $v         |\n';});
    rv += '| Quality Rating | $rating |\n';
    rv += '| Success | $success |\n';
    return rv+'\n\n';
  }

  String _createHTMLHeader() {
    var rv = '''<style>
table { border-collapse:collapse; }
table thead th { border-bottom: 2px solid #000; }
table tbody tr { border-bottom: 1px solid lightgray; }
table tbody tr td { min-width:100px; padding: 7px; }
</style>
<h1>Mutation report</h1>
<p>This is a mutation report generated by ${mutationTestVersion()}</p>
<p>${DateTime.now()}</p>
<table>
<thead><tr><th>Key</th><th>Value</th></tr></thead>
<tbody>\n''';
  xmlFiles.forEach((element) { rv += '<tr><td>Rules</td><td>$element</td></tr>\n'; });
  rv += '''<tr><td>Mutations</td><td>$_totalRuns</td></tr>
<tr><td>Elapsed</td><td>$elapsed</td></tr>
<tr><td>Timeouts</td><td>$_totalTimeouts</td></tr>
<tr><td>Undetected</td><td>$undetectedMutations</td></tr>
<tr><td>Undetected%</td><td>${asPercentString(undetectedMutations, _totalRuns)}</td></tr>
''';
    _groupStatistics.forEach((k, v){rv += '<tr><td>Detected by: $k</td><td>$v</td></tr>\n';});
    rv += '<tr><td>Quality Rating</td><td>$rating</td></tr>\n';
    rv += '<tr><td>Success</td><td>$success</td></tr>\n';
    rv += '\n</tbody>\n</table>';
    return rv;
  }

}