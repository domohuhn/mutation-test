// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:convert';
import 'package:path/path.dart';

import 'package:mutation_test/src/core/errors.dart';

/// Coverage data for a file
class FileCoverage {
  String filename;
  Map<int, int> coverage;

  FileCoverage(this.filename) : coverage = {};

  /// Checks if any line in between start and end is not covered.
  ///
  /// Returns true if the line was instrumented and not covered by tests.
  bool isUncovered(int start, int end) {
    if (start < end) {
      int notCoveredCount = 0;
      for (int line = start; line <= end; ++line) {
        if (_containsUncoveredLine(line)) {
          notCoveredCount += 1;
        }
      }
      return notCoveredCount == end - start;
    }
    return _containsUncoveredLine(start);
  }

  bool _containsUncoveredLine(int line) {
    if (coverage.containsKey(line)) {
      return coverage[line] == 0;
    }
    return false;
  }

  /// Returns true if a [line] is instrumented and executed
  bool lineIsCovered(int line) {
    return lineIsInstrumented(line) && coverage[line]! > 0;
  }

  /// Returns true if a [line] is instrumented
  bool lineIsInstrumented(int line) {
    return coverage.containsKey(line);
  }
}

/// This class holds the line coverage information for each source code file
/// of the project that is tested via mutation testing. In case a file is present
/// in this database, the mutation will only be tested if the lines are covered
/// in test suites.
class ProjectLineCoverage {
  Map<String, FileCoverage> coveredFiles;

  /// searches the path for a file, or
  /// checks if there is a file path ending with "path" (relative path)
  FileCoverage? getFileOrNull(String path) {
    if (coveredFiles.containsKey(path)) {
      return coveredFiles[path];
    }
    var absPath = canonicalize(path);
    if (coveredFiles.containsKey(absPath)) {
      return coveredFiles[absPath];
    }
    return null;
  }

  /// Checks if the lines in [file] are covered by tests. This method should be used
  /// to determine if a mutation has to be tested.
  ///
  /// Returns true if there is no coverage information for the given file.
  bool isCoveredByTests(String file, int lineStart, [int lineEnd = -1]) {
    var info = getFileOrNull(file);
    if (info != null) {
      var rv = info.isUncovered(lineStart, lineEnd);
      return !rv;
    }
    return true;
  }

  /// Checks if the [line] in [file] is instrumented and covered.
  bool lineIsCovered(String file, int line) {
    var info = getFileOrNull(file);
    if (info != null) {
      return info.lineIsCovered(line);
    }
    return false;
  }

  /// Checks if the [line] in [file] is instrumented.
  bool lineIsInstrumented(String file, int line) {
    var info = getFileOrNull(file);
    if (info != null) {
      return info.lineIsInstrumented(line);
    }
    return false;
  }

  ProjectLineCoverage() : coveredFiles = {};

  /// Creates the class by parsing a given string with the lcov file contents.
  ProjectLineCoverage.fromLCOV(String lcov) : coveredFiles = {} {
    const splitter = LineSplitter();
    bool recordStarted = false;
    int lineCounter = 0;
    String file = '';
    FileCoverage? fileData;
    for (final line in splitter.convert(lcov)) {
      lineCounter++;
      if (line.startsWith('SF:')) {
        if (recordStarted) {
          throw MutationError(
              'Expected end of record in line $lineCounter instead of starting a new record!');
        }
        recordStarted = true;
        file = line.substring(3);
        var canonPath = canonicalize(file);
        fileData =
            coveredFiles.putIfAbsent(canonPath, () => FileCoverage(file));
      }
      if (line.startsWith('DA:')) {
        if (!recordStarted || fileData == null) {
          throw MutationError(
              'Unexpected data record in line $lineCounter: no record started!');
        }
        final array = line.substring(3).split(',');
        try {
          final lineNumber = int.parse(array[0]);
          final hits = int.parse(array[1]);
          if (fileData.coverage.containsKey(lineNumber)) {
            fileData.coverage[lineNumber] =
                fileData.coverage[lineNumber]! + hits;
          } else {
            fileData.coverage.putIfAbsent(lineNumber, () => hits);
          }
        } catch (e) {
          throw MutationError(
              'Wrong format for a data record in line $lineCounter. Expected: DA:<line>,<hits> - got "$line".\nFailed with error: $e');
        }
      }
      if (line == 'end_of_record') {
        if (!recordStarted) {
          throw MutationError('Unexpected end of record in line $lineCounter!');
        }
        recordStarted = false;
        fileData = null;
      }
    }
  }
}
