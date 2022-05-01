/// Copyright 2021, domohuhn. 
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license

import 'package:mutation_test/src/errors.dart';
import 'package:mutation_test/src/test_runner.dart';
import 'package:mutation_test/src/mutations.dart';
import 'package:mutation_test/src/mutation_test.dart';
import 'package:mutation_test/src/ratings.dart';
import 'dart:io';
import 'package:mutation_test/src/string_helpers.dart';
import 'package:mutation_test/src/html_reporter.dart';

/// Format for the report file
enum ReportFormat {
  /// Creates the report as XML document.
  XML,
  /// Creates the report as markdown document.
  MARKDOWN,
  /// Creates the report as html documents.
  HTML,
  /// Creates all reports at once.
  ALL,
  /// Creates no report.
  NONE
}


/// Creates the test report in directory [outputPath] from [inputFile]
/// in the specified [format] using the [results].
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

/// Holds the report data for a file.
class FileMutationResults {
  /// path to the file
  String path;
  /// total mutation count per file
  int mutationCount = 0;
  /// detected count per file
  int detectedCount = 0;
  /// timeout count per file
  int timeoutCount = 0;
  /// undected mutations in this file
  List<MutatedLine> undetectedMutations;

  FileMutationResults(this.path, this.mutationCount) : undetectedMutations=[];
}

/// This class logs the mutations and can create report documents in different
/// formats. See [ReportFormat] for the supported reports.
///
/// It may create multiple folders in the output path depending on the selected report
/// format.
class ResultsReporter {
  /// statistics which command group caught how many mutations
  final Map<String,int> _groupStatistics = {};
  
  /// stores the undetected mutations
  final Map<String,FileMutationResults> testedFiles = {};
  
  /// stores the undetected mutations
  final Map<String,List<MutatedLine>> _undetectedMutations = {};

  /// all files that were added as rules
  List<String> xmlFiles = [];
  Ratings quality = Ratings();

  final Stopwatch _timer = Stopwatch();

  Duration get elapsed => _timer.elapsed;

  /// Creates a test runner and adds [inputFile] to the xml input file list.
  /// [builtinRulesAdded] sets the flag in the report file when the builtin rules were added.
  ResultsReporter(String inputFile, this.builtinRulesAdded) {
    xmlFiles.add(inputFile);
    _timer.start();
  }

  /// whether the builtin rules were added.
  final bool builtinRulesAdded;

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
        if(testedFiles.containsKey(file)) {
          testedFiles[file]!.timeoutCount += 1;
        } else {
          throw MutationError('"$file" was not registered in the reporter!');
        }
        break;
      case TestResult.Detected:
        if (verbose) {
          print('Found mutation with ${test.command}');
        }
        if (test.command != null && test.command!.group.isNotEmpty) {
          _groupStatistics.update(test.command!.group, (v) => v+1, ifAbsent: () => 1);
        }
        _totalFound += 1;        
        if(testedFiles.containsKey(file)) {
          testedFiles[file]!.detectedCount += 1;
        } else {
          throw MutationError('"$file" was not registered in the reporter!');
        }
        break;
      case TestResult.Undetected:
        if (verbose) {
          print('Undetected mutation! All tests passed!');
        }
        addMutation(file,mutation);
        break;
    }
  }

  /// Starts a test run on the file [path] with [count] mutations.
  void startFileTest(String path, int count) {
    if (testedFiles.containsKey(path)) {
      testedFiles[path]!.mutationCount += count;
    }
    else {
      testedFiles[path] = FileMutationResults(path,count);
    }
  }

  /// Reports the count of performed mutations.
  int get totalMutations => _totalRuns;

  /// Reports the count of test commands that timed out.
  int get totalTimeouts => _totalTimeouts;
  
  /// Reports the count of detected mutations.
  int get foundMutations => _totalFound;

  /// Reports the count of undetected mutations.
  int get undetectedMutations => _totalRuns-_totalFound;

  /// Reports the percentage of undetected mutations of the total mutations.
  double get undetectedFraction => (100.0*undetectedMutations)/_totalRuns;
  /// Reports the percentage of detected mutations of the total mutations.
  double get detectedFraction => 100.0-(100.0*undetectedMutations)/_totalRuns;
  /// Reports the percentage of mutations that ran into the timeout.
  double get timeoutFraction => (100.0*totalTimeouts)/_totalRuns;
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
    if(testedFiles.containsKey(file)) {
      testedFiles[file]!.undetectedMutations.add(mutation);
    } else {
      throw MutationError('"$file" was not registered in the reporter!');
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
    for(final element in xmlFiles) {
      text += '<ruleset document="$element"/>';
    }
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
        // ignore: unnecessary_string_escapes
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
    var index = createToplevelHtmlFile(this);
    var fname = createReportFileName('index',outpath,'html', appendReport: false);
    _createPathsAndWriteFile(fname,index);
    /*var text = _createHTMLHeader();
    _undetectedMutations.forEach((key, value) {
      text += '<h2>Undetected mutations in file : $key</h2>\n';
      for (final mut in value) {
        // ignore: unnecessary_string_escapes
        text += mut.toHTML().replaceAll('*', '\*');
      }
      text += '\n\n';
    });
    final name = createReportFileName(input,outpath,'html');
    File(name).writeAsStringSync(text);*/
  }

  void _createPathsAndWriteFile(String path, String text) {
    final dir = getDirectory(path);
    if(dir.isNotEmpty) {
      if(!Directory(dir).existsSync()){
        Directory(dir).createSync(recursive: true);
      }
    }
    File(path).writeAsStringSync(text);
  }


  String _createMarkdownHeader() {
    var rv = '''# Mutation report
This is a mutation report generated by ${mutationTestVersion()}

${DateTime.now()}

| Key           | Value                     |
| ------------- | ------------------------- |
''';
    for(final element in xmlFiles) {
      rv += '| Rules         | $element           |\n';
    }
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
    for(final element in xmlFiles) {
      rv += '<tr><td>Rules</td><td>$element</td></tr>\n';
    }
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