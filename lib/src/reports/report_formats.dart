// Copyright 2021, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

/// Format for the report file
enum ReportFormat {
  /// Creates the report as XML document.
  XML,

  /// Creates the report as markdown document.
  MARKDOWN,

  /// Creates the report as html documents.
  HTML,

  /// Creates the report as junit xml document.
  JUNIT,

  /// Creates the report as xunit xml document.
  XUNIT,

  /// Creates all reports at once.
  ALL,

  /// Creates no report.
  NONE
}
