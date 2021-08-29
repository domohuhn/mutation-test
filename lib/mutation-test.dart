


import 'dart:io';
import 'package:mutation_test/mutations.dart';

import 'test-runner.dart';
import 'errors.dart';
import 'configuration.dart';
import 'string-helpers.dart';
import 'report-format.dart';
import 'range.dart';
import 'builtin-rules.dart';

export 'report-format.dart';
export 'builtin-rules.dart';

/// Runs the mutation tests using the xml configuration file [inputFile].
/// Undetected modifications are written to a file in [outputPath] using the 
/// specified [format].
/// 
/// The testrunner will use builtin mutation rules unless a path to a XML file
/// is given as [ruleFile].
/// 
/// The amount of output to the command line is controlled via [verbose].
/// You can perform a [dry] run that wil not run any tests or perform any modifications,
/// but will list all found mutations per file.
/// Returns true if all modifications were detected by the test commands. 
bool runMutationTest(String inputFile, String outputPath, bool verbose, bool dry, ReportFormat format,
    {String? ruleFile}) {
  final configuration = Configuration.fromFile(inputFile, verbose, dry);
  final tests = TestRunner(inputFile);
  if (ruleFile!=null) {
    configuration.addRulesFromFile(ruleFile);
    tests.xmlFiles.add(ruleFile);
  } else {
    if(verbose) {
      print('No ruleset given - adding builtin ruleset!');
    }
    tests.xmlFiles.add('Built in Ruleset');
    configuration.parseXMLString(builtinMutationRules());
  }
  configuration.validate();

  checkTests(configuration,tests);

  for (final current in configuration.files) {
    final source = File(current).readAsStringSync();
    var data = MutationData(configuration,tests,current,source);
    var count = countMutations(data);
    print('$current : performing $count mutations');
    if (dry || count==0) {
      continue;
    }
    var failed = doMutationTests(data);
    if (failed > 0) {
      print('FAILED: $failed (${asPercentString(failed, count)}) mutations passed all tests!');
    }

    // restore orignal
    File(current).writeAsStringSync(source);
  }
  if(!dry) {
    createReport(tests,outputPath,inputFile,format);
  }
  return tests.foundAll;
}


/// Data structure holding all data for a mutation run.
class MutationData {
  /// The current configuration
  final Configuration configuration;
  /// The testrunner
  final TestRunner test;
  /// Name of the file to mutate
  final String filename;
  /// Contents of the file to mutate
  final String contents;
  
  MutationData(this.configuration,this.test,this.filename,this.contents);
}

/// Checks if the tests in [cfg] can be run by the test runner [test] on the unmodified sources.
void checkTests(Configuration cfg, TestRunner test) {
  if (cfg.verbose) {
    print('Checking if the test commands work with unmodified sources ...');
  }
  test.prepare(cfg);
  if (cfg.dry) {
    return;
  }
  if (!test.run(cfg, outputOnFailure: true)) {
    throw Error('Running the test commands failed with unmodified code! Aborting.');
  }
}

/// Counts the mutations possible mutations in [data].
int countMutations(MutationData data) {
  return doMutationTests(data, functor: (MutationData data, MutatedCode mutated) {return true;}) ;
}

/// Performs the mutation tests in [data].
/// The unmodified contents of the file are mutated
/// using all mutation rules in [data] and then the tests are run.
/// Returns the number of undetected mutations.
int doMutationTests(MutationData data,
   {bool Function(MutationData data, MutatedCode mutated) functor = runTest,
   bool supressVerbose=false}) {
  var failed = 0;
  for (final mutation in data.configuration.mutations) {
    if (data.configuration.verbose&&!supressVerbose) {
      print('Pattern: ${mutation.pattern}');
    }
    for ( final m in mutation.allMutations(data.contents, data.configuration.exclusions) ) {
      if(functor(data,m)) {
        failed += 1;
      }
    }
  }
  return failed;
}

/// Writes the [mutated] code to disk and runs the tests. 
/// Undetected Mutations are added to the TestRunner in [data].
/// Returns true if the mutation was not found by the tests.
bool runTest(MutationData data, MutatedCode mutated) {
  File(data.filename).writeAsStringSync(mutated.text);
  if (data.test.run(data.configuration)) {
    data.test.addMutation(data.filename, mutated.line);
    return true;
  }
  return false;
}




