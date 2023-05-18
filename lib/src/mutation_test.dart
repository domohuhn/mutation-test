// Copyright 2021, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:io';

import 'package:mutation_test/src/core/commands.dart';
import 'package:mutation_test/src/core/mutation.dart';
import 'package:mutation_test/src/reports/command_line_report.dart';
import 'package:mutation_test/src/reports/html_report.dart';
import 'package:mutation_test/src/reports/markdown_report.dart';
import 'package:mutation_test/src/reports/report_data.dart';
import 'package:mutation_test/src/reports/xml_report.dart';
import 'package:mutation_test/src/reports/xunit_report.dart';
import 'package:mutation_test/src/core/test_runner.dart';
import 'package:mutation_test/src/core/errors.dart';
import 'package:mutation_test/src/configuration/configuration.dart';
import 'package:mutation_test/src/reports/report_formats.dart';
import 'package:mutation_test/src/configuration/builtin_rules.dart';
import 'package:mutation_test/src/core/app_progress_bar.dart';
import 'package:mutation_test/src/core/system_interactions.dart';

/// This is the primary interface for the mutation testing.
///
/// To do a test run, create an instance of this class, then
/// call the method [runMutationTest()].
class MutationTest {
  /// The list of input files.
  List<String> inputs;

  /// The list of rule files to load.
  List<String>? ruleFiles;

  /// The path where the reports are generated if the report format is not none.
  String outputPath;

  /// The format in which reports are generated.
  ReportFormat format;

  /// If the test runner should print many messages to the command line.
  bool verbose;

  /// Performs a dry run - no actual mutations are applied and no test commands are run.
  bool dry;

  /// If the builtin rules should be loaded.
  bool builtinRules;

  /// The progress bar printed to the command line.
  late AppProgressBar bar;

  /// If any messages should be printed to the command line.
  bool quiet;

  /// Abstraction for the system.
  SystemInteractions system;

  /// Runs the mutation tests using the inputs from [inputs].
  /// Undetected modifications are written to a file in [outputPath] using the
  /// specified [format].
  ///
  /// The testrunner will use builtin mutation rules if [builtinRules] is set to true.
  /// Additionally the [ruleFiles] will be loaded.
  ///
  /// The amount of output to the command line is controlled via [verbose].
  /// You can perform a [dry] run that wil not run any tests or perform any modifications,
  /// but will list all found mutations per file.
  /// Returns true if all modifications were detected by the test commands.
  ///
  /// Writing output to the command line can be suppressed if [quiet] is set.
  MutationTest(
      this.inputs, this.outputPath, this.verbose, this.dry, this.format,
      {this.ruleFiles, this.builtinRules = true, this.quiet = false})
      : system = SystemInteractions(verbose, quiet) {
    bar = AppProgressBar(0, 0.8, system);
  }

  /// Performs the mutation tests asynchronously.
  /// The test run uses the options given during construction.
  ///
  /// During testing, a new process will be spawned for each given command.
  Future<bool> runMutationTest() async {
    await _countAll();
    var foundAll = true;
    if (inputs.isNotEmpty) {
      for (final file in inputs) {
        var result = await _runMutationTest(
            file, outputPath, verbose, dry, format,
            ruleFiles: ruleFiles, addBuiltin: builtinRules);
        foundAll = result && foundAll;
      }
    } else {
      await _runMutationTest('', outputPath, verbose, dry, format,
          ruleFiles: ruleFiles,
          addBuiltin: builtinRules,
          useDefaultConfig: true);
    }
    return foundAll;
  }

  /// Runs the mutation tests using the xml configuration file [inputFile].
  /// Undetected modifications are written to a file in [outputPath] using the
  /// specified [format].
  ///
  /// The testrunner will use builtin mutation rules if [addBuiltin] is set to true.
  /// Additionally the [ruleFiles] will be loaded.
  ///
  /// The amount of output to the command line is controlled via [verbose].
  /// You can perform a [dry] run that wil not run any tests or perform any modifications,
  /// but will list all found mutations per file.
  /// Returns true if all modifications were detected by the test commands.
  Future<bool> _runMutationTest(String inputFile, String outputPath,
      bool verbose, bool dry, ReportFormat format,
      {List<String>? ruleFiles,
      bool addBuiltin = true,
      bool useDefaultConfig = false}) async {
    var data = _createMutationData(inputFile, outputPath, verbose, dry, format,
        ruleFiles: ruleFiles,
        addBuiltin: addBuiltin,
        useDefaultConfig: useDefaultConfig);

    await checkTests(data.configuration, data.test);

    for (final current in data.configuration.files) {
      final source = File(current.path).readAsStringSync();
      data.filename = current;
      data.contents = source;

      var count = await countMutations(data);
      data.results.startFileTest(current.path, data.contents);
      data.bar.startFile(current.path, count);
      if (dry || count == 0) {
        continue;
      }

      var failed = await doMutationTests(data);
      data.bar.endFile(failed);

      // restore orignal
      File(current.path).writeAsStringSync(source);
      if (!_continue) {
        break;
      }
    }
    if (!dry) {
      createReport(data.results, outputPath, inputFile, format);
    }
    return data.results.success;
  }

  /// Count all mutations done in all input files
  Future<void> _countAll() async {
    var totalCount = 0;
    var fileCount = 0;
    for (final file in inputs) {
      var data = _createMutationData(file, outputPath, false, dry, format,
          ruleFiles: ruleFiles, addBuiltin: builtinRules);
      for (final current in data.configuration.files) {
        final source = File(current.path).readAsStringSync();
        data.filename = current;
        data.contents = source;

        var count = await countMutations(data);
        totalCount += count;
        fileCount += 1;
      }
    }
    if (inputs.isEmpty) {
      var data = _createMutationData('', outputPath, false, dry, format,
          ruleFiles: ruleFiles,
          addBuiltin: builtinRules,
          useDefaultConfig: true);
      for (final current in data.configuration.files) {
        final source = File(current.path).readAsStringSync();
        data.filename = current;
        data.contents = source;

        var count = await countMutations(data);
        totalCount += count;
        fileCount += 1;
      }
    }
    system.writeLine('Found $totalCount mutations in $fileCount source files!');
    bar.mutationCount = totalCount;
  }

  MutationData _createMutationData(String inputFile, String outputPath,
      bool verbose, bool dry, ReportFormat format,
      {List<String>? ruleFiles,
      bool addBuiltin = true,
      bool useDefaultConfig = false}) {
    final configuration = Configuration(verbose, dry);
    final tests = TestRunner();
    final reporter =
        ReportData(inputFile, addBuiltin, SystemInteractions(verbose, quiet));
    _testRunner = tests;
    if (ruleFiles != null && ruleFiles.isNotEmpty) {
      for (final rf in ruleFiles) {
        configuration.addRulesFromFile(rf);
        reporter.xmlFiles.add(rf);
      }
    }
    if (addBuiltin) {
      system.verboseWriteLine('Adding the builtin default mutation rules!');
      reporter.xmlFiles.add('Builtin Rules');
      configuration.parseXMLString(builtinMutationRules());
    }
    if (!useDefaultConfig) {
      if (inputFile.endsWith('.xml')) {
        system.verboseWriteLine(
            'Loading additional XML configuration : "$inputFile"');
        configuration.addRulesFromFile(inputFile);
      } else {
        configuration.files.add(TargetFile(inputFile, []));
      }
    } else {
      system.verboseWriteLine(
          'No input files found - assuming default dart configuration!');
      configuration.parseXMLString(dartDefaultConfiguration());
    }
    configuration.validate();
    reporter.quality = configuration.ratings;
    bar.threshold = configuration.ratings.failure;
    return MutationData(
        configuration, tests, TargetFile('', []), '', reporter, bar);
  }

  /// Checks if the tests in [cfg] can be run by the test runner [executor] on the unmodified sources.
  Future<void> checkTests(Configuration cfg, TestRunner executor) async {
    system.verboseWriteLine(
        'Checking if the test commands work with unmodified sources ...');
    if (cfg.dry) {
      return;
    }
    var test = await executor.run(cfg, system, outputOnFailure: true);
    if (test.result != TestResult.Undetected) {
      throw MutationError(
          'Running the test commands failed with unmodified code! Aborting.');
    }
  }

  /// Counts the mutations possible mutations in [data].
  Future<int> countMutations(MutationData data) async {
    return doMutationTests(data, supressVerbose: true,
        functor: (MutationData data, MutatedCode mutated) async {
      return true;
    });
  }

  /// Performs the mutation tests in [data].
  /// The unmodified contents of the file are mutated
  /// using all mutation rules in [data] and then the tests are run.
  /// Returns the number of undetected mutations.
  Future<int> doMutationTests(MutationData data,
      {Future<bool> Function(MutationData data, MutatedCode mutated) functor =
          _runTest,
      bool supressVerbose = false}) async {
    var failed = 0;
    for (final mutation in data.configuration.mutations) {
      if (data.configuration.verbose && !supressVerbose) {
        print('Pattern: ${mutation.pattern}');
      }
      for (final m in mutation.allMutations(data.contents,
          data.filename.whitelist, data.configuration.exclusions)) {
        if (data.configuration.verbose && !supressVerbose) {
          print('${m.line}');
        }
        if (!_continue) {
          return failed;
        }
        var result = await functor(data, m);
        if (result) {
          failed += 1;
        }
      }
    }
    return failed;
  }

  /// No new tests are started if this is set to false
  bool _continue = true;

  /// We need to sent a sigkill to the child process, otherwise the program might hang
  TestRunner? _testRunner;

  /// Aborts the tests and restores the original state of the source code.
  void abortMutationTest() {
    _continue = false;
    system.writeLine('Abort requested! Waiting for unfinished tasks...');
    if (_testRunner != null) {
      _testRunner!.kill();
    }
  }
}

/// Writes the [mutated] code to disk and runs the tests.
/// Undetected Mutations are added to the TestRunner in [data].
/// Returns true if the mutation was not found by the tests.
Future<bool> _runTest(MutationData data, MutatedCode mutated) async {
  final Stopwatch timer = Stopwatch()..start();
  File(data.filename.path).writeAsStringSync(mutated.text);
  final test = await data.test.run(data.configuration, data.results.system);
  timer.stop();
  mutated.line.elapsed = timer.elapsed;
  data.results.addTestReport(data.filename.path, mutated.line, test);
  data.bar.increment();
  data.bar.render();
  return test.result == TestResult.Undetected;
}

/// Data structure holding all data for a mutation run.
class MutationData {
  /// The current configuration
  final Configuration configuration;

  /// The testrunner
  final TestRunner test;

  /// Name of the file to mutate
  TargetFile filename;

  /// Contents of the file to mutate
  String contents;

  /// Class to store the results in
  final ReportData results;

  /// A reference to the progress bar.
  final AppProgressBar bar;

  /// Checks if the reporting should be verbose.
  bool get verbose => configuration.verbose;

  /// Constructor for the mutation data.
  /// The object is given to the test runner to run tests on the given [filename].
  MutationData(this.configuration, this.test, this.filename, this.contents,
      this.results, this.bar);
}

/// Creates the test report in directory [outputPath] from [inputFile]
/// in the specified [format] using the [results].
void createReport(ReportData results, String outputPath, String inputFile,
    ReportFormat format) {
  writeCommandLineReport(results, results.system);
  results.sort();
  switch (format) {
    case ReportFormat.NONE:
      return;
    case ReportFormat.XML:
      writeXMLReport(outputPath, inputFile, results, results.system);
      break;
    case ReportFormat.MARKDOWN:
      writeMarkdownReport(outputPath, inputFile, results, results.system);
      break;
    case ReportFormat.HTML:
      writeHTMLReport(outputPath, inputFile, results, results.system);
      break;
    case ReportFormat.XUNIT:
      writeXUnitReport(outputPath, inputFile, results, results.system);
      break;
    case ReportFormat.JUNIT:
      writeJUnitReport(outputPath, inputFile, results, results.system);
      break;
    case ReportFormat.ALL:
      writeXMLReport(outputPath, inputFile, results, results.system);
      writeMarkdownReport(outputPath, inputFile, results, results.system);
      writeHTMLReport(outputPath, inputFile, results, results.system);
      writeXUnitReport(outputPath, inputFile, results, results.system);
      writeJUnitReport(outputPath, inputFile, results, results.system);
      break;
  }
  results.system.writeLine('Output has been written to $outputPath');
}
