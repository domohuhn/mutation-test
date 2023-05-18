// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/core/system_interactions.dart';

class MockSystemInteractions extends SystemInteractions {
  MockSystemInteractions() : super(false, false);

  List<String> argPaths = [];
  List<String> argTexts = [];

  @override
  void createPathsAndWriteFile(String path, String text) {
    argPaths.add(path);
    argTexts.add(text);
  }

  List<String> argLine = [];
  List<String> argverboseLine = [];

  @override
  void verboseWriteLine(String text) {
    argverboseLine.add(text);
  }

  @override
  void writeLine(String text) {
    argLine.add(text);
  }

  @override
  void write(String text) {
    argTexts.add(text);
  }

  void clear() {
    argPaths.clear();
    argTexts.clear();
    argLine.clear();
    argverboseLine.clear();
  }
}
