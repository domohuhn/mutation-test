// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/file_writer.dart';

class MockFileWriter extends FileWriter {
  List<String> argPaths = [];
  List<String> argTexts = [];

  @override
  void createPathsAndWriteFile(String path, String text) {
    argPaths.add(path);
    argTexts.add(text);
  }
}
