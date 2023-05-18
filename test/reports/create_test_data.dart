// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/reports/report_data.dart';
import 'package:mutation_test/src/core/mutations.dart';
import 'package:mutation_test/src/core/commands.dart';
import '../mock_system_interactions.dart';

ReportData createTestData() {
  var reporter = ReportData('test.xml', true, MockSystemInteractions());
  reporter.startFileTest('path.dart', 'var x = 0;\n\n// mooo\n');
  reporter.addTestReport(
    'path.dart',
    MutatedLine(1, 0, 5, 'var x = 0;', 'var x = -0;', Mutation(0, '[0-9]+')),
    TestReport(TestResult.Detected),
  );
  reporter.addTestReport(
    'path.dart',
    MutatedLine(1, 0, 5, 'var x = 0;', 'var x = a;', Mutation(0, '[0-9]+')),
    TestReport(TestResult.Undetected),
  );
  reporter.addTestReport(
    'path.dart',
    MutatedLine(1, 0, 5, 'var x = 0;', 'var x = c;',
        Mutation(0, '[0-9]+', id: 'testId')),
    TestReport(TestResult.Timeout),
  );
  return reporter;
}
