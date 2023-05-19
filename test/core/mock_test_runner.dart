// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/configuration/configuration.dart';
import 'package:mutation_test/src/core/core.dart';

class MockTestRunner extends TestRunner {
  int killCallCount = 0;
  bool rvKill = false;

  @override
  bool kill() {
    killCallCount++;
    return rvKill;
  }

  int runCallCount = 0;
  TestReport rvReport = TestReport(TestResult.Detected);

  @override
  Future<TestReport> run(Configuration config, SystemInteractions system,
      {bool outputOnFailure = false}) async {
    runCallCount++;
    return rvReport;
  }

  void clear() {
    killCallCount = 0;
    runCallCount = 0;
  }
}
