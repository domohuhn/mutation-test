// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/reports/report_data.dart';
import 'package:mutation_test/src/reports/string_helpers.dart';
import 'package:mutation_test/src/core/system_interactions.dart';
import 'package:mutation_test/src/version.dart';

/// Writes the results of the tests to a xml file in directory [outPath].
/// The report will be named "mutation-test-report.xml".
/// [reporter] holds the results of the test run that will be formatted to xml
/// documents.
/// [system] is used to make the file system interactions testable.
void writeXMLReport(
    String outPath, ReportData data, SystemInteractions system) {
  final text = createXMLReport(data);
  final name = createReportFileName(defaultReportName(), outPath, 'xml');
  system.createPathsAndWriteFile(name, text);
}

/// Creates the XML report string
String createXMLReport(ReportData data) {
  final text = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8"?>\n<undetected-mutations>\n');
  text.write('<program-version>${mutationTestVersion()}</program-version>\n');
  text.write('<elapsed>${data.elapsed}</elapsed>\n');
  text.write('<result rating="${data.rating}" success="${data.success}"/>\n');
  text.write('<rules>\n');
  for (final element in data.inputFiles) {
    text.write('<ruleset document="$element"/>');
  }
  text.write('</rules>\n');
  data.testedFiles.forEach((key, value) {
    text.write('<file name="$key">\n');
    for (final mut in value.undetectedMutations) {
      text.write('<mutation line="${mut.line}">\n');
      text.write('<original>${convertToXML(mut.original)}</original>\n');
      text.write('<modified>${convertToXML(mut.mutated)}</modified>\n');
      text.write('</mutation>\n');
    }
    text.write('</file>\n');
  });
  text.write('</undetected-mutations>\n');
  return text.toString();
}
