// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/core/core.dart';

import 'mock_system_interactions.dart';
import 'mock_test_runner.dart';

class MockPlatformFactory extends PlatformFactory {
  MockSystemInteractions? system;
  MockTestRunner? runner;

  @override
  SystemInteractions createSystemInteractions(
      {bool verbose = false, bool quiet = false}) {
    system ??= MockSystemInteractions();
    return system!;
  }

  @override
  TestRunner createTestRunner() {
    runner ??= MockTestRunner();
    return runner!;
  }
}
