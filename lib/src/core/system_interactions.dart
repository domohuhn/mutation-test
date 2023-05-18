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
    File(path).writeAsStringSync(text);
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
}
