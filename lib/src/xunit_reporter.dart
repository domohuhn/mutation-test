// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/commands.dart';
import 'package:mutation_test/src/mutations.dart';
import 'package:mutation_test/src/report_format.dart';
import 'package:mutation_test/src/version.dart';
import 'package:xml/xml.dart' as xml;
import 'dart:io' show Platform;

/// Creates an xunit report xml using the results stored in the [reporter].
/// There is no "official" schema to create a conforming xml document.
/// However, there are a unofficial ones on github, e.g.
/// http://windyroad.com.au/dl/Open%20Source/JUnit.xsd
/// or
/// https://gist.github.com/jclosure/45d7005d120d90ba6430130356e4cd61
///
/// Both of the these schemas should be comatible with external tools such as
/// Polarion.
///
/// If [conformToJUnit] is set to true, the produced output will match
/// the first schema, otherwise the second one.
///
/// Layout:
/// Each mutation rule is converted to a test suite.
/// Each mutated line is a test case.
///
String createXUnitReport(ResultsReporter reporter, bool conformToJUnit) {
  final builder = xml.XmlBuilder();
  builder.processing('xml', 'version="1.0"');
  builder.element('testsuites', nest: () {
    for (final rule in reporter.rules) {
      builder.element('testsuite', nest: () {
        final filtered = reporter.filterResultsByRuleIndex(rule.index);
        _addAttributesToTestsuite(filtered, rule, builder, conformToJUnit);
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

void _addAttributesToTestsuite(Map<String, FileMutationResults> filtered,
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
