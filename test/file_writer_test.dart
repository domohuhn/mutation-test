// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/file_writer.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  test('Create a file', () {
    var writer = FileWriter();
    const path = 'build/out.html';
    writer.createPathsAndWriteFile(path, 'Somedata');
    expect(File(path).existsSync(), true);
  });
}
