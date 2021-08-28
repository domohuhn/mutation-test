

/// A possible mutation of the source file.
/// 
/// Each occurence of the pattern will be replaced by one of the replacements and then the test commands are run
/// to check if the mutation survies.
class Mutation {
  final String pattern;
  List<String> replacements = [];

  Mutation(this.pattern);
}

/// A mutation that passed all tests.
class UndetectedMutation {
  int line;
  int start;
  int end;
  String original;
  String mutated;

  UndetectedMutation(this.line,this.start,this.end,this.original,this.mutated);

  String toMarkdown() {
    var rv = 'Line $line:<br>\n';
    rv += _formatRemoved();
    rv += _formatAdded();
    return rv;
  }

  String _formatRemoved() {
    var rv = '&nbsp;&nbsp;&nbsp;&nbsp;<span style="background-color: rgb(255, 200, 200);">';
    rv += '- ${original.substring(0,start).replaceAll('\*', '\\\*')}';
    rv += '<span style="background-color: rgb(255, 50, 50);">';
    rv += original.substring(start,end).replaceAll('\*', '\\\*');
    rv += '</span>';
    rv += original.substring(end,original.length-1).replaceAll('\*', '\\\*');
    rv += '</span><br>\n';
    return rv;
  }

  String _formatAdded() {
    var rv = '&nbsp;&nbsp;&nbsp;&nbsp;<span style="background-color: rgb(200, 255, 200);">';
    rv += '+ ${mutated.substring(0,start).replaceAll('\*', '\\\*')}';
    rv += '<span style="background-color: rgb(50, 255, 50);">';
    var mutationEnd = end + mutated.length - original.length;
    rv += mutated.substring(start,mutationEnd).replaceAll('\*', '\\\*');
    rv += '</span>';
    rv += mutated.substring(mutationEnd,mutated.length-1).replaceAll('\*', '\\\*');
    rv += '</span><br>\n';
    return rv;
  }
}

