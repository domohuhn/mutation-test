
import 'package:mutation_test/errors.dart';

import 'configuration.dart';
import 'dart:io';
import 'test-runner.dart';


bool runMutationTest(String inputFile, String outputPath, bool verbose, bool dry) {
  final configuration = Configuration.fromFile(inputFile, verbose, dry);
  final tests = TestRunner();

  checkTests(configuration,tests);

  for (final current in configuration.files) {
    final source = File(current).readAsStringSync();
    var count = countMutations(configuration,source);
    print('$current : $count mutations');
    if (dry) {
      continue;
    }
    doMutationTests(configuration,tests,inputFile,source);

    // restore orignal
    File(current).writeAsStringSync(source);
  }
  tests.printResults();
  return tests.foundAll;
}

void checkTests(Configuration cfg, TestRunner test) {
  if (cfg.verbose) {
    print('Checking if the test commands work with unmodified sources ...');
  }
  test.prepare(cfg);
  if (cfg.dry) {
    return;
  }
  if (!test.run(cfg)) {
    throw InputError('Running the test commands failed with unmodified code! Aborting.');
  }
}

int countMutations(Configuration config, String text) {
  var rv = 0;
  for (final mutation in config.mutations) {
    var count = mutation.replacements.length;
    final matches = mutation.pattern.allMatches(text);
    rv += count * matches.length;
  }
  return rv;
}


void doMutationTests(Configuration config, TestRunner test, String filename, String original) {
  for (final mutation in config.mutations) {
    final matches = mutation.pattern.allMatches(original);
    for ( final m in matches ) {
      doReplacements(config,test,filename,original,m,mutation.replacements);
    }
  }
}

void doReplacements(Configuration config, TestRunner test, String filename, String original, Match match, List<String> replacements) {
  for (final repl in replacements) {
    final mutated = original.substring(0,match.start) + repl + original.substring(match.end);
    File(filename).writeAsStringSync(mutated);
    test.run(config);
  }
}


