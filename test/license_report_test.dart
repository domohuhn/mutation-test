// Copyright 2023, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/create_license_text.dart';
import 'package:test/test.dart';

void main() {
  test('Create license text', () {
    // checks if licenses are created - checking for the full contents does not scale ...
    var result = createLicenseText();
    expect(result.isNotEmpty, true);
    // search for bsd license start:
    expect(
        result.contains(
            '''Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:'''),
        true);
  });
}
