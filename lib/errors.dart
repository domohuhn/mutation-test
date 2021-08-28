
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
