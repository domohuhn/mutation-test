// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/mutation_progress_bar.dart';
import 'package:test/test.dart';

import 'mock_system_interactions.dart';

void main() {
  test('App Progress bar - start file', () {
    final mock = MockSystemInteractions();
    final bar = MutationProgressBar(500, 0.8, mock);
    bar.startFile('moo', 100);
    expect(mock.argLine.length, 1);
    expect(mock.argLine[0], 'moo : 100 mutations');
  });

  test('App Progress bar - render', () {
    final mock = MockSystemInteractions();
    final bar = MutationProgressBar(500, 0.8, mock);
    bar.startFile('moo', 100);
    for (int i = 0; i < 50; ++i) {
      bar.increment();
    }
    mock.clear();
    bar.render();
    expect(mock.argLine.length, 0);
    expect(mock.argTexts.length, 1);
    expect(mock.argverboseLine.length, 1);
    expect(mock.argTexts[0].substring(0, 76),
        '\rFile [=========>         ]  50% Total [=>                 ]  10% (50/500) ~');
    expect(mock.argverboseLine[0], '');
  });

  test('App Progress bar - end file - failed', () {
    final mock = MockSystemInteractions();
    final bar = MutationProgressBar(500, 80, mock);
    bar.startFile('moo', 100);
    mock.clear();
    bar.endFile(50);
    expect(mock.argLine.length, 1);
    expect(mock.argLine[0],
        '\rFAILED: 50/100 (50.00%) mutations were not detected!');
  });

  test('App Progress bar - end file - ok', () {
    final mock = MockSystemInteractions();
    final bar = MutationProgressBar(500, 80, mock);
    bar.startFile('moo', 100);
    mock.clear();
    bar.endFile(0);
    expect(mock.argLine.length, 1);
    expect(mock.argLine[0], '\rOK: 0/100 (0.00%) mutations were not detected!');
  });
}
