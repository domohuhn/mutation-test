

class InputError implements Exception {
  String cause;
  InputError(this.cause);

  @override
  String toString(){
    return 'InputError: '+cause;
  }
}
