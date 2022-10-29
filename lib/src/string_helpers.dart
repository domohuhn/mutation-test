/// Copyright 2021, domohuhn.
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license
import 'dart:math';

/// Finds the line number at [position] in a multiline [text].
/// Indexing starts at 1.
int findLineFromPosition(String text, int position) {
  var rv = 0;
  for (var i = 0; i < min(text.length, position); i++) {
    if (text[i] == '\n') {
      rv += 1;
    }
  }
  return rv + 1;
}

/// Finds the start position of the line at [position] in a multiline [text].
int findBeginOfLineFromPosition(String text, int position) {
  var rv = findFirstTokenBeforePosition(text, position, '\n');
  return rv >= 0 ? rv + 1 : 0;
}

/// Finds the start position of the first [token] before [position] in [text].
int findFirstTokenBeforePosition(String text, int position, String token) {
  return text.lastIndexOf(token, position);
}

/// Finds the start position of the first [token] after [position] in [text].
int findFirstTokenAfterPosition(String text, int position, String token) {
  return text.indexOf(token, position);
}

/// Finds the end position of the line at [position] in a multiline [text].
int findEndOfLineFromPosition(String text, int position) {
  var rv = findFirstTokenAfterPosition(text, position, '\n');
  return rv >= 0 ? rv : text.length;
}

/// Converts the inputs to a percentage string "[fraction]/[total]%"
String asPercentString(int fraction, int total) {
  var percent = 0.0;
  if (total > 0) {
    percent = 100.0 * fraction / total;
  }
  return '${percent.toStringAsFixed(2)}%';
}

/// Creates a report file name from the [input] file in directory [outpath]
/// with the given file [ext].
String createReportFileName(String input, String outpath, String ext,
    {bool appendReport = true, bool removePathsFromInput = true, bool removeInputExt = true}) {
  var fixed = removePathsFromInput ? basename(input) : input;
  var end = -1;
  if (removeInputExt) {
    end = fixed.lastIndexOf('.');
  }
  if (end == -1) {
    end = fixed.length;
  }
  var name = '$outpath/${fixed.substring(0, end)}';
  if (appendReport) {
    name += '-report';
  }
  name += '.$ext';
  return name;
}

/// Removes the directories from a file name and returns just the basename.
String basename(String path) {
  var start = 0;
  if (path.contains('/')) {
    start = path.lastIndexOf('/') + 1;
  }
  if (path.contains('\\')) {
    var start2 = path.lastIndexOf('\\') + 1;
    if (start2 > start) {
      start = start2;
    }
  }
  return path.substring(start);
}

/// Gets the directory from the given path [path].
String getDirectory(String path) {
  var end = -1;
  if (path.contains('/')) {
    end = path.lastIndexOf('/') + 1;
  }
  if (path.contains('\\')) {
    var end2 = path.lastIndexOf('\\') + 1;
    if (end2 > end) {
      end = end2;
    }
  }
  if (end == -1) {
    return '';
  }
  return path.substring(0, end);
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

/// Formats duration [dur] in the range 0 - 100h.
/// If the value is outside of the range, 100+h is displayed.
String formatDuration(Duration dur) {
  var hrs = dur.inHours;
  var mins = dur.inMinutes.remainder(60);
  var secs = dur.inSeconds.remainder(60);
  var rv = '';
  if (hrs > 100) {
    return '100+h';
  } else if (hrs > 0) {
    rv += '${hrs}h ';
  }
  if (mins > 0 || hrs > 0) {
    rv += '${mins}m ';
  }
  rv += '${secs}s';
  return rv;
}

/// Creates the prefix for a link back to the top.
String createParentLinkPrefix(String path) {
  if (path.contains('/') || path.contains('\\')) {
    var rv = '';
    var previous = false;
    for (int i = 0; i < path.length; ++i) {
      if (path[i] == '/' || path[i] == '\\') {
        if (!previous) {
          rv += '../';
        }
        previous = true;
      } else {
        previous = false;
      }
    }
    return rv;
  }
  return './';
}

/// Escapes &, < and > in [input] with its Html tokens.
String escapeCharsForHtml(String input) {
  return input.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}
