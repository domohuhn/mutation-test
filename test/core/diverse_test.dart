// Copyright 2021, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/core/core.dart';
import 'package:test/test.dart';

void main() {
  test('Command - toString', () {
    var cmd = Command('original', 'make', []);
    expect(cmd.toString(), 'Command: "original"');
  });

  test('MutationError - toString', () {
    var err = MutationError('moo');
    expect(err.toString(), 'Error: moo');
  });
}
