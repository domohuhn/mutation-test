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
void createReport(ResultsReporter results, String outputPath, String inputFile,
    ReportFormat format) {
  results.write();
  results.sort();
  switch (format) {
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
      return;
  }
  print('Output has been written to $outputPath');
}

/// Holds the report data for a file.
class FileMutationResults {
  /// path to the file
  String path;

  /// contents of the file
  String contents;

  /// total mutation count per file
  int mutationCount = 0;

  /// detected count per file
  int detectedCount = 0;

  /// timeout count per file
  int timeoutCount = 0;

  /// undected mutations in this file
  List<MutatedLine> undetectedMutations;

  FileMutationResults(this.path, this.mutationCount, this.contents)
      : undetectedMutations = [];

  bool lineHasUndetectedMutation(int i) {
    for (final m in undetectedMutations) {
      if (m.line == i) {
        return true;
      }
    }
    return false;
  }
}

/// This class logs the mutations and can create report documents in different
/// formats. See [ReportFormat] for the supported reports.
///
/// It may create multiple folders in the output path depending on the selected report
/// format.
class ResultsReporter {
  /// statistics which command group caught how many mutations
  final Map<String, int> _groupStatistics = {};

  /// stores the undetected mutations
  final Map<String, FileMutationResults> testedFiles = {};

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
  void addTestReport(
      String file, MutatedLine mutation, TestReport test, bool verbose) {
    _totalRuns += 1;
    switch (test.result) {
      case TestResult.Timeout:
        if (verbose) {
          print('Timeout for ${test.command}');
        }
        _totalTimeouts += 1;
        if (testedFiles.containsKey(file)) {
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
          _groupStatistics.update(test.command!.group, (v) => v + 1,
              ifAbsent: () => 1);
        }
        _totalFound += 1;
        if (testedFiles.containsKey(file)) {
          testedFiles[file]!.detectedCount += 1;
        } else {
          throw MutationError('"$file" was not registered in the reporter!');
        }
        break;
      case TestResult.Undetected:
        if (verbose) {
          print('Undetected mutation! All tests passed!');
        }
        addMutation(file, mutation);
        break;
    }
  }

  /// Starts a test run on the file [path] with [count] mutations.
  /// The [contents] of the file are used for the html reporting.
  void startFileTest(String path, int count, String contents) {
    if (testedFiles.containsKey(path)) {
      testedFiles[path]!.mutationCount += count;
    } else {
      testedFiles[path] = FileMutationResults(path, count, contents);
    }
  }

  /// Reports the count of performed mutations.
  int get totalMutations => _totalRuns;

  /// Reports the count of test commands that timed out.
  int get totalTimeouts => _totalTimeouts;

  /// Reports the count of detected mutations.
  int get foundMutations => _totalFound;

  /// Reports the count of undetected mutations.
  int get undetectedMutations => _totalRuns - _totalFound;

  /// Reports the percentage of undetected mutations of the total mutations.
  double get undetectedFraction => (100.0 * undetectedMutations) / _totalRuns;

  /// Reports the percentage of detected mutations of the total mutations.
  double get detectedFraction =>
      100.0 - (100.0 * undetectedMutations) / _totalRuns;

  /// Reports the percentage of mutations that ran into the timeout.
  double get timeoutFraction => (100.0 * totalTimeouts) / _totalRuns;

  /// Checks if the test run was successful.
  bool get success => quality.isSuccessful(detectedFraction);

  /// Gets the quality rating for this run.
  String get rating => quality.rating(detectedFraction);

  /// Prints the statistics at the end of the execution.
  void write() {
    print('  --- Results ---');
    print('Test group statistics:');
    _groupStatistics
        .forEach((k, v) => print('  Group : $k, Found mutations: $v'));
    print(
        '\nTotal tests: $_totalRuns\nUndetected Mutations: $undetectedMutations (${asPercentString(undetectedMutations, _totalRuns)})');
    print('Timeouts: $_totalTimeouts');
    print('Elapsed: $elapsed');
    print('Success: $success, Quality rating: $rating');
  }

  /// Sorts mutations by lines.
  void sort() {
    testedFiles.forEach((key, value) {
      value.undetectedMutations
          .sort((lhs, rhs) => lhs.line.compareTo(rhs.line));
    });
  }

  /// Checks if all mutations were found.
  bool get foundAll => _totalRuns == _totalFound;

  /// Adds the undetected [mutation] from [file] to the list.
  void addMutation(String file, MutatedLine mutation) {
    if (testedFiles.containsKey(file)) {
      testedFiles[file]!.undetectedMutations.add(mutation);
    } else {
      throw MutationError('"$file" was not registered in the reporter!');
    }
  }

  /// Writes the results of the tests to a xml file in directory [outpath].
  /// The report will be named like the [input], but ending with "-report.xml".
  void writeXMLReport(String outpath, String input) {
    var text =
        '<?xml version="1.0" encoding="UTF-8"?>\n<undetected-mutations>\n';
    text += '<program-version>${mutationTestVersion()}</program-version>\n';
    text += '<elapsed>$elapsed</elapsed>\n';
    text += '<result rating="$rating" success="$success"/>\n';
    text += '<rules>\n';
    for (final element in xmlFiles) {
      text += '<ruleset document="$element"/>';
    }
    text += '</rules>\n';
    testedFiles.forEach((key, value) {
      text += '<file name="$key">\n';
      for (final mut in value.undetectedMutations) {
        text += '<mutation line="${mut.line}">\n';
        text += '<original>${convertToXML(mut.original)}</original>\n';
        text += '<modified>${convertToXML(mut.mutated)}</modified>\n';
        text += '</mutation>\n';
      }
      text += '</file>\n';
    });
    text += '</undetected-mutations>\n';
    final name =
        createReportFileName(_sanitizeInputFile(input), outpath, 'xml');
    _createPathsAndWriteFile(name, text);
  }

  /// Writes the results of the tests to a markdown file in directory [outpath].
  /// The report will be named like the [input], but ending with "-report.md".
  void writeMarkdownReport(String outpath, String input) {
    var text = _createMarkdownHeader();
    testedFiles.forEach((key, value) {
      text += '## Undetected mutations in file : $key\n';
      for (final mut in value.undetectedMutations) {
        // ignore: unnecessary_string_escapes
        text += mut.toMarkdown().replaceAll('*', '\*');
      }
      text += '\n\n';
    });
    final name = createReportFileName(_sanitizeInputFile(input), outpath, 'md');
    _createPathsAndWriteFile(name, text);
  }

  /// Writes the results of the tests to a html file in directory [outpath].
  /// The report will be named like the [input], but ending with "-report.html".
  void writeHTMLReport(String outpath, String input) {
    var index = createToplevelHtmlFile(this);
    var fname =
        createReportFileName(_sanitizeInputFile(input), outpath, 'html');
    _createPathsAndWriteFile(fname, index);
    testedFiles.forEach((key, value) {
      var contents = createSourceHtmlFile(this, value, basename(fname));
      var sname = createReportFileName(key, outpath, 'html',
          appendReport: false,
          removeInputExt: false,
          removePathsFromInput: false);
      _createPathsAndWriteFile(sname, contents);
    });
  }

  String _sanitizeInputFile(String input) {
    if (input.isNotEmpty) {
      return input;
    }
    return 'mutation-test';
  }

  void _createPathsAndWriteFile(String path, String text) {
    final dir = getDirectory(path);
    if (dir.isNotEmpty) {
      if (!Directory(dir).existsSync()) {
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
    for (final element in xmlFiles) {
      rv += '| Rules         | $element           |\n';
    }
    rv += '''
| Mutations     | $_totalRuns                        |
| Elapsed     | $elapsed                        |
| Timeouts      | $_totalTimeouts                        |
| Undetected    | $undetectedMutations                        |
| Undetected%   | ${asPercentString(undetectedMutations, _totalRuns)}                        |
''';
    _groupStatistics.forEach((k, v) {
      rv += '| Detected by: $k            | $v         |\n';
    });
    rv += '| Quality Rating | $rating |\n';
    rv += '| Success | $success |\n';
    return '$rv\n\n';
  }
}
