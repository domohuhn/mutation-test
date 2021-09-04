

import 'package:mutation_test/test-runner.dart';

/// Format for the report file
enum ReportFormat {
  XML,
  MARKDOWN,
  HTML,
  ALL,
  NONE
}


/// Creates the [test] report in directory [outputPath] from [inputFile]
/// int the specified [format].
void createReport(TestRunner test, String outputPath, String inputFile, ReportFormat format) {
  test.printResults();
  test.sort();
  switch(format) {
    case ReportFormat.XML:
      test.writeXMLReport(outputPath, inputFile);
      break;
    case ReportFormat.MARKDOWN:
      test.writeMarkdownReport(outputPath, inputFile);
      break;
    case ReportFormat.HTML:
      test.writeHTMLReport(outputPath, inputFile);
      break;
    case ReportFormat.ALL:
      test.writeXMLReport(outputPath, inputFile);
      test.writeMarkdownReport(outputPath, inputFile);
      test.writeHTMLReport(outputPath, inputFile);
      break;
    case ReportFormat.NONE:
      break;
  }
}

