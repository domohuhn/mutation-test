/// Copyright 2021, domohuhn. 
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license

import 'package:mutation_test/src/ratings.dart';
import 'package:test/test.dart';

void main() {
  test('Rating - Empty ', () {
    var ratings = Ratings();
    expect(ratings.isSuccessful(100.0), true);
    expect(ratings.isSuccessful(99.999), false);
    expect(ratings.rating(100.0), 'N/A');
  });

  test('Rating - Threshold', () {
    var ratings = Ratings();
    ratings.failure = 50.0;
    expect(ratings.isSuccessful(100.0), true);
    expect(ratings.isSuccessful(51.0), true);
    expect(ratings.isSuccessful(49.999), false);
  });

  test('Rating - get rating', () {
    var ratings = Ratings();
    ratings.addRating(0.0, 'F');
    ratings.addRating(100.0, 'A');
    ratings.addRating(80.0, 'B');
    ratings.addRating(20.0, 'E');
    ratings.addRating(40.0, 'D');
    ratings.addRating(60.0, 'C');
    expect(ratings.rating(100.0), 'A');
    expect(ratings.rating(85.0), 'B');
    expect(ratings.rating(65.0), 'C');
    expect(ratings.rating(45.0), 'D');
    expect(ratings.rating(25.0), 'E');
    expect(ratings.rating(5.0), 'F');
  });

  test('Rating - sanitize', () {
    var ratings = Ratings();
    ratings.sanitize();
    expect(ratings.rating(100.0), 'A');
    expect(ratings.rating(85.0), 'B');
    expect(ratings.rating(65.0), 'C');
    expect(ratings.rating(45.0), 'D');
    expect(ratings.rating(25.0), 'E');
    expect(ratings.rating(5.0), 'F');
    expect(ratings.isSuccessful(81.0), true);
    expect(ratings.isSuccessful(79.999), false);
  });

  test('Rating - dont sanitize', () {
    var ratings = Ratings();
    ratings.failure = 50;
    ratings.sanitize();
    expect(ratings.rating(100.0), 'N/A');
    expect(ratings.isSuccessful(79.999), true);
  });

}
