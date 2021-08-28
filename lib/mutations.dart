



/// A possible mutation of the source file.
/// 
/// Each occurence of the pattern will be replaced by one of the replacements and then the test commands are run
/// to check if the mutation survies.
class Mutation {
  final String pattern;
  List<String> replacements = [];

  Mutation(this.pattern);
}

