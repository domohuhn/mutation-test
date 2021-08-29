


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
  createReport(tests,outputPath,inputFile,format);
  return tests.foundAll;
}


/// Data structure holding all data for a mutation run.
class MutationData {
  final Configuration configuration;
  final TestRunner test;
  final String filename;
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
  return doMutationTests(data, functor: (MutationData data, Match m, List<String> l) {return l.length;}) ;
}

/// Performs the mutation tests in [data].
/// The unmodified contents of the file are mutated
/// using all mutation rules in [data] and then the tests are run.
/// Returns the number of undetected mutations.
int doMutationTests(MutationData data,
   {int Function(MutationData data, Match, List<String>) functor = doReplacements,
   bool supressVerbose=false}) {
  var failed = 0;
  for (final mutation in data.configuration.mutations) {
    if (data.configuration.verbose&&!supressVerbose) {
      print('Pattern: ${mutation.pattern}');
    }
    final matches = mutation.pattern.allMatches(data.contents);
    for ( final m in matches ) {
      if(!isInExclusionRange(data.configuration.exclusions,data.contents,m.start)
         && !isInExclusionRange(data.configuration.exclusions,data.contents,m.end) ) {
        failed += functor(data,m,mutation.replacements);
      }
    }
  }
  return failed;
}

/// Performs all [replacements] for the [match] in the [original] file contents.
/// The modified file is written an [filename] and then all [tests] specified in [config] are run. 
/// Undetected Mutations are added to the TestRunner.
/// Returns the number of undetected mutations.
int doReplacements(MutationData data, Match match, List<String> replacements) {
  var failed = 0;
  for (final repl in replacements) {
    if (data.configuration.verbose) {
      print('Mutation: "$repl" at ${match.start}');
    }
    final mutated = data.contents.substring(0,match.start) + repl + data.contents.substring(match.end);
    File(data.filename).writeAsStringSync(mutated);
    if (data.test.run(data.configuration)) {
      addMutationtoTestRunner(data.test,data.filename,match.start,match.end,data.contents,mutated);
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

/// Checks if a mutation is in an exclusion range
bool isInExclusionRange(List<Range> exclusions, String text, int position) {
  for(final ex in exclusions) {
    if(ex.isInRange(text, position)) {
      return true;
    }
  }
  return false;
}

