// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:convert';
import 'package:path/path.dart';

import 'package:mutation_test/src/core/errors.dart';

/// Coverage data for a file
class FileCoverage {
  String filename;
  Set<int> coveredLines;

  FileCoverage(this.filename) : coveredLines = <int>{};

  /// Checks if any line in between start and end is covered.
  bool isCovered(int start, int end) {
    if (start <= end) {
      for (int line = start; line <= end; ++line) {
        if (_containsLine(line)) {
          return true;
        }
      }
      return false;
    }
    return _containsLine(start);
  }

  bool _containsLine(int line) => coveredLines.contains(line);
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

  /// Checks if the lines in [file] are covered by tests.
  ///
  /// Returns true if there is no coverage information for the given file.
  bool isCoveredByTests(String file, int lineStart, [int lineEnd = -1]) {
    var info = getFileOrNull(file);
    if (info != null) {
      return info.isCovered(lineStart, lineEnd);
    }
    return true;
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
          if (hits > 0) {
            fileData.coveredLines.add(lineNumber);
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
