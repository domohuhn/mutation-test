// Copyright 2022, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/report_format.dart';
import 'package:mutation_test/src/version.dart';
import 'package:mutation_test/src/xunit_reporter.dart';
import 'package:test/test.dart';

import 'create_test_data.dart';

void main() {
  group('Xunit', () {
    test('Create Empty Xunit report', () {
      var result = createXUnitReport(ResultsReporter('test.xml', true), false);
      expect(result, '<?xml version="1.0"?>\n<testsuites/>');
    });

    test('Create xunit report', () {
      final reporter = createTestData();
      var result = createXUnitReport(reporter, false);
      // exclude report creation time and hostname
      expect(result.substring(0, _expectedXunit.length), _expectedXunit);
      final endOfDate = _expectedXunit.length + 19;
      final startOfHost = endOfDate + _expectedXunit2.length;
      expect(result.substring(endOfDate, startOfHost), _expectedXunit2);
      final endOfHost = result.indexOf('">', startOfHost);
      expect(result.substring(endOfHost), _expectedXunit3);
    });
  });

  group('Junit', () {
    test('Create Empty Junit report', () {
      var result = createXUnitReport(ResultsReporter('test.xml', true), true);
      expect(result, '<?xml version="1.0"?>\n<testsuites/>');
    });

    test('Create Junit report', () {
      final reporter = createTestData();
      var result = createXUnitReport(reporter, true);
      // exclude report creation time and hostname
      expect(result.substring(0, _expectedXunit.length), _expectedXunit);
      final endOfDate = _expectedXunit.length + 19;
      final startOfHost = endOfDate + _expectedXunit2.length;
      expect(result.substring(endOfDate, startOfHost), _expectedXunit2);
      final endOfHost = result.indexOf('">', startOfHost);
      expect(result.substring(endOfHost), _expectedJunit);
    });
  });
}

const String _expectedXunit = '''<?xml version="1.0"?>
<testsuites>
  <testsuite id="0" name="NamelessMutationRule-0" package="NamelessMutationRule-0" tests="3" failures="1" errors="1" time="0.0" timestamp="''';

const String _expectedXunit2 = '" hostname="';

const String _expectedXunit3 = '''">
    <testcase name="Line1_NamelessMutationRule-0_0" classname="path.dart" time="0.0"/>
    <testcase name="Line1_NamelessMutationRule-0_0" classname="path.dart" time="0.0">
      <failure type="undetected" message="All tests passed despite changing the code!">
File: path.dart
Line: 1
Original line: var x = 0;
Mutation: var x = a;
</failure>
    </testcase>
    <testcase name="Line1_testId_0" classname="path.dart" time="0.0">
      <error type="timeout" message="The test command timed out after 0.0 s">
File: path.dart
Line: 1
Original line: var x = 0;
Mutation: var x = c;
</error>
    </testcase>
  </testsuite>
</testsuites>''';

final String _expectedJunit = '''">
    <properties>
      <property name="test_runner" value="mutation_test"/>
      <property name="version" value="${mutationTestVersion()}"/>
    </properties>
    <testcase name="Line1_NamelessMutationRule-0_0" classname="path.dart" time="0.0"/>
    <testcase name="Line1_NamelessMutationRule-0_0" classname="path.dart" time="0.0">
      <failure type="undetected" message="All tests passed despite changing the code!">
File: path.dart
Line: 1
Original line: var x = 0;
Mutation: var x = a;
</failure>
    </testcase>
    <testcase name="Line1_testId_0" classname="path.dart" time="0.0">
      <error type="timeout" message="The test command timed out after 0.0 s">
File: path.dart
Line: 1
Original line: var x = 0;
Mutation: var x = c;
</error>
    </testcase>
    <system-out/>
    <system-err/>
  </testsuite>
</testsuites>''';
