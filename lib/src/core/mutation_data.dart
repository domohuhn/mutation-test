// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/configuration/configuration.dart';
import 'package:mutation_test/src/core/test_runner.dart';
import 'package:mutation_test/src/reports/report_data.dart';

import 'app_progress_bar.dart';

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
  final ReportData results;

  /// A reference to the progress bar.
  final AppProgressBar bar;

  /// Constructor for the mutation data.
  /// The object is given to the test runner to run tests on the given [filename].
  MutationData(this.configuration, this.test, this.filename, this.contents,
      this.results, this.bar);
}
