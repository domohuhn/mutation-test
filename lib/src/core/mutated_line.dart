// Copyright 2021, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/core/mutation.dart';
import 'package:mutation_test/src/reports/string_helpers.dart';

/// A mutation data structure with Information about a mutated line.
class MutatedLine {
  /// line number in the source
  final int line;

  /// start position of the mutation in the original line
  late final int start;

  /// end position of the mutated code in the original line
  late final int end;

  /// original line of code
  final String original;

  /// mutated line of code
  final String mutated;

  final Mutation mutation;

  /// The time needed to perform and verify this mutation
  Duration elapsed = Duration();

  /// the order in the list of replacements for this rule
  int replacementIndex = 0;

  MutatedLine(this.line, int first, int last, this.original, this.mutated,
      this.mutation) {
    /// make wrong states impossible to represent
    start = first >= 0 ? first : 0;
    end = last <= original.length ? last : original.length;
  }

  /// Pretty formatting
  String toMarkdown() {
    final rv = StringBuffer('Line $line:<br>\n');
    rv.write(_formatRemoved(true));
    rv.write(_formatAdded(true));
    // ignore: unnecessary_string_escapes
    return rv.toString().replaceAll('*', '\*');
  }

  /// Pretty formatting
  String toHTML() {
    final rv = StringBuffer('Line $line:<br>\n');
    rv.write(_formatRemoved(false));
    rv.write(_formatAdded(false));
    return rv.toString();
  }

  String _formatRemoved(bool escape) {
    final rv = StringBuffer(
        '&nbsp;&nbsp;&nbsp;&nbsp;<span style="background-color: rgb(255, 200, 200);">');
    rv.write('- ${_escapeChars(original.substring(0, start), escape)}');
    rv.write('<span style="background-color: rgb(255, 50, 50);">');
    rv.write(_escapeChars(original.substring(start, end), escape));
    rv.write('</span>');
    rv.write(_escapeChars(original.substring(end), escape));
    rv.write('</span><br>\n');
    return rv.toString();
  }

  String _formatAdded(bool escape) {
    final begin = start < mutated.length ? start : 0;
    final rv = StringBuffer(
        '&nbsp;&nbsp;&nbsp;&nbsp;<span style="background-color: rgb(200, 255, 200);">');
    rv.write('+ ${_escapeChars(mutated.substring(0, begin), escape)}');
    rv.write('<span style="background-color: rgb(50, 255, 50);">');
    var mutationEnd = end + mutated.length - original.length;
    mutationEnd = mutationEnd >= begin && mutationEnd <= mutated.length
        ? mutationEnd
        : begin;
    rv.write(_escapeChars(mutated.substring(begin, mutationEnd), escape));
    rv.write('</span>');
    rv.write(_escapeChars(mutated.substring(mutationEnd), escape));
    rv.write('</span><br>\n');
    return rv.toString();
  }

  /// Formats the modified code for the Html reporting.
  String formatMutatedCodeToHTML() {
    final begin = start < mutated.length ? start : 0;
    final rv = StringBuffer('<span class="addedLine">');
    rv.write('+ ${escapeCharsForHtml(mutated.substring(0, begin))}');
    rv.write('<span class="changedTokens">');
    var mutationEnd = end + mutated.length - original.length;
    mutationEnd = mutationEnd >= begin && mutationEnd <= mutated.length
        ? mutationEnd
        : begin;
    rv.write(escapeCharsForHtml(mutated.substring(begin, mutationEnd)));
    rv.write('</span>');
    rv.write(escapeCharsForHtml(mutated.substring(mutationEnd)));
    rv.write('</span>');
    return rv.toString();
  }

  String _escapeChars(String text, bool doIt) {
    if (doIt) {
      return convertToMarkdown(text);
    }
    return text;
  }

  @override
  String toString() {
    return '$line: "${mutated.trim()}"';
  }
}

/// Creates a new mutated line.
/// Finds the line in the source file and extracts
/// the original and mutated code.
MutatedLine createMutatedLine(
  int absoluteStart,
  int absoluteEnd,
  String original,
  String mutated,
  Mutation mutation,
) {
  if (absoluteStart < 0) {
    absoluteStart = 0;
  }
  if (absoluteStart > original.length) {
    absoluteStart = original.length;
  }
  if (absoluteStart > absoluteEnd) {
    absoluteEnd = absoluteStart;
  }
  if (absoluteEnd > original.length) {
    absoluteEnd = original.length;
  }
  var line = findLineFromPosition(original, absoluteStart);
  final lineStart = findBeginOfLineFromPosition(original, absoluteStart);
  final lineEnd = findEndOfLineFromPosition(original, absoluteEnd);
  // this may be false if the mutation matches the newline character and starts there.
  final mutationStart =
      lineStart <= absoluteStart ? absoluteStart - lineStart : 0;
  // if the mutation begin is on the newline character, we want to add one to the line number
  if (absoluteStart + 1 == lineStart) {
    line += 1;
  }
  final mutationEndInOriginal = absoluteEnd - lineStart;
  // correct the end position in case the length changed.
  final mutationEnd =
      mutationEndInOriginal - (original.length - mutated.length);
  final lineEndMutated =
      findEndOfLineFromPosition(mutated, lineStart + mutationEnd);
  return MutatedLine(
    line,
    mutationStart,
    mutationEndInOriginal,
    original.substring(lineStart, lineEnd),
    mutated.substring(lineStart, lineEndMutated),
    mutation,
  );
}
