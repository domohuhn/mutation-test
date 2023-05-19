// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:io';
import 'package:mutation_test/src/reports/string_helpers.dart';

/// SystemInteractions serves as abstraction of the interaction with the system. It can
/// be injected to other functions to e.g. write to the file system, while
/// a different class inheriting from this can be used for the unit tests.
class SystemInteractions {
  SystemInteractions(this.verbose, this.quiet);

  /// Creates all directories in [path] that do not exist
  /// and then writes a file named [path] with [text] as its contents.
  void createPathsAndWriteFile(String path, String text) {
    final dir = getDirectory(path);
    if (dir.isNotEmpty) {
      if (!Directory(dir).existsSync()) {
        Directory(dir).createSync(recursive: true);
      }
    }
    writeFile(path, text);
  }

  bool verbose = false;
  bool quiet = false;

  /// Writes a line of [text] to the terminal if verbose is true and quiet false.
  void verboseWriteLine(String text) {
    if (verbose) {
      _write(text, true);
    }
  }

  /// Writes a line of [text] to the terminal if quiet is false.
  void writeLine(String text) {
    _write(text, true);
  }

  /// Writes [text] to the terminal (without appending a new line) if quiet is false.
  void write(String text) {
    _write(text, false);
  }

  void _write(String text, bool line) {
    if (quiet) {
      return;
    }
    if (line) {
      stdout.writeln(text);
    } else {
      stdout.write(text);
    }
  }

  /// Synchronously checks if a file exists in [path]
  bool fileExists(String path) {
    return File(path).existsSync();
  }

  /// Synchronously checks if a file exists in [path]
  bool directoryExists(String path) {
    return Directory(path).existsSync();
  }

  /// Synchronously lists all files in [path] whose names match the [patterns].
  /// If [recurse] is set to true, then the subdirectories will also be included.
  List<String> listDirectoryContents(
      String path, bool recurse, List<RegExp> patterns) {
    List<String> files = [];
    var tree = Directory(path).listSync(recursive: recurse);
    for (var f in tree) {
      if (f is Link || f is Directory) {
        continue;
      }
      if (patterns.isNotEmpty) {
        for (var pat in patterns) {
          if (pat.hasMatch(f.path)) {
            files.add(f.path);
          }
        }
      } else {
        files.add(f.path);
      }
    }
    return files;
  }

  /// Synchronously reads the entire file in [path]
  String readFile(String path) {
    return File(path).readAsStringSync();
  }

  /// Synchronously writes the entire [text] to a file called [path]
  void writeFile(String path, String text) {
    File(path).writeAsStringSync(text);
  }
}
