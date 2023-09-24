// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/core/mutated_line.dart';

/// Holds the report data for a file.
class FileMutationResults {
  /// path to the file
  String path;

  /// contents of the file
  String contents;

  /// total mutation count per file
  int get mutationCount =>
      detectedCount + timeoutCount + undetectedCount + notCoveredCount;

  /// detected count per file
  int get detectedCount => detectedMutations.length;

  /// timeout count per file
  int get timeoutCount => timeoutMutations.length;

  /// detected count per file
  int get undetectedCount => undetectedMutations.length;

  /// detected count per file
  int get notCoveredCount => notCoveredByTests.length;

  int get blockedCount => timeoutCount + notCoveredCount;

  /// undetected mutations in this file
  List<MutatedLine> undetectedMutations;

  /// detected mutations in this file
  List<MutatedLine> detectedMutations;

  /// detected mutations in this file
  List<MutatedLine> timeoutMutations;

  /// mutations in this file not covered by tests
  List<MutatedLine> notCoveredByTests;

  Duration get elapsed {
    var dur = Duration();
    for (var element in undetectedMutations) {
      dur += element.elapsed;
    }
    for (var element in detectedMutations) {
      dur += element.elapsed;
    }
    for (var element in timeoutMutations) {
      dur += element.elapsed;
    }
    return dur;
  }

  FileMutationResults(this.path, this.contents)
      : undetectedMutations = [],
        detectedMutations = [],
        timeoutMutations = [],
        notCoveredByTests = [];

  bool lineHasUndetectedMutation(int i) {
    return _lineIsInList(undetectedMutations, i);
  }

  bool lineHasDetectedMutation(int i) {
    return _lineIsInList(detectedMutations, i);
  }

  bool lineHasTimeoutMutation(int i) {
    return _lineIsInList(timeoutMutations, i);
  }

  bool lineHasMutationNotCovered(int i) {
    return _lineIsInList(notCoveredByTests, i);
  }

  bool lineHasMutation(int i) {
    return _lineIsInList(undetectedMutations, i) ||
        _lineIsInList(detectedMutations, i) ||
        _lineIsInList(timeoutMutations, i) ||
        _lineIsInList(notCoveredByTests, i);
  }

  bool lineHasProblem(int i) {
    return _lineIsInList(undetectedMutations, i) ||
        _lineIsInList(timeoutMutations, i) ||
        _lineIsInList(notCoveredByTests, i);
  }

  bool _lineIsInList(List<MutatedLine> list, int i) {
    for (final m in list) {
      if (m.line == i) {
        return true;
      }
    }
    return false;
  }

  void sort() {
    undetectedMutations.sort((lhs, rhs) => lhs.line.compareTo(rhs.line));
    detectedMutations.sort((lhs, rhs) => lhs.line.compareTo(rhs.line));
    timeoutMutations.sort((lhs, rhs) => lhs.line.compareTo(rhs.line));
    notCoveredByTests.sort((lhs, rhs) => lhs.line.compareTo(rhs.line));
  }
}
