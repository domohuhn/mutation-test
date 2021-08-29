

import 'string-helpers.dart';

/// A possible mutation of the source file.
/// 
/// Each occurence of the pattern will be replaced by one of the replacements and then the test commands are run
/// to check if the mutation survies.
class Mutation {
  final Pattern pattern;
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
    rv += _formatRemoved(true);
    rv += _formatAdded(true);
    return rv;
  }

  String toHTML() {
    var rv = 'Line $line:<br>\n';
    rv += _formatRemoved(false);
    rv += _formatAdded(false);
    return rv;
  }

  String _formatRemoved(bool escape) {
    var rv = '&nbsp;&nbsp;&nbsp;&nbsp;<span style="background-color: rgb(255, 200, 200);">';
    rv += '- ${_escapeChars(original.substring(0,start),escape)}';
    rv += '<span style="background-color: rgb(255, 50, 50);">';
    rv += _escapeChars(original.substring(start,end),escape);
    rv += '</span>';
    rv += _escapeChars(original.substring(end,original.length-1),escape);
    rv += '</span><br>\n';
    return rv;
  }

  String _formatAdded(bool escape) {
    var rv = '&nbsp;&nbsp;&nbsp;&nbsp;<span style="background-color: rgb(200, 255, 200);">';
    rv += '+ ${_escapeChars(mutated.substring(0,start),escape)}';
    rv += '<span style="background-color: rgb(50, 255, 50);">';
    var mutationEnd = end + mutated.length - original.length;
    rv += _escapeChars(mutated.substring(start,mutationEnd),escape);
    rv += '</span>';
    rv += _escapeChars(mutated.substring(mutationEnd,mutated.length-1),escape);
    rv += '</span><br>\n';
    return rv;
  }

  String _escapeChars(String text, bool doIt) {
    if (doIt) {
      return convertToMarkdown(text);
    }
    return text;
  }
}

