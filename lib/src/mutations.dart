/// Copyright 2021, domohuhn.
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license

import 'package:mutation_test/src/string_helpers.dart';
import 'package:mutation_test/src/replacements.dart';
import 'package:mutation_test/src/range.dart';

/// A possible mutation of the source file.
///
/// Each occurence of the pattern will be replaced by one of the replacements and then the test commands are run
/// to check if the mutation is detected.
class Mutation {
  final Pattern pattern;
  final List<Replacement> replacements = [];

  Mutation(this.pattern);

  /// Iterate through [text] and replaces all matches of the pattern with every replacement.
  /// Only one match is mutated at a time and replaced with a single replacement.
  IterableMutation allMutations(
      String text, List<Range> whitelist, List<Range> exclusions) {
    return IterableMutation(
        MutationIterator(this, text, whitelist, exclusions));
  }
}

/// Wrapper to allow iteration
class IterableMutation extends Iterable<MutatedCode> {
  IterableMutation(this._itr);
  final Iterator<MutatedCode> _itr;

  @override
  Iterator<MutatedCode> get iterator => _itr;
}

/// Wrapper for the return value of the iterator.
class MutatedCode {
  /// The full content of the mutated file
  String text;

  /// Information about the mutated line.
  MutatedLine line;
  MutatedCode(this.text, this.line);
}

/// Iterator for all mutations in a given text.
class MutationIterator implements Iterator<MutatedCode> {
  MutationIterator(this.mutation, this.text, this.whitelist, this.exclusions)
      : _matches = mutation.pattern.allMatches(text).iterator;

  final Mutation mutation;
  final String text;
  final List<Range> whitelist;
  final List<Range> exclusions;
  int _index = 0;
  bool _initialized = false;

  final MutatedCode _currentMutation =
      MutatedCode('', MutatedLine(0, 0, 0, '', ''));
  final Iterator<Match> _matches;

  @override
  MutatedCode get current => _currentMutation;

  @override
  bool moveNext() {
    if (_index >= mutation.replacements.length || !_initialized) {
      var advance = true;
      _index = 0;
      while (advance) {
        if (_matches.moveNext()) {
          if (isPositionOk(whitelist, exclusions, text, _matches.current)) {
            advance = false;
            _initialized = true;
          }
        } else {
          return false;
        }
      }
    }
    _currentMutation.text =
        mutation.replacements[_index].replace(text, _matches.current);
    _currentMutation.line = createMutatedLine(_matches.current.start,
        _matches.current.end, text, _currentMutation.text);
    _index += 1;
    return true;
  }
}

/// Checks if a [position] in [text] is inside the whitelists or if it is excluded.
bool isPositionOk(List<Range> whitelist, List<Range> exclusions, String text,
    Match position) {
  var whitelisted = whitelist.isEmpty ||
      (isInRange(whitelist, text, position.start) &&
          isInRange(whitelist, text, position.end));
  var blacklisted = isInRange(exclusions, text, position.start) ||
      isInRange(exclusions, text, position.end);
  return whitelisted && !blacklisted;
}

/// Checks if a [position] in [text] is inside one of the ranges defined by [ranges].
bool isInRange(List<Range> ranges, String text, int position) {
  for (final ex in ranges) {
    if (ex.isInRange(text, position)) {
      return true;
    }
  }
  return false;
}

/// Adds a mutation to the Testrunner.
MutatedLine createMutatedLine(
    int absoluteStart, int absoluteEnd, String original, String mutated) {
  if (absoluteStart<0) {
    absoluteStart = 0;
  }
  if (absoluteStart>original.length) {
    absoluteStart = original.length;
  }
  if (absoluteStart>absoluteEnd) {
    absoluteEnd = absoluteStart;
  }
  if (absoluteEnd>original.length) {
    absoluteEnd = original.length;
  }
  var line = findLineFromPosition(original, absoluteStart);
  final lineStart = findBeginOfLineFromPosition(original, absoluteStart);
  final lineEnd = findEndOfLineFromPosition(original, absoluteEnd);
  // this may be false if the mutation matches the newline character and starts there.
  final mutationStart = lineStart<=absoluteStart ? absoluteStart - lineStart : 0;
  // if the mutation begin is on the newline character, we want to add one to the line number
  if (absoluteStart+1 == lineStart) {
    line += 1;
  }
  final mutationEnd = absoluteEnd - lineStart;
  final lineEndMutated =
      findEndOfLineFromPosition(mutated, lineStart + mutationEnd);
  return MutatedLine(
      line,
      mutationStart,
      mutationEnd,
      original.substring(lineStart, lineEnd),
      mutated.substring(lineStart, lineEndMutated));
}

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

  MutatedLine(this.line, int first, int last, this.original, this.mutated) {
    /// make wrong states impossible to repesent
    start = first>=0 ? first : 0;
    end = last <= original.length ? last : original.length;
  }

  /// Pretty formatting
  String toMarkdown() {
    var rv = 'Line $line:<br>\n';
    rv += _formatRemoved(true);
    rv += _formatAdded(true);
    return rv;
  }

  /// Pretty formatting
  String toHTML() {
    var rv = 'Line $line:<br>\n';
    rv += _formatRemoved(false);
    rv += _formatAdded(false);
    return rv;
  }

  String _formatRemoved(bool escape) {
    var rv =
        '&nbsp;&nbsp;&nbsp;&nbsp;<span style="background-color: rgb(255, 200, 200);">';
    rv += '- ${_escapeChars(original.substring(0, start), escape)}';
    rv += '<span style="background-color: rgb(255, 50, 50);">';
    rv += _escapeChars(original.substring(start, end), escape);
    rv += '</span>';
    rv += _escapeChars(original.substring(end), escape);
    rv += '</span><br>\n';
    return rv;
  }

  String _formatAdded(bool escape) {
    final begin = start<mutated.length ? start : 0;
    var rv =
        '&nbsp;&nbsp;&nbsp;&nbsp;<span style="background-color: rgb(200, 255, 200);">';
    rv += '+ ${_escapeChars(mutated.substring(0, begin), escape)}';
    rv += '<span style="background-color: rgb(50, 255, 50);">';
    var mutationEnd = end + mutated.length - original.length;
    mutationEnd = mutationEnd>=begin && mutationEnd<=mutated.length ? mutationEnd : begin;
    rv += _escapeChars(mutated.substring(begin, mutationEnd), escape);
    rv += '</span>';
    rv += _escapeChars(mutated.substring(mutationEnd), escape);
    rv += '</span><br>\n';
    return rv;
  }

  /// Formats the modified code for the Html reporting.
  String formatMutatedCodeToHTML() {
    final begin = start<mutated.length ? start : 0;
    var rv = '<span class="addedLine">';
    rv += '+ ${escapeCharsForHtml(mutated.substring(0, begin))}';
    rv += '<span class="changedTokens">';
    var mutationEnd = end + mutated.length - original.length;
    mutationEnd = mutationEnd>=begin && mutationEnd<=mutated.length ? mutationEnd : begin;
    rv += escapeCharsForHtml(mutated.substring(begin, mutationEnd));
    rv += '</span>';
    rv += escapeCharsForHtml(mutated.substring(mutationEnd));
    rv += '</span>';
    return rv;
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
