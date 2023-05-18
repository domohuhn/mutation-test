import 'package:mutation_test/src/reports/command_line_report.dart';
import 'package:mutation_test/src/reports/html_report.dart';
import 'package:mutation_test/src/reports/markdown_report.dart';
import 'package:mutation_test/src/reports/report_data.dart';
import 'package:mutation_test/src/reports/report_formats.dart';
import 'package:mutation_test/src/reports/xml_report.dart';
import 'package:mutation_test/src/reports/xunit_report.dart';

/// Creates the test report in directory [outputPath] from [inputFile]
/// in the specified [format] using the [results].
void createReport(ReportData results, String outputPath, String inputFile,
    ReportFormat format) {
  writeCommandLineReport(results, results.system);
  results.sort();
  switch (format) {
    case ReportFormat.NONE:
      return;
    case ReportFormat.XML:
      writeXMLReport(outputPath, inputFile, results, results.system);
      break;
    case ReportFormat.MARKDOWN:
      writeMarkdownReport(outputPath, inputFile, results, results.system);
      break;
    case ReportFormat.HTML:
      writeHTMLReport(outputPath, inputFile, results, results.system);
      break;
    case ReportFormat.XUNIT:
      writeXUnitReport(outputPath, inputFile, results, results.system);
      break;
    case ReportFormat.JUNIT:
      writeJUnitReport(outputPath, inputFile, results, results.system);
      break;
    case ReportFormat.ALL:
      writeXMLReport(outputPath, inputFile, results, results.system);
      writeMarkdownReport(outputPath, inputFile, results, results.system);
      writeHTMLReport(outputPath, inputFile, results, results.system);
      writeXUnitReport(outputPath, inputFile, results, results.system);
      writeJUnitReport(outputPath, inputFile, results, results.system);
      break;
  }
  results.system.writeLine('Output has been written to $outputPath');
}
