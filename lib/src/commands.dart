/// Copyright 2021, domohuhn. 
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license

/// A command to check if a mutation survives your tests.
/// 
/// The return value of the command is checked against the expectedReturnValue to determine success.
class Command {
  String group = '';
  String? directory;
  int expectedReturnValue = 0;
  Duration? timeout;
  final String original;
  final String command;
  final List<String> arguments;

  Command(this.original, this.command, this.arguments);

  @override
  String toString() {
    return 'Command: "$original"';
  }
}

