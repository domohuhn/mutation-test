// Copyright 2021, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/configuration/configuration.dart';
import 'package:mutation_test/src/core/commands.dart';
import 'package:test/test.dart';

import '../core/mock_system_interactions.dart';

void main() {
  final mock = MockSystemInteractions();
  mock.useRealFileSystem = false;
  test('Infer rules - no pubspec', () {
    expect(mock.rvFileContents.length, 0);
    final configuration = Configuration(mock, true);
    configuration.inferCommandsIfEmpty();
    expect(configuration.commands.length, 0);
  });

  test('Infer rules - dart', () {
    mock.rvFileContents['pubspec.yaml'] = 'environment:\n    sdk: "^3.0.0"';
    expect(mock.rvFileContents.length, 1);
    final configuration = Configuration(mock, true);
    configuration.inferCommandsIfEmpty();
    expect(configuration.commands.length, 1);
    expect(configuration.commands[0].original, 'dart test');
  });

  test('Infer rules - flutter', () {
    mock.rvFileContents['pubspec.yaml'] =
        'dependencies:\n    flutter:\n      sdk: flutter';
    expect(mock.rvFileContents.length, 1);
    final configuration = Configuration(mock, true);
    configuration.inferCommandsIfEmpty();
    expect(configuration.commands.length, 1);
    expect(configuration.commands[0].original, 'flutter test');
  });

  test('Infer rules - do nothing', () {
    mock.rvFileContents['pubspec.yaml'] =
        'dependencies:\n    flutter:\n      sdk: flutter';
    expect(mock.rvFileContents.length, 1);
    final configuration = Configuration(mock, true);
    configuration.commands.add(Command('bla', 'bla', []));
    configuration.inferCommandsIfEmpty();
    expect(configuration.commands.length, 1);
    expect(configuration.commands[0].original, 'bla');
  });
}
