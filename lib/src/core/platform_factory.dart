// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/core/system_interactions.dart';
import 'package:mutation_test/src/core/test_runner.dart';

/// A Factory class injected into the mutation test interface.
class PlatformFactory {
  SystemInteractions createSystemInteractions(
      {bool verbose = false, bool quiet = false}) {
    return SystemInteractions(verbose, quiet);
  }

  TestRunner createTestRunner() {
    return TestRunner();
  }
}
