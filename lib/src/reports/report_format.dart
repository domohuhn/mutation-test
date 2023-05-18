// Copyright 2021, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/errors.dart';
import 'package:mutation_test/src/system_interactions.dart';
import 'package:mutation_test/src/mutations.dart';
import 'package:mutation_test/src/version.dart';
import 'package:mutation_test/src/ratings.dart';
import 'package:mutation_test/src/reports/string_helpers.dart';
import 'package:mutation_test/src/reports/html_reporter.dart';
import 'package:mutation_test/src/commands.dart';
import 'package:mutation_test/src/reports/xunit_reporter.dart';

/// Format for the report file
enum ReportFormat {
  /// Creates the report as XML document.
  XML,

  /// Creates the report as markdown document.
  MARKDOWN,

  /// Creates the report as html documents.
  HTML,

  /// Creates the report as junit xml document.
  JUNIT,

  /// Creates the report as xunit xml document.
  XUNIT,

  /// Creates all reports at once.
  ALL,

  /// Creates no report.
  NONE
}

/// Holds the report data for a file.
class FileMutationResults {
  /// path to the file
  String path;

  /// contents of the file
  String contents;

  /// total mutation count per file
  int get mutationCount => detectedCount + timeoutCount + undetectedCount;

  /// detected count per file
  int get detectedCount => detectedMutations.length;

  /// timeout count per file
  int get timeoutCount => timeoutMutations.length;

  /// detected count per file
  int get undetectedCount => undetectedMutations.length;

  /// undetected mutations in this file
  List<MutatedLine> undetectedMutations;

  /// detected mutations in this file
  List<MutatedLine> detectedMutations;

  /// detected mutations in this file
  List<MutatedLine> timeoutMutations;

  Duration get elapsed {
    var dur = Duration();
    for (var element in undetectedMutations) {
      dur += element.elapsed;
    }
    for (var element in detectedMutations) {
      dur += element.elapsed;
    }
    for (var element in timeoutMutations) {
      dur += element.elapsed;
    }
    return dur;
  }

  FileMutationResults(this.path, this.contents)
      : undetectedMutations = [],
        detectedMutations = [],
        timeoutMutations = [];

  bool lineHasUndetectedMutation(int i) {
    return _lineIsInList(undetectedMutations, i);
  }

  bool lineHasDetectedMutation(int i) {
    return _lineIsInList(detectedMutations, i);
  }

  bool lineHasTimeoutMutation(int i) {
    return _lineIsInList(timeoutMutations, i);
  }

  bool lineHasMutation(int i) {
    return _lineIsInList(undetectedMutations, i) ||
        _lineIsInList(detectedMutations, i) ||
        _lineIsInList(timeoutMutations, i);
  }

  bool lineHasProblem(int i) {
    return _lineIsInList(undetectedMutations, i) ||
        _lineIsInList(timeoutMutations, i);
  }

  bool _lineIsInList(List<MutatedLine> list, int i) {
    for (final m in list) {
      if (m.line == i) {
        return true;
      }
    }
    return false;
  }

  void sort() {
    undetectedMutations.sort((lhs, rhs) => lhs.line.compareTo(rhs.line));
    detectedMutations.sort((lhs, rhs) => lhs.line.compareTo(rhs.line));
    timeoutMutations.sort((lhs, rhs) => lhs.line.compareTo(rhs.line));
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

  /// stores the mutation results. Mapping filename -> results
  final Map<String, FileMutationResults> testedFiles = {};

  /// Returns a map containing the mutation results per file
  /// for a single rule. This method uses the parsed [index]
  /// for filtering.
  Map<String, FileMutationResults> filterResultsByRuleIndex(int index) {
    Map<String, FileMutationResults> rv = {};
    testedFiles.forEach((file, results) {
      final tmp = FileMutationResults(results.path, results.contents);
      results.detectedMutations
          .where((element) => element.mutation.index == index)
          .forEach((match) {
        tmp.detectedMutations.add(match);
      });
      results.undetectedMutations
          .where((element) => element.mutation.index == index)
          .forEach((match) {
        tmp.undetectedMutations.add(match);
      });
      results.timeoutMutations
          .where((element) => element.mutation.index == index)
          .forEach((match) {
        tmp.timeoutMutations.add(match);
      });
      if (tmp.mutationCount > 0) {
        rv[file] = tmp;
      }
    });
    return rv;
  }

  /// all files that were added as rules
  List<String> xmlFiles = [];
  Ratings quality = Ratings();

  final Stopwatch _timer = Stopwatch();

  Duration get elapsed => _timer.elapsed;

  final SystemInteractions writer;

  /// Creates a test runner and adds [inputFile] to the xml input file list.
  /// [builtinRulesAdded] sets the flag in the report file when the builtin rules were added.
  ResultsReporter(String inputFile, this.builtinRulesAdded, this.writer)
      : rules = [] {
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
    if (!testedFiles.containsKey(file)) {
      throw MutationError('"$file" was not registered in the reporter!');
    }
    _addRule(mutation.mutation);
    switch (test.result) {
      case TestResult.Timeout:
        if (verbose) {
          print('Timeout for ${test.command}');
        }
        _totalTimeouts += 1;
        addTimeoutMutation(file, mutation);
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
        addDetectedMutation(file, mutation);
        break;
      case TestResult.Undetected:
        if (verbose) {
          print('Undetected mutation! All tests passed!');
        }
        addUndetectedMutation(file, mutation);
        break;
    }
  }

  void _addRule(Mutation rule) {
    for (final existing in rules) {
      if (existing.index == rule.index) {
        return;
      }
    }
    rules.add(rule);
  }

  /// Starts a test run on the file [path].
  /// The [contents] of the file are used for the html reporting.
  void startFileTest(String path, String contents) {
    if (!testedFiles.containsKey(path)) {
      testedFiles[path] = FileMutationResults(path, contents);
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
  double get undetectedFraction =>
      _totalRuns > 0 ? (100.0 * undetectedMutations) / _totalRuns : 0.0;

  /// Reports the percentage of detected mutations of the total mutations.
  double get detectedFraction => _totalRuns > 0
      ? 100.0 - (100.0 * undetectedMutations) / _totalRuns
      : 100.0;

  /// Reports the percentage of mutations that ran into the timeout.
  double get timeoutFraction =>
      _totalRuns > 0 ? (100.0 * totalTimeouts) / _totalRuns : 0.0;

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
      value.sort();
    });
  }

  /// The list of all mutations that were executed
  List<Mutation> rules;

  /// Checks if all mutations were found.
  bool get foundAll => _totalRuns == _totalFound;

  /// Adds the undetected [mutation] from [file] to the list.
  void addUndetectedMutation(String file, MutatedLine mutation) {
    if (testedFiles.containsKey(file)) {
      testedFiles[file]!.undetectedMutations.add(mutation);
    } else {
      throw MutationError('"$file" was not registered in the reporter!');
    }
  }

  /// Adds the detected [mutation] from [file] to the list.
  void addDetectedMutation(String file, MutatedLine mutation) {
    if (testedFiles.containsKey(file)) {
      testedFiles[file]!.detectedMutations.add(mutation);
    } else {
      throw MutationError('"$file" was not registered in the reporter!');
    }
  }

  /// Adds a [mutation] from [file] to the timeout list.
  void addTimeoutMutation(String file, MutatedLine mutation) {
    if (testedFiles.containsKey(file)) {
      testedFiles[file]!.timeoutMutations.add(mutation);
    } else {
      throw MutationError('"$file" was not registered in the reporter!');
    }
  }

  /// Creates the XML report string
  String createXMLReport() {
    final text = StringBuffer(
        '<?xml version="1.0" encoding="UTF-8"?>\n<undetected-mutations>\n');
    text.write('<program-version>${mutationTestVersion()}</program-version>\n');
    text.write('<elapsed>$elapsed</elapsed>\n');
    text.write('<result rating="$rating" success="$success"/>\n');
    text.write('<rules>\n');
    for (final element in xmlFiles) {
      text.write('<ruleset document="$element"/>');
    }
    text.write('</rules>\n');
    testedFiles.forEach((key, value) {
      text.write('<file name="$key">\n');
      for (final mut in value.undetectedMutations) {
        text.write('<mutation line="${mut.line}">\n');
        text.write('<original>${convertToXML(mut.original)}</original>\n');
        text.write('<modified>${convertToXML(mut.mutated)}</modified>\n');
        text.write('</mutation>\n');
      }
      text.write('</file>\n');
    });
    text.write('</undetected-mutations>\n');
    return text.toString();
  }

  /// Writes the results of the tests to a xml file in directory [outpath].
  /// The report will be named like the [input], but ending with "-report.xml".
  void writeXMLReport(String outpath, String input) {
    final text = createXMLReport();
    final name =
        createReportFileName(_sanitizeInputFile(input), outpath, 'xml');
    _createPathsAndWriteFile(name, text);
  }

  /// Creates the markdown report string
  String createMarkdownReport() {
    var text = _createMarkdownHeader();
    testedFiles.forEach((key, value) {
      text += '## Undetected mutations in file : $key\n';
      for (final mut in value.undetectedMutations) {
        text += mut.toMarkdown();
      }
      text += '\n\n';
    });
    return text;
  }

  /// Writes the results of the tests to a markdown file in directory [outpath].
  /// The report will be named like the [input], but ending with "-report.md".
  void writeMarkdownReport(String outpath, String input) {
    var text = createMarkdownReport();
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

  /// Writes the xunit report in directory [outpath].
  /// The report will have the basename of [input], but ending with "-xunit.xml".
  void writeXUnitReport(String outpath, String input) {
    final contents = createXUnitReport(this, false);
    final fname = createReportFileName(_sanitizeInputFile(input), outpath, '',
        appendReport: false);
    _createPathsAndWriteFile(
        '${fname.substring(0, fname.length - 1)}-xunit.xml', contents);
  }

  /// Writes the junit report in directory [outpath].
  /// The report will have the basename of [input], but ending with "-junit.xml".
  void writeJUnitReport(String outpath, String input) {
    final contents = createXUnitReport(this, true);
    final fname = createReportFileName(_sanitizeInputFile(input), outpath, '',
        appendReport: false);
    _createPathsAndWriteFile(
        '${fname.substring(0, fname.length - 1)}-junit.xml', contents);
  }

  String _sanitizeInputFile(String input) {
    if (input.isNotEmpty) {
      return input;
    }
    return 'mutation-test';
  }

  void _createPathsAndWriteFile(String path, String text) {
    writer.createPathsAndWriteFile(path, text);
  }

  String _createMarkdownHeader() {
    final rv = StringBuffer('''# Mutation report
This is a mutation report generated by ${mutationTestVersion()}

${DateTime.now()}

| Key           | Value                     |
| ------------- | ------------------------- |
''');
    for (final element in xmlFiles) {
      rv.write('| Rules         | $element           |\n');
    }
    rv.write('''
| Mutations     | $_totalRuns                        |
| Elapsed     | $elapsed                        |
| Timeouts      | $_totalTimeouts                        |
| Undetected    | $undetectedMutations                        |
| Undetected%   | ${asPercentString(undetectedMutations, _totalRuns)}                        |
''');
    _groupStatistics.forEach((k, v) {
      rv.write('| Detected by: $k            | $v         |\n');
    });
    rv.write('| Quality Rating | $rating |\n');
    rv.write('| Success | $success |\n\n\n');
    return rv.toString();
  }
}
