// Copyright 2022, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/report_format.dart';
import 'package:mutation_test/src/version.dart';
import 'package:mutation_test/src/mutations.dart';
import 'package:mutation_test/src/commands.dart';
import 'package:test/test.dart';

import 'create_test_data.dart';
import 'mock_file_writer.dart';

void main() {
  group('With data', () {
    var reporter = ResultsReporter('test.xml', true, MockFileWriter());
    reporter.startFileTest('path.dart', 'var x = 0;\n\n// mooo\n');
    reporter.addTestReport(
      'path.dart',
      MutatedLine(1, 0, 5, 'var x = 0;', 'var x = -0;', Mutation(0, '0')),
      TestReport(TestResult.Detected),
      true,
    );
    reporter.addTestReport(
      'path.dart',
      MutatedLine(1, 0, 5, 'var x = 0;', 'var x = a;', Mutation(0, '0')),
      TestReport(TestResult.Undetected),
      true,
    );
    reporter.addTestReport(
      'path.dart',
      MutatedLine(1, 0, 5, 'var x = 0;', 'var x = c;', Mutation(0, '0')),
      TestReport(TestResult.Timeout),
      true,
    );
    test('Usage test for the reporter', () {
      expect(reporter.builtinRulesAdded, true);
      expect(reporter.foundMutations, 1);
      expect(reporter.success, false);
      expect(reporter.rating, 'N/A');
      reporter.sort();
      reporter.write();
    });

    test('detection numbers', () {
      expect(reporter.totalMutations, 3);
      expect(reporter.totalTimeouts, 1);
      expect(reporter.undetectedMutations, 2);
    });

    test('detection fractions', () {
      expect(reporter.detectedFraction, closeTo(100.0 / 3.0, 0.0001));
      expect(reporter.undetectedFraction, closeTo(200.0 / 3.0, 0.0001));
      expect(reporter.timeoutFraction, closeTo(100.0 / 3.0, 0.0001));
    });

    test('XML report', () {
      final xml = reporter.createXMLReport();
      // exclude execution time
      expect(xml.substring(0, 137), xmlReportString.substring(0, 137));
      expect(
          xml.substring(149),
          '</elapsed>\n'
          '<result rating="N/A" success="false"/>\n'
          '<rules>\n'
          '<ruleset document="test.xml"/></rules>\n'
          '<file name="path.dart">\n'
          '<mutation line="1">\n'
          '<original>var x = 0;</original>\n'
          '<modified>var x = a;</modified>\n'
          '</mutation>\n'
          '</file>\n'
          '</undetected-mutations>\n'
          '');
    });

    test('md report', () {
      final md = reporter.createMarkdownReport();
      final end1 = 86;
      final start2 = 113;
      final end2 = 307;
      final start3 = 321;
      // exclude execution time
      expect(md.substring(0, end1), mdString.substring(0, end1));
      expect(
          md.substring(start2, end2),
          '\n'
          '\n'
          '| Key           | Value                     |\n'
          '| ------------- | ------------------------- |\n'
          '| Rules         | test.xml           |\n'
          '| Mutations     | 3                        |\n'
          '| Elapsed     | ');
      expect(
          md.substring(start3),
          '                        |\n'
          '| Timeouts      | 1                        |\n'
          '| Undetected    | 2                        |\n'
          '| Undetected%   | 66.67%                        |\n'
          '| Quality Rating | N/A |\n'
          '| Success | false |\n'
          '\n'
          '\n'
          '## Undetected mutations in file : path.dart\n'
          'Line 1:<br>\n'
          '&nbsp;&nbsp;&nbsp;&nbsp;<span style="background-color: rgb(255, 200, 200);">- <span style="background-color: rgb(255, 50, 50);">var x</span> = 0;</span><br>\n'
          '&nbsp;&nbsp;&nbsp;&nbsp;<span style="background-color: rgb(200, 255, 200);">+ <span style="background-color: rgb(50, 255, 50);">var x</span> = a;</span><br>\n'
          '\n'
          '\n'
          '');
    });
  });

  group('no data', () {
    var reporter = ResultsReporter('test.xml', false, MockFileWriter());

    test('builtin rules', () {
      expect(reporter.builtinRulesAdded, false);
      expect(reporter.success, true);
      expect(reporter.rating, 'N/A');
      reporter.sort();
      reporter.write();
    });

    test('detection numbers', () {
      expect(reporter.foundMutations, 0);
      expect(reporter.totalMutations, 0);
      expect(reporter.totalTimeouts, 0);
      expect(reporter.undetectedMutations, 0);
    });

    test('detection fractions', () {
      expect(reporter.detectedFraction, closeTo(100.0, 0.0001));
      expect(reporter.undetectedFraction, closeTo(0.0, 0.0001));
      expect(reporter.timeoutFraction, closeTo(0.0, 0.0001));
    });

    test('XML report', () {
      final xml = reporter.createXMLReport();
      // exclude execution time
      expect(xml.substring(0, 137), xmlReportString.substring(0, 137));
      expect(xml.substring(149), xmlReportString.substring(149));
    });

    test('md report', () {
      final md = reporter.createMarkdownReport();
      final end1 = 86;
      final start2 = 113;
      final end2 = 307;
      final start3 = 321;
      // exclude execution time
      expect(md.substring(0, end1), mdString.substring(0, end1));
      expect(md.substring(start2, end2), mdString.substring(start2, end2));
      expect(md.substring(start3), mdString.substring(start3));
    });
  });

  group('Write Reports', () {
    test('md', () {
      final data = createTestData();
      expect(data.foundAll, false);
      data.writeMarkdownReport('fake_dir', 'in.xml');

      var mock = data.writer as MockFileWriter;

      expect(mock.argPaths.length, 1);
      expect(mock.argPaths[0], 'fake_dir/in-report.md');
      expect(mock.argTexts.length, 1);
      expect(mock.argTexts[0].length, 906);
    });

    test('junit', () {
      final data = createTestData();
      expect(data.foundAll, false);
      data.writeJUnitReport('fake_dir', 'in.xml');

      var mock = data.writer as MockFileWriter;

      expect(mock.argPaths.length, 1);
      expect(mock.argPaths[0], 'fake_dir/in-junit.xml');
      expect(mock.argTexts.length, 1);
      expect(mock.argTexts[0].length, 1054);
    });

    test('xunit', () {
      final data = createTestData();
      expect(data.foundAll, false);
      data.writeXUnitReport('fake_dir', 'in.xml');

      var mock = data.writer as MockFileWriter;

      expect(mock.argPaths.length, 1);
      expect(mock.argPaths[0], 'fake_dir/in-xunit.xml');
      expect(mock.argTexts.length, 1);
      expect(mock.argTexts[0].length, 854);
    });

    test('xml', () {
      final data = createTestData();
      expect(data.foundAll, false);
      data.writeXMLReport('fake_dir', 'in.xml');

      var mock = data.writer as MockFileWriter;

      expect(mock.argPaths.length, 1);
      expect(mock.argPaths[0], 'fake_dir/in-report.xml');
      expect(mock.argTexts.length, 1);
      expect(mock.argTexts[0].length, 398);
    });

    test('html', () {
      final data = createTestData();
      expect(data.foundAll, false);
      data.writeHTMLReport('fake_dir', 'in.xml');

      var mock = data.writer as MockFileWriter;

      expect(mock.argPaths.length, 2);
      expect(mock.argPaths[0], 'fake_dir/in-report.html');
      expect(mock.argPaths[1], 'fake_dir/path.dart.html');
      expect(mock.argTexts.length, 2);
      expect(mock.argTexts[0].length, 7981);
      expect(mock.argTexts[1].length, 8843);
    });
  });
}

final xmlReportString = '<?xml version="1.0" encoding="UTF-8"?>\n'
    '<undetected-mutations>\n'
    '<program-version>${mutationTestVersion()}</program-version>\n'
    '<elapsed>0:00:00.093959</elapsed>\n'
    '<result rating="N/A" success="true"/>\n'
    '<rules>\n'
    '<ruleset document="test.xml"/></rules>\n'
    '</undetected-mutations>\n'
    '';

final mdString = '# Mutation report\n'
    'This is a mutation report generated by ${mutationTestVersion()}\n'
    '\n'
    '2022-10-30 16:28:42.481740\n'
    '\n'
    '| Key           | Value                     |\n'
    '| ------------- | ------------------------- |\n'
    '| Rules         | test.xml           |\n'
    '| Mutations     | 0                        |\n'
    '| Elapsed     | 0:00:00.100068                        |\n'
    '| Timeouts      | 0                        |\n'
    '| Undetected    | 0                        |\n'
    '| Undetected%   | 0.00%                        |\n'
    '| Quality Rating | N/A |\n'
    '| Success | true |\n'
    '\n'
    '\n'
    '';
