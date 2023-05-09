// Copyright 2021, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license
import 'package:mutation_test/src/errors.dart';

/// Abstract class for all replacements.
abstract class Replacement {
  /// Replaces the [match] in [text] and returns a copy.
  String replace(String text, Match match);
}

/// Implements a literal text replacement.
class LiteralReplacement extends Replacement {
  final String _text;
  LiteralReplacement(this._text);

  /// Replaces the [match] in [text] and returns a copy.
  /// The text of the match is removed and replaced by the contents of this class.
  @override
  String replace(String text, Match match) {
    return text.substring(0, match.start) + _text + text.substring(match.end);
  }
}

/// Just a simple data structure
class RegexGroup {
  int start;
  int end;
  int index;
  RegexGroup(this.start, this.end, this.index);
}

/// Implements a text replacement that will also replace the tokens $1, $2, $3, ... with the groups found in the regular expression match.
class RegexReplacement extends Replacement {
  String _text;
  final List<RegexGroup> _groups = [];
  RegexReplacement(this._text) {
    _findGroups();
    _removeEscapeSequences();
    _validate();
  }

  /// Validates that the replacements were all ok.
  void _validate() {
    var lastEnd = 0;
    for (final grp in _groups) {
      if (lastEnd > grp.start) {
        throw MutationError(
            'Internal error - there should never be overlapping replacement groups! Group: index ${grp.index} in [${grp.start},${grp.end}] overlaps $lastEnd');
      }
      if (!(grp.start < _text.length && grp.end <= _text.length)) {
        throw MutationError(
            'Internal error - group outside string! Group: index ${grp.index} in [${grp.start},${grp.end}] outside of ${_text.length}');
      }
      lastEnd = grp.end;
    }
  }

  /// Getter
  String get text => _text;

  /// Higher order funtion that searches for matches of [reg] in text and calls [functor] with each match.
  /// It is expected that functor will reduce the string length by 1 from the start of the match.
  void _processText(RegExp reg, void Function(Match) functor) {
    var index = 0;
    var found = true;
    while (found && index < _text.length) {
      found = false;
      for (final m in reg.allMatches(_text, index)) {
        functor(m);
        found = true;
        _leftShiftGroupsAfter(m.start);
        index = m.end - 1;
        break;
      }
    }
  }

  /// Removes all escape sequences from the pattern string and shifts the groups accordingly.
  void _removeEscapeSequences() {
    _processText(RegExp(r'([\\]|[\\][\\])[$]([0-9]+)'), (Match m) {
      if (m.group(1) == r'\\') {
        _text =
            '${_text.substring(0, m.start)}\\\$${m.group(2)}${_text.substring(m.end)}';
      } else {
        _text =
            '${_text.substring(0, m.start)}\$${m.group(2)}${_text.substring(m.end)}';
      }
    });

    _processText(RegExp(r'([\\][tnr])'), (Match m) {
      if (m.group(1) == r'\n') {
        _text = '${_text.substring(0, m.start)}\n${_text.substring(m.end)}';
      } else if (m.group(1) == r'\t') {
        _text = '${_text.substring(0, m.start)}\t${_text.substring(m.end)}';
      } else if (m.group(1) == r'\r') {
        _text = '${_text.substring(0, m.start)}\r${_text.substring(m.end)}';
      } else {
        throw MutationError('Internal error - no matching whitespace!');
      }
    });
  }

  /// Finds the positions and indices of the groups in the given replacement pattern.
  void _findGroups() {
    var pattern = RegExp(r'(^|[^\\]|[\\][\\])[$]([0-9]+)');
    for (final m in pattern.allMatches(_text)) {
      var prefix = m.group(1);
      var grp = m.group(2);
      if (prefix == null || grp == null) {
        throw MutationError(
            'Internal error - matched group without number. This should not happen!');
      }
      _groups.add(RegexGroup(m.start + prefix.length, m.end, int.parse(grp)));
    }
  }

  /// Shifts all groups after [position] one index to the left.
  void _leftShiftGroupsAfter(int position) {
    for (final grp in _groups) {
      if (grp.start <= position && position < grp.end) {
        throw MutationError(
            'Internal error - groups should not be modified! $position is in [${grp.start}, ${grp.end}]');
      }
      if (grp.start > position) {
        grp.start -= 1;
        grp.end -= 1;
      }
    }
  }

  /// Replaces the [match] in [text] and returns a copy.
  /// The text of the match is removed and replaced by the contents of this class.
  /// All tokens of type $[0-9]+ will be replaced with the matching groups unless
  /// the dollar sign was escaped.
  @override
  String replace(String text, Match match) {
    var tmp = _text;
    var shift = 0;
    try {
      for (final grp in _groups) {
        var repl = match.group(grp.index);

        if (repl == null) {
          throw MutationError(
              'RegEx mutation "$_text" requires groups! ${grp.index} not present!');
        }
        tmp = tmp.substring(0, grp.start + shift) +
            repl +
            tmp.substring(grp.end + shift);
        shift += repl.length - (grp.end - grp.start);
      }
    } catch (e) {
      throw MutationError(
          'RegEx mutation "$_text" requires groups! Pattern only has ${match.groupCount} groups!  ${e.toString()}');
    }
    return text.substring(0, match.start) + tmp + text.substring(match.end);
  }
}
