// Copyright 2021, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/core/mutated_line.dart';
import 'package:mutation_test/src/core/mutation.dart';
import 'package:mutation_test/src/core/range.dart';

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

  final MutatedCode _currentMutation = MutatedCode(
    '',
    MutatedLine(0, 0, 0, '', '', Mutation(0, '')),
  );
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
          if (_isPositionOk(whitelist, exclusions, text, _matches.current)) {
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

    _currentMutation.line = createMutatedLine(
      _matches.current.start,
      _matches.current.end,
      text,
      _currentMutation.text,
      mutation,
    );
    _currentMutation.line.replacementIndex = _index;

    _index += 1;
    return true;
  }
}

/// Checks if a [position] in [text] is inside the whitelists or if it is excluded.
bool _isPositionOk(List<Range> whitelist, List<Range> exclusions, String text,
    Match position) {
  var whitelisted = whitelist.isEmpty ||
      (_isInRange(whitelist, text, position.start) &&
          _isInRange(whitelist, text, position.end));
  var blacklisted = _isInRange(exclusions, text, position.start) ||
      _isInRange(exclusions, text, position.end);
  return whitelisted && !blacklisted;
}

/// Checks if a [position] in [text] is inside one of the ranges defined by [ranges].
bool _isInRange(List<Range> ranges, String text, int position) {
  for (final ex in ranges) {
    if (ex.isInRange(text, position)) {
      return true;
    }
  }
  return false;
}
