
import 'string-helpers.dart';

/// A range in the source file delimited by tokens.
class Range {
  final String startToken;
  final String endToken;

  Range(this.startToken,this.endToken);

  /// Checks if [position] in [text] is inside an exclusion range 
  /// defined by the start and end token in this instance.
  bool isInExclusionRange(String text, int position) {
    var start = findFirstTokenBeforePosition(text, position, startToken);
    var end = findFirstTokenAfterPosition(text, position, endToken);
    return start <= position && position <= end;
  }

}


