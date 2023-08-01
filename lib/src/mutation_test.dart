// Copyright 2021, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/core/core.dart';
import 'package:mutation_test/src/reports/create_report.dart';
import 'package:mutation_test/src/reports/report_data.dart';
import 'package:mutation_test/src/configuration/configuration.dart';
import 'package:mutation_test/src/reports/report_formats.dart';
import 'package:mutation_test/src/configuration/builtin_rules.dart';

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

  /// The results of the test run
  late ReportData reporter;

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
  late SystemInteractions system;

  /// Factory creating other objects
  late PlatformFactory platformFactory;

  /// Runs the mutation tests using the inputs from [inputs].
  /// Undetected modifications are written to a file in [outputPath] using the
  /// specified [format].
  ///
  /// The test runner will use builtin mutation rules if [builtinRules] is set to true.
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
      {this.ruleFiles,
      this.builtinRules = true,
      this.quiet = false,
      PlatformFactory? platform}) {
    platformFactory = platform ?? PlatformFactory();
    system = platformFactory.createSystemInteractions(
        verbose: verbose, quiet: quiet);
    reporter = ReportData(builtinRules, system);
    bar = AppProgressBar(0, 0.8, system);
  }

  /// Performs the mutation tests asynchronously.
  /// The test run uses the options given during construction.
  ///
  /// During testing, a new process will be spawned for each given command.
  Future<bool> runMutationTest() async {
    await count();
    var foundAll = true;
    if (inputs.isNotEmpty) {
      for (final file in inputs) {
        var result = await _runMutationTest(file, dry,
            ruleFiles: ruleFiles, addBuiltin: builtinRules);
        foundAll = result && foundAll;
      }
    } else {
      foundAll = await _runMutationTest('', dry,
          ruleFiles: ruleFiles,
          addBuiltin: builtinRules,
          useDefaultConfig: true);
    }
    createReport(reporter, outputPath, format);
    return foundAll;
  }

  /// Runs the mutation tests using the xml configuration file [inputFile].
  ///
  /// The test runner will use builtin mutation rules if [addBuiltin] is set to true.
  /// Additionally the [ruleFiles] will be loaded.
  ///
  /// The amount of output to the command line is controlled via [verbose].
  /// You can perform a [dry] run that wil not run any tests or perform any modifications,
  /// but will list all found mutations per file.
  /// Returns true if all modifications were detected by the test commands.
  Future<bool> _runMutationTest(String inputFile, bool dry,
      {List<String>? ruleFiles,
      bool addBuiltin = true,
      bool useDefaultConfig = false}) async {
    var data = _createMutationData(inputFile, outputPath, dry, format,
        ruleFiles: ruleFiles,
        addBuiltin: addBuiltin,
        useDefaultConfig: useDefaultConfig);

    await checkTests(data.configuration, data.test);

    for (final current in data.configuration.files) {
      final source = system.readFile(current.path);
      data.filename = current;
      data.contents = source;

      var count = await _countMutations(data);
      data.results.startFileTest(current.path, data.contents);
      data.bar.startFile(current.path, count);
      if (count == 0) {
        continue;
      }

      var failed = await _doMutationTests(data);
      data.bar.endFile(failed);
      if (dry) {
        continue;
      }

      // restore original
      system.writeFile(current.path, source);
      if (!_continue) {
        break;
      }
    }
    return data.results.success;
  }

  /// Counts all mutations done by all input files
  Future<int> count() async {
    var totalCount = 0;
    var fileCount = 0;
    for (final file in inputs) {
      final data = _createMutationDataFromMembers(file, false);
      for (final current in data.configuration.files) {
        totalCount += await _readFileAndCountMutations(current, data);
        fileCount += 1;
      }
    }
    if (inputs.isEmpty) {
      final data = _createMutationDataFromMembers('', true);
      for (final current in data.configuration.files) {
        totalCount += await _readFileAndCountMutations(current, data);
        fileCount += 1;
      }
    }
    system.writeLine('Found $totalCount mutations in $fileCount source files!');
    bar.mutationCount = totalCount;
    return totalCount;
  }

  /// Gets the number of total mutations found.
  /// You must call count() or runMutationTest() first.
  int get total => bar.total.maximum;

  MutationData _createMutationDataFromMembers(
      String file, bool useDefaultConfig) {
    return _createMutationData(file, outputPath, dry, format,
        ruleFiles: ruleFiles,
        addBuiltin: builtinRules,
        useDefaultConfig: useDefaultConfig);
  }

  Future<int> _readFileAndCountMutations(
      TargetFile current, MutationData data) async {
    final source = system.readFile(current.path);
    data.filename = current;
    data.contents = source;
    return await _countMutations(data);
  }

  MutationData _createMutationData(
      String inputFile, String outputPath, bool dry, ReportFormat format,
      {List<String>? ruleFiles,
      bool addBuiltin = true,
      bool useDefaultConfig = false}) {
    final configuration = Configuration(system, dry);
    final tests = platformFactory.createTestRunner();
    reporter.addInputFile(inputFile);
    _testRunner = tests;
    if (ruleFiles != null && ruleFiles.isNotEmpty) {
      for (final rf in ruleFiles) {
        configuration.addRulesFromFile(rf);
        reporter.addInputFile(rf);
      }
    }
    if (addBuiltin) {
      system.verboseWriteLine('Adding the builtin default mutation rules!');
      reporter.addInputFile('Builtin Rules');
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
    configuration.inferCommandsIfEmpty();
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
  Future<int> _countMutations(MutationData data) async {
    return _doMutationTests(data, suppressVerbose: true,
        functor: (MutationData data, MutatedCode mutated) async {
      return true;
    });
  }

  /// Performs the mutation tests in [data].
  /// The unmodified contents of the file are mutated
  /// using all mutation rules in [data] and then the tests are run.
  /// Returns the number of undetected mutations.
  Future<int> _doMutationTests(MutationData data,
      {Future<bool> Function(MutationData data, MutatedCode mutated) functor =
          _runTest,
      bool suppressVerbose = false}) async {
    var failed = 0;
    for (final mutation in data.configuration.mutations) {
      if (!suppressVerbose) {
        data.results.system.verboseWriteLine('Pattern: ${mutation.pattern}');
      }
      for (final m in mutation.allMutations(data.contents,
          data.filename.whitelist, data.configuration.exclusions)) {
        if (!suppressVerbose) {
          data.results.system.verboseWriteLine('${m.line}');
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

  /// Reference to the test process. We need to sent a sigkill to the child process, otherwise the program might hang
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
  if (data.configuration.dry) {
    data.results.addTestReport(
        data.filename.path, mutated.line, TestReport(TestResult.Undetected));
    return true;
  }
  final Stopwatch timer = Stopwatch()..start();
  data.results.system.writeFile(data.filename.path, mutated.text);
  final test = await data.test.run(data.configuration, data.results.system);
  timer.stop();
  mutated.line.elapsed = timer.elapsed;
  data.results.addTestReport(data.filename.path, mutated.line, test);
  data.bar.increment();
  data.bar.render();
  return test.result == TestResult.Undetected;
}
