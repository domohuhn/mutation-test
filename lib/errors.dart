/// Copyright 2021, domohuhn. 
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license

/// A simple exception for any error.
class Error implements Exception {
  /// cause of the error
  String cause;
  Error(this.cause);

  @override
  String toString(){
    return 'Error: '+cause;
  }
}
