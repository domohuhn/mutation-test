// Copyright 2022, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/reports/create_report.dart';
import 'package:mutation_test/src/reports/report_formats.dart';
import 'package:test/test.dart';

import 'create_test_data.dart';
import '../core/mock_system_interactions.dart';

void main() {
  group('Write Reports', () {
    test('md', () {
      final data = createTestData();
      createReport(data, 'fake_dir', 'in.xml', ReportFormat.MARKDOWN);

      var mock = data.system as MockSystemInteractions;

      expect(mock.argPaths.length, 1);
      expect(mock.argPaths[0], 'fake_dir/in-report.md');
      expect(mock.argTexts.length, 1);
      expect(mock.argTexts[0].length, 906);
    });

    test('junit', () {
      final data = createTestData();
      createReport(data, 'fake_dir', 'in.xml', ReportFormat.JUNIT);

      var mock = data.system as MockSystemInteractions;

      expect(mock.argPaths.length, 1);
      expect(mock.argPaths[0], 'fake_dir/in-junit.xml');
      expect(mock.argTexts.length, 1);
      expect(mock.argTexts[0].length >= 1039, true);
    });

    test('xunit', () {
      final data = createTestData();
      createReport(data, 'fake_dir', 'in.xml', ReportFormat.XUNIT);

      var mock = data.system as MockSystemInteractions;

      expect(mock.argPaths.length, 1);
      expect(mock.argPaths[0], 'fake_dir/in-xunit.xml');
      expect(mock.argTexts.length, 1);
      expect(mock.argTexts[0].length >= 839, true);
    });

    test('xml', () {
      final data = createTestData();
      createReport(data, 'fake_dir', 'in.xml', ReportFormat.XML);

      var mock = data.system as MockSystemInteractions;

      expect(mock.argPaths.length, 1);
      expect(mock.argPaths[0], 'fake_dir/in-report.xml');
      expect(mock.argTexts.length, 1);
      expect(mock.argTexts[0].length, 398);
    });

    test('html', () {
      final data = createTestData();
      createReport(data, 'fake_dir', 'in.xml', ReportFormat.HTML);

      var mock = data.system as MockSystemInteractions;

      expect(mock.argPaths.length, 2);
      expect(mock.argPaths[0], 'fake_dir/in-report.html');
      expect(mock.argPaths[1], 'fake_dir/path.dart.html');
      expect(mock.argTexts.length, 2);
      expect(mock.argTexts[0].length, 7981);
      expect(mock.argTexts[1].length, 8843);
    });

    test('none', () {
      final data = createTestData();
      createReport(data, 'fake_dir', 'in.xml', ReportFormat.NONE);

      var mock = data.system as MockSystemInteractions;

      expect(mock.argPaths.length, 0);
    });

    test('all', () {
      final data = createTestData();
      createReport(data, 'fake_dir', 'in.xml', ReportFormat.ALL);
      var mock = data.system as MockSystemInteractions;

      expect(mock.argPaths.length, 6);
      expect(mock.argPaths[0], 'fake_dir/in-report.xml');
      expect(mock.argPaths[1], 'fake_dir/in-report.md');
      expect(mock.argPaths[2], 'fake_dir/in-report.html');
      expect(mock.argPaths[3], 'fake_dir/path.dart.html');
      expect(mock.argPaths[4], 'fake_dir/in-xunit.xml');
      expect(mock.argPaths[5], 'fake_dir/in-junit.xml');
    });
  });
}
