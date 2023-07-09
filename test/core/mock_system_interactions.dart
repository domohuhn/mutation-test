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
    rvFileContents.clear();
    reads = 0;
    writes = 0;
  }

  /// all existing files for readFile and fileExists if useRealFileSystem is false
  Map<String, String> rvFileContents = {};
  bool useRealFileSystem = true;
  int reads = 0;
  int writes = 0;

  @override
  String readFile(String path) {
    ++reads;
    argPaths.add(path);
    if (useRealFileSystem) {
      return super.readFile(path);
    }
    if (rvFileContents.containsKey(path)) {
      return rvFileContents[path]!;
    }
    return '';
  }

  @override
  void writeFile(String path, String text) {
    ++writes;
    argPaths.add(path);
    argTexts.add(text);
    if (useRealFileSystem) {
      super.writeFile(path, text);
    }
  }

  /// the list of files returned from listDirectoryContents if useRealFileSystem is false
  List<String> rvFiles = [];

  @override
  List<String> listDirectoryContents(
      String path, bool recurse, List<RegExp> patterns) {
    argPaths.add(path);
    if (useRealFileSystem) {
      return super.listDirectoryContents(path, recurse, patterns);
    }
    return rvFiles;
  }

  @override
  bool fileExists(String path) {
    if (useRealFileSystem) {
      return super.fileExists(path);
    }
    return rvFileContents.containsKey(path);
  }
}
