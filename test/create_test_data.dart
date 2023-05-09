// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/report_format.dart';
import 'package:mutation_test/src/mutations.dart';
import 'package:mutation_test/src/commands.dart';

ResultsReporter createTestData() {
  var reporter = ResultsReporter('test.xml', true);
  reporter.startFileTest('path.dart', 'var x = 0;\n\n// mooo\n');
  reporter.addTestReport(
    'path.dart',
    MutatedLine(1, 0, 5, 'var x = 0;', 'var x = -0;', Mutation(0, '[0-9]+')),
    TestReport(TestResult.Detected),
    false,
  );
  reporter.addTestReport(
    'path.dart',
    MutatedLine(1, 0, 5, 'var x = 0;', 'var x = a;', Mutation(0, '[0-9]+')),
    TestReport(TestResult.Undetected),
    false,
  );
  reporter.addTestReport(
    'path.dart',
    MutatedLine(1, 0, 5, 'var x = 0;', 'var x = c;',
        Mutation(0, '[0-9]+', id: 'testId')),
    TestReport(TestResult.Timeout),
    false,
  );
  return reporter;
}
