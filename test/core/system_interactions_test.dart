// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/core/system_interactions.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  test('Create and read a file', () {
    var writer = SystemInteractions(true, true);
    const path = 'build/moo/out.html';
    const data = 'Somedata';
    writer.createPathsAndWriteFile(path, data);
    expect(File(path).existsSync(), true);
    expect(writer.readFile(path), data);
  });

  test('print to terminal - normal', () {
    // more or less a manual test to check if output is visibile and no expection is thrown ...
    var writer = SystemInteractions(false, false);
    writer.write('write normal -');
    writer.writeLine('writeLine');
    writer.verboseWriteLine('verboseWriteLine');
  });

  test('print to terminal - quiet', () {
    // more or less a manual test to check if output is visibile and no expection is thrown ...
    var writer = SystemInteractions(true, true);
    writer.write('write normal -');
    writer.writeLine('writeLine');
    writer.verboseWriteLine('verboseWriteLine');
  });

  test('print to terminal - verbose', () {
    // more or less a manual test to check if output is visibile and no expection is thrown ...
    var writer = SystemInteractions(true, false);
    writer.write('write normal -');
    writer.writeLine('writeLine');
    writer.verboseWriteLine('verboseWriteLine');
  });

  const dir = 'example';
  const dir1 = 'example/data';
  const dir2 = 'example/doesnotexist';

  test('directory exists', () {
    var sys = SystemInteractions(true, false);
    expect(sys.directoryExists(dir1), true);
    expect(sys.directoryExists(dir2), false);
  });

  test('file exists', () {
    var sys = SystemInteractions(true, false);
    expect(sys.fileExists('$dir1/source4.dart'), true);
    expect(sys.fileExists('$dir2/source4.dart'), false);
  });

  test('list directory', () {
    var sys = SystemInteractions(true, false);
    final list = sys.listDirectoryContents(dir, false, []);
    list.forEach(print);
    expect(list.length, 9);
  });

  test('list directory with pattern', () {
    var sys = SystemInteractions(true, false);
    final list = sys.listDirectoryContents(dir, false, [RegExp(r'.*\.dart$')]);
    expect(list.length, 3);
  });

  test('list directory recursive with pattern', () {
    var sys = SystemInteractions(true, false);
    final list = sys.listDirectoryContents(dir, true, [RegExp(r'.*\.dart$')]);
    expect(list.length, 4);
  });
}
