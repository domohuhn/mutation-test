// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/errors.dart';
import 'package:mutation_test/src/reports/file_mutation_results.dart';
import 'package:mutation_test/src/system_interactions.dart';
import 'package:mutation_test/src/mutations.dart';
import 'package:mutation_test/src/ratings.dart';
import 'package:mutation_test/src/reports/string_helpers.dart';
import 'package:mutation_test/src/commands.dart';

/// This class holds the results of the mutation test run.
///
/// The results are stored in a map with an entry for each file.
class ReportData {
  /// statistics which command group caught how many mutations
  final Map<String, int> _groupStatistics = {};

  /// stores the mutation results. Mapping filename -> results
  final Map<String, FileMutationResults> testedFiles = {};

  Map<String, int> get groupStatistics => _groupStatistics;

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

  /// Creates a results storage and adds [inputFile] to the xml input file list.
  /// [builtinRulesAdded] sets a flag showing if the builtin rules were added.
  ReportData(String inputFile, this.builtinRulesAdded, this.writer)
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
  /// This method will print to the command line via the verbose is true.
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
}