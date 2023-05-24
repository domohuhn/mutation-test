// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/core/commands.dart';
import 'package:mutation_test/src/core/mutated_line.dart';
import 'package:mutation_test/src/core/mutation.dart';
import 'package:mutation_test/src/reports/file_mutation_results.dart';
import 'package:mutation_test/src/reports/report_data.dart';
import 'package:mutation_test/src/reports/string_helpers.dart';
import 'package:mutation_test/src/core/system_interactions.dart';
import 'package:mutation_test/src/version.dart';
import 'package:xml/xml.dart' as xml;
import 'dart:io' show Platform;

/// Writes the xunit report in directory [outPath].
/// The report will have the basename of [input], but ending with ".xunit.xml".
/// [reporter] holds the results of the test run that will be formatted to xunit
/// documents.
/// [system] is used to make the file system interactions testable.
void writeXUnitReport(
    String outPath, String input, ReportData data, SystemInteractions system) {
  final contents = createXUnitReport(data, false);
  final fileName = createReportFileName(
      inputFileOrDefaultName(input), outPath, 'xunit.xml',
      appendReport: false);
  system.createPathsAndWriteFile(fileName, contents);
}

/// Writes the junit report in directory [outPath].
/// The report will have the basename of [input], but ending with ".junit.xml".
/// [reporter] holds the results of the test run that will be formatted to junit
/// documents.
/// [system] is used to make the file system interactions testable.
void writeJUnitReport(
    String outPath, String input, ReportData data, SystemInteractions system) {
  final contents = createXUnitReport(data, true);
  final fileName = createReportFileName(
      inputFileOrDefaultName(input), outPath, 'junit.xml',
      appendReport: false);
  system.createPathsAndWriteFile(fileName, contents);
}

/// Creates an xunit report xml using the results stored in the [reporter].
/// There is no "official" schema to create a conforming xml document.
/// However, there are a unofficial ones on github, e.g.
/// http://windyroad.com.au/dl/Open%20Source/JUnit.xsd
/// or
/// https://gist.github.com/jclosure/45d7005d120d90ba6430130356e4cd61
///
/// Both of the these schemas should be compatible with external tools such as
/// Polarion.
///
/// If [conformToJUnit] is set to true, the produced output will match
/// the first schema, otherwise the second one.
///
/// Layout:
/// Each mutation rule is converted to a test suite.
/// Each mutated line is a test case.
///
String createXUnitReport(ReportData reporter, bool conformToJUnit) {
  final builder = xml.XmlBuilder();
  builder.processing('xml', 'version="1.0"');
  builder.element('testsuites', nest: () {
    for (final rule in reporter.rules) {
      builder.element('testsuite', nest: () {
        final filtered = reporter.filterResultsByRuleIndex(rule.index);
        _addAttributesToTestSuite(filtered, rule, builder, conformToJUnit);
        filtered.forEach((file, results) {
          _addTestCases(
              builder, file, results.detectedMutations, TestResult.Detected);
          _addTestCases(builder, file, results.undetectedMutations,
              TestResult.Undetected);
          _addTestCases(
              builder, file, results.timeoutMutations, TestResult.Timeout);
        });
        if (conformToJUnit) {
          builder.element('system-out');
          builder.element('system-err');
        }
      });
    }
  });
  final document = builder.buildDocument();
  return document.toXmlString(
      pretty: true,
      preserveWhitespace: (node) =>
          node.parentElement?.name.local == 'testcase');
}

void _addAttributesToTestSuite(Map<String, FileMutationResults> filtered,
    Mutation rule, xml.XmlBuilder builder, bool conformToJUnit) {
  final tmpNow = DateTime.now().toIso8601String();
  final now = tmpNow.substring(0, tmpNow.lastIndexOf('.'));
  int tests = 0;
  int failures = 0;
  int timeouts = 0;
  var total = Duration();
  filtered.forEach((file, results) {
    tests += results.mutationCount;
    failures += results.undetectedCount;
    timeouts += results.timeoutCount;
    total += results.elapsed;
  });
  builder.attribute('id', rule.index);
  builder.attribute('name', rule.xUnitId);
  builder.attribute('package', rule.xUnitId);
  builder.attribute('tests', tests);
  builder.attribute('failures', failures);
  builder.attribute('errors', timeouts);
  builder.attribute('time', total.inMilliseconds * 0.001);
  builder.attribute('timestamp', now);
  String hostname = Platform.localHostname;
  builder.attribute('hostname', hostname);

  if (conformToJUnit) {
    builder.element('properties', nest: () {
      builder.element('property', nest: () {
        builder.attribute('name', 'test_runner');
        builder.attribute('value', 'mutation_test');
      });
      builder.element('property', nest: () {
        builder.attribute('name', 'version');
        builder.attribute('value', mutationTestVersion());
      });
    });
  }
}

void _addTestCases(xml.XmlBuilder builder, String file, List<MutatedLine> lines,
    TestResult type) {
  for (final line in lines) {
    builder.element('testcase', nest: () {
      builder.attribute('name',
          'Line${line.line}_${line.mutation.xUnitId}_${line.replacementIndex}');
      builder.attribute('classname', file);
      final elapsedSeconds = line.elapsed.inMilliseconds * 0.001;
      builder.attribute('time', elapsedSeconds);
      if (type == TestResult.Timeout) {
        builder.element('error', nest: () {
          builder.attribute('type', 'timeout');
          builder.attribute(
              'message', 'The test command timed out after $elapsedSeconds s');
          builder.text(
              '\nFile: $file\nLine: ${line.line}\nOriginal line: ${line.original}\nMutation: ${line.mutated}\n');
        });
      }
      if (type == TestResult.Undetected) {
        builder.element('failure', nest: () {
          builder.attribute('type', 'undetected');
          builder.attribute(
              'message', 'All tests passed despite changing the code!');
          builder.text(
              '\nFile: $file\nLine: ${line.line}\nOriginal line: ${line.original}\nMutation: ${line.mutated}\n');
        });
      }
    });
  }
}
