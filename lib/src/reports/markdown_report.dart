// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/reports/report_data.dart';
import 'package:mutation_test/src/reports/string_helpers.dart';
import 'package:mutation_test/src/core/system_interactions.dart';
import 'package:mutation_test/src/version.dart';

/// Writes the results of the tests to a markdown file in directory [outPath].
/// The report will be named "mutation-test-report.md".
/// [reporter] holds the results of the test run that will be formatted to markdown
/// documents.
/// [system] is used to make the file system interactions testable.
void writeMarkdownReport(
    String outPath, ReportData data, SystemInteractions system) {
  var text = createMarkdownReport(data);
  final name = createReportFileName(defaultReportName(), outPath, 'md');
  system.createPathsAndWriteFile(name, text);
}

/// Creates the markdown report string
String createMarkdownReport(ReportData data) {
  var text = _createMarkdownHeader(data);
  data.testedFiles.forEach((key, value) {
    text += '## Undetected mutations in file : $key\n';
    for (final mut in value.undetectedMutations) {
      text += mut.toMarkdown();
    }
    text += '\n\n';
  });
  return text;
}

String _createMarkdownHeader(ReportData data) {
  final rv = StringBuffer('''# Mutation report
This is a mutation report generated by ${mutationTestVersion()}

${DateTime.now()}

| Key           | Value                     |
| ------------- | ------------------------- |
''');
  for (final element in data.inputFiles) {
    rv.write('| Rules         | $element           |\n');
  }
  rv.write('''
| Mutations     | ${data.totalMutations}                        |
| Elapsed     | ${data.elapsed}                        |
| Timeouts      | ${data.totalTimeouts}                        |
| Undetected    | ${data.undetectedMutations}                        |
| Undetected%   | ${asPercentString(data.undetectedMutations, data.totalMutations)}                        |
''');
  data.groupStatistics.forEach((k, v) {
    rv.write('| Detected by: $k            | $v         |\n');
  });
  rv.write('| Quality Rating | ${data.rating} |\n');
  rv.write('| Success | ${data.success} |\n\n\n');
  return rv.toString();
}
