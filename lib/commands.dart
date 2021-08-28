



/// A command to check if a mutation survies your tests.
/// 
/// The return value of the command is checked against the expectedReturnValue to determine success.
class Command {
  String name = '';
  String group = '';
  String? directory;
  int expectedReturnValue = 0;
  final String original;
  final String command;
  final List<String> arguments;

  Command(this.original, this.command, this.arguments);
}

