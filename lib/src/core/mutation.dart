// Copyright 2021, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/core/errors.dart';
import 'package:mutation_test/src/core/mutated_line.dart';
import 'package:mutation_test/src/core/mutation_iterator.dart';
import 'package:mutation_test/src/core/replacements.dart';
import 'package:mutation_test/src/core/range.dart';

const String _backUpIdPrefix = 'NamelessMutationRule';

/// A possible mutation of the source file.
///
/// Each occurrence of the pattern will be replaced by one of the replacements and then the test commands are run
/// to check if the mutation is detected.
class Mutation {
  final String? id;

  /// This mutation was parsed as the xth rule.
  /// Used internally to identify mutation rules.
  final int index;
  final Pattern pattern;
  final List<Replacement> replacements = [];

  Mutation(this.index, this.pattern, {this.id}) {
    if (id != null && id!.contains(_backUpIdPrefix)) {
      throw MutationError(
          'An id for a rule must not contain "$_backUpIdPrefix"! Got: $id');
    }
  }

  /// Iterates through [text] and replaces all matches of the pattern with every replacement.
  /// Only one match is mutated at a time and replaced with a single replacement.
  IterableMutation allMutations(
      String text, List<Range> whitelist, List<Range> exclusions) {
    return IterableMutation(
        MutationIterator(this, text, whitelist, exclusions));
  }

  String get xUnitId => id != null ? id! : '$_backUpIdPrefix-$index';
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
