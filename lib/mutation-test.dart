


import 'dart:io';
import 'package:mutation_test/mutations.dart';

import 'test-runner.dart';
import 'errors.dart';
import 'configuration.dart';
import 'string-helpers.dart';

/// Runs the mutation tests using the xml configuration file [inputFile].
/// Undetected modifications are written to a [outputPath].
/// 
/// The amount of output to the command line is controlled via [verbose].
/// You can perform a [dry] run that wil not run any tests or perform any modifications,
/// but will list all found mutations per file.
/// Returns true if all modifications were detected by the test commands. 
bool runMutationTest(String inputFile, String outputPath, bool verbose, bool dry) {
  final configuration = Configuration.fromFile(inputFile, verbose, dry);
  final tests = TestRunner();

  checkTests(configuration,tests);

  for (final current in configuration.files) {
    final source = File(current).readAsStringSync();
    var count = countMutations(configuration,source);
    print('$current : performing $count mutations');
    if (dry || count==0) {
      continue;
    }
    var failed = doMutationTests(configuration,tests,current,source);
    if (failed > 0) {
      print('FAILED: $failed (${asPercentString(failed, count)}) mutations passed all tests!');
    }

    // restore orignal
    File(current).writeAsStringSync(source);
  }
  tests.printResults();
  tests.writeMarkdownReport(outputPath, inputFile);
  return tests.foundAll;
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

/// Counts the mutations in [text] that are specified in [config].
int countMutations(Configuration config, String text) {
  var rv = 0;
  for (final mutation in config.mutations) {
    var count = mutation.replacements.length;
    final matches = mutation.pattern.allMatches(text);
    rv += count * matches.length;
  }
  return rv;
}

/// Performs the mutation tests in [config] on [filename].
/// The unmodified contents of the file in [original] are mutated
/// and then the [test]s are run.
/// Returns the number of undetected mutations.
int doMutationTests(Configuration config, TestRunner test, String filename, String original) {
  var failed = 0;
  for (final mutation in config.mutations) {
    if (config.verbose) {
      print('Pattern: ${mutation.pattern}');
    }
    final matches = mutation.pattern.allMatches(original);
    for ( final m in matches ) {
      failed += doReplacements(config,test,filename,original,m,mutation.replacements);
    }
  }
  return failed;
}

/// Performs all [replacements] for the [match] in the [original] file contents.
/// The modified file is written an [filename] and then all [tests] specified in [config] are run. 
/// Undetected Mutations are added to the TestRunner.
/// Returns the number of undetected mutations.
int doReplacements(Configuration config, TestRunner test, String filename, String original, Match match, List<String> replacements) {
  var failed = 0;
  for (final repl in replacements) {
    if (config.verbose) {
      print('Mutation: $repl');
    }
    final mutated = original.substring(0,match.start) + repl + original.substring(match.end);
    File(filename).writeAsStringSync(mutated);
    if (test.run(config)) {
      if (config.verbose) {
        print('undetected mutation!');
      }
      addMutationtoTestRunner(test,filename,match.start,match.end,original,mutated);
      failed += 1;
    }
  }
  return failed;
}

/// Adds a mutation to the Testrunner.
void addMutationtoTestRunner(TestRunner test,String file, int absoluteStart, int absoluteEnd, String original, String mutated) {
  final line = findLineFromPosition(original,absoluteStart);
  final lineStart = findBeginOfLineFromPosition(original, absoluteStart);
  final lineEnd = findEndOfLineFromPosition(original, absoluteStart);
  final mutationStart = absoluteStart-lineStart;
  final mutationEnd = absoluteEnd-lineStart;
  final lineEndMutated = findEndOfLineFromPosition(mutated, absoluteStart);
  final mut = UndetectedMutation(line,mutationStart ,mutationEnd,original.substring(lineStart,lineEnd), mutated.substring(lineStart,lineEndMutated));
  test.addMutation(file, mut);
}

