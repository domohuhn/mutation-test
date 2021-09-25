/// Copyright 2021, domohuhn. 
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license


import 'dart:io';

import 'mutations.dart';
import 'test-runner.dart';
import 'errors.dart';
import 'configuration.dart';
import 'report-format.dart';
import 'builtin-rules.dart';
import 'mutation-progress-bar.dart';

export 'report-format.dart';
export 'builtin-rules.dart';
export 'create-license-text.dart';


class MutationTest {

  List<String> inputs;
  List<String>? ruleFiles;
  String outputPath;
  ReportFormat format;
  bool verbose;
  bool dry;
  bool builtinRules;
  MutationProgressBar bar;
  bool quiet;

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
  MutationTest(this.inputs, this.outputPath, this.verbose, this.dry, this.format,
      {this.ruleFiles, this.builtinRules=true, this.quiet=false}) : bar = MutationProgressBar(0,verbose,0.8,quiet);

  Future<bool> runMutationTest() async {
    await _countAll();
    var foundAll = true;
    for (final file in inputs) {
      var result = await _runMutationTest(
          file, outputPath, verbose, dry, format,
          ruleFiles: ruleFiles,
          addBuiltin: builtinRules);
      foundAll = result && foundAll;
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
  Future<bool> _runMutationTest(String inputFile, String outputPath, bool verbose, bool dry, ReportFormat format,
      {List<String>? ruleFiles, bool addBuiltin=true}) async {
    var data = _createMutationData(inputFile,outputPath,verbose,dry,format,ruleFiles: ruleFiles, addBuiltin: addBuiltin);

    await checkTests(data.configuration,data.test);

    for (final current in data.configuration.files) {
      final source = File(current.path).readAsStringSync();
      data.filename = current;
      data.contents = source;

      var count = await countMutations(data);
      data.bar.startFile(current.path,count);
      if (dry || count==0) {
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
    if(!dry) {
      createReport(data.results,outputPath,inputFile,format);
    }
    return data.results.success;
  }

  /// Count all mutations done in all input files
  Future<void> _countAll() async
  {
    var totalCount = 0;
    for (final file in inputs) {
      var data = _createMutationData(file,outputPath,false,dry,format,ruleFiles: ruleFiles, addBuiltin: builtinRules);
      for (final current in data.configuration.files) {
        final source = File(current.path).readAsStringSync();
        data.filename = current;
        data.contents = source;

        var count = await countMutations(data);
        totalCount += count;
      }
    }
    bar.mutationCount = totalCount;
  }

  MutationData _createMutationData(String inputFile, String outputPath, bool verbose, bool dry, ReportFormat format,
      {List<String>? ruleFiles, bool addBuiltin=true}) {
    final configuration = Configuration(verbose, dry);
    final tests = TestRunner();
    final reporter = ResultsReporter(inputFile);
    _testRunner = tests;
    if (ruleFiles!=null && ruleFiles.isNotEmpty) {
      for(final rf in ruleFiles) {
        configuration.addRulesFromFile(rf);
        reporter.xmlFiles.add(rf);
      }
    }
    if (addBuiltin) {
      if(verbose) {
        print('Adding the builtin default mutation rules!');
      }
      reporter.xmlFiles.add('Builtin Rules');
      configuration.parseXMLString(builtinMutationRules());
    }
    if (inputFile.endsWith('.xml')) {
      if(verbose) {
        print('Loading additional XML configuration : "$inputFile"');
      }
      configuration.addRulesFromFile(inputFile);
    }
    else {
      configuration.files.add(TargetFile(inputFile, []));
    }
    configuration.validate();
    reporter.quality = configuration.ratings;
    bar.threshold = configuration.ratings.failure;
    return MutationData(configuration,tests,TargetFile('',[]),'',reporter,bar);
  }

  /// Checks if the tests in [cfg] can be run by the test runner [executor] on the unmodified sources.
  Future<void> checkTests(Configuration cfg, TestRunner executor) async {
    if (cfg.verbose) {
      print('Checking if the test commands work with unmodified sources ...');
    }
    if (cfg.dry) {
      return;
    }
    var test = await executor.run(cfg, outputOnFailure: true);
    if (test.result != TestResult.Undetected) {
      throw Error('Running the test commands failed with unmodified code! Aborting.');
    }
  }

  /// Counts the mutations possible mutations in [data].
  Future<int> countMutations(MutationData data) async {
    return doMutationTests(data, supressVerbose: true, functor: (MutationData data, MutatedCode mutated) async {return true;}) ;
  }

  /// Performs the mutation tests in [data].
  /// The unmodified contents of the file are mutated
  /// using all mutation rules in [data] and then the tests are run.
  /// Returns the number of undetected mutations.
  Future<int> doMutationTests(MutationData data,
    {Future<bool> Function(MutationData data, MutatedCode mutated) functor = _runTest,
    bool supressVerbose=false}) async {
    var failed = 0;
    for (final mutation in data.configuration.mutations) {
      if (data.configuration.verbose&&!supressVerbose) {
        print('Pattern: ${mutation.pattern}');
      }
      for (final m in mutation.allMutations(data.contents,data.filename.whitelist , data.configuration.exclusions) ) {
        if (data.configuration.verbose&&!supressVerbose) {
          print('${m.line}');
        }
        if(!_continue) {
          return failed;
        }
        var result = await functor(data,m);
        if(result) {
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
    print('Abort requested! Waiting for unfinished tasks...');
    if (_testRunner!=null) {
      _testRunner!.kill();
    }
  }

}

/// Writes the [mutated] code to disk and runs the tests. 
/// Undetected Mutations are added to the TestRunner in [data].
/// Returns true if the mutation was not found by the tests.
Future<bool> _runTest(MutationData data, MutatedCode mutated) async {
  File(data.filename.path).writeAsStringSync(mutated.text);
  var test = await data.test.run(data.configuration);
  data.results.addTestReport(data.filename.path, mutated.line, test, data.configuration.verbose);
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
  final ResultsReporter results;

  final MutationProgressBar bar;

  bool get verbose => configuration.verbose;
  
  MutationData(this.configuration,this.test,this.filename,this.contents,this.results,this.bar);
}

String mutationTestVersion() {
  return 'mutation-test version: 1.1.0';
}
