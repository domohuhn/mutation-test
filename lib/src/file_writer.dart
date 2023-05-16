// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:io';
import 'package:mutation_test/src/string_helpers.dart';

/// FileWriter serves as abstraction of the interaction with the system. It can
/// be injected to other functions to actually write to the file system, while
/// a different class inheriting from this can be used for the unit tests.
class FileWriter {
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
}
