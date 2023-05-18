// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/reports/report_data.dart';
import 'package:mutation_test/src/reports/string_helpers.dart';
import 'package:mutation_test/src/core/system_interactions.dart';

/// Prints the statistics to the command line at the end of the execution.
/// [reporter] holds the results of the test run that will be formatted to xml
/// documents.
/// [system] is used to make the file system interactions testable.
void writeCommandLineReport(ReportData data, SystemInteractions system) {
  system.writeLine('  --- Results ---');
  system.writeLine('Test group statistics:');
  data.groupStatistics
      .forEach((k, v) => system.writeLine('  Group : $k, Found mutations: $v'));
  system.writeLine(
      '\nTotal tests: ${data.totalMutations}\nUndetected Mutations: ${data.undetectedMutations} (${asPercentString(data.undetectedMutations, data.totalMutations)})');
  system.writeLine('Timeouts: ${data.totalTimeouts}');
  system.writeLine('Elapsed: ${data.elapsed}');
  system.writeLine('Success: ${data.success}, Quality rating: ${data.rating}');
}
