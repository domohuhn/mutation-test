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
String createReportFileName(String input, String outpath, String extension, {bool appendReport = true}) {
  var start = 0;
  if (input.contains('/')) {
    start = input.lastIndexOf('/')+1;
  } else if (input.contains('\\')) {
    start = input.lastIndexOf('\\')+1;
  }
  var end = input.lastIndexOf('.');
  if (end == -1) {
    end = input.length;
  }
  var name = '$outpath/${input.substring(start,end)}';
  if(appendReport) {
    name += '-report';
  }
  name += '.$extension';
  return name;
}

/// Gets the directory from the given path [path].
String getDirectory(String path) {
  var end = 0;
  if (path.contains('/')) {
    end = path.lastIndexOf('/')+1;
  } else if (path.contains('\\')) {
    end = path.lastIndexOf('\\')+1;
  }
  if (end == -1) {
    return '';
  }
  return path.substring(0,end);
}

/// Escapes characters for xml
String convertToXML(String input) {
  return input.replaceAll('&', '&amp;').replaceAll('"', '&quot;').replaceAll("'", '&apos;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}

/// Escapes characters for markdown
String convertToMarkdown(String input) {
  // ignore: unnecessary_string_escapes
  return input.replaceAll('\*', '\\\*');
}

String formatDuration(Duration dur) {
  var hrs = dur.inHours;
  var mins = dur.inMinutes.remainder(60);
  var secs = dur.inSeconds.remainder(60);
  var rv = '';
  if (hrs>100) {
    return '100+h';
  } else if (hrs>0) {
    rv += '${hrs}h ';
  }
  if(mins>0||hrs>0) {
    rv += '${mins}m ';
  }
  rv += '${secs}s';
  return rv;
}
