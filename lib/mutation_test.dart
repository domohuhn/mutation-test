/// This library provides functionality to test the quality of your automated tests
/// via mutation testing.
///
/// Especially for software that has to provide functional safety,
/// the tests have to be of high quality and recognize any change in behaviour of
/// your code.
/// In order to verify the quality of your tests, create an instance of the "MutationTest"
/// class and call method runMutationTest().
library mutation_test;

// Copyright 2021, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

export 'package:mutation_test/src/mutation_test.dart';
export 'package:mutation_test/src/report_format.dart';
export 'package:mutation_test/src/builtin_rules.dart';
export 'package:mutation_test/src/version.dart';
export 'package:mutation_test/src/create_license_text.dart';
