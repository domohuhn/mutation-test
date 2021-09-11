/// Copyright 2021, domohuhn. 
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license
import 'dart:math';

/// Finds the line number at [position] in a multiline [text].
/// Indexing starts at 1.
int findLineFromPosition(String text, int position) {
  var rv = 0;
  for(var i=0; i<min(text.length,position); i++) {
    if(text[i]=='\n') {
      rv += 1;
    }
  }
  return rv+1;
}

/// Finds the start position of the line at [position] in a multiline [text].
int findBeginOfLineFromPosition(String text, int position) {
  var rv = findFirstTokenBeforePosition(text,position,'\n');
  return rv>=0 ? rv+1 : 0;
}

/// Finds the start position of the first [token] before [position] in [text].
int findFirstTokenBeforePosition(String text, int position, String token) {
  return text.lastIndexOf(token,position);
}

/// Finds the start position of the first [token] after [position] in [text].
int findFirstTokenAfterPosition(String text, int position, String token) {
  return text.indexOf(token,position);
}

/// Finds the end position of the line at [position] in a multiline [text].
int findEndOfLineFromPosition(String text, int position) {
  var rv = findFirstTokenAfterPosition(text,position,'\n');
  return rv>=0 ? rv : text.length;
}

/// Converts the inputs to a percentage string "[fraction]/[total]%"
String asPercentString(int fraction, int total) {
  var percent = 0.0;
  if (total>0) {
    percent = 100.0*fraction/total;
  }
  return '${percent.toStringAsFixed(2)}%';
}

/// Creates a report file name from the [input] file in directory [outpath]
/// with the given file [extension].
String createReportFileName(String input, String outpath, String extension) {
  var start = 0;
  if (input.contains('/')) {
    start = input.lastIndexOf('/');
  } else if (input.contains('\\')) {
    start = input.lastIndexOf('\\');
  }
  var end = input.lastIndexOf('.');
  var name = '$outpath/${input.substring(start,end)}-report.$extension';
  return name;
}

/// Escapes characters for xml
String convertToXML(String input) {
  return input.replaceAll('&', '&amp;').replaceAll('"', '&quot;').replaceAll("'", '&apos;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}

/// Escapes characters for markdown
String convertToMarkdown(String input) {
  return input.replaceAll('\*', '\\\*');
}

