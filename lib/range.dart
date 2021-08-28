
import 'string-helpers.dart';

/// A range in the source file delimited by tokens.
class Range {
  final String startToken;
  final String endToken;

  Range(this.startToken,this.endToken);

  /// Checks if [position] in [text] is inside an exclusion range 
  /// defined by the start and end token in this instance.
  bool isInRange(String text, int position) {
    // TODO check exclusion ranges from start of file
    // search begin / end pairs
    //var shiftStart = startToken.length-1;
    //var startSearch = position-shiftStart>0? position-shiftStart : position;
    var start = findFirstTokenBeforePosition(text, position, startToken); 
    //print('CHECKING $position in [$start,xxxx] Start "$startToken" End "$endToken" ');
    if (start<0) {
      return false;
    }
    if(start==position && position>0 && isInRange(text,position-1)) {
      return true;
    }
    var shiftEnd = endToken.length-1;
    var end = findFirstTokenAfterPosition(text, start, endToken);
    //print('CHECKING $position in [$start,${end+shiftEnd}] Start "$startToken" End "$endToken" ');
    if (end<0 || start>=end) {
      return false;
    }
    return start <= position && position <= end+shiftEnd;
  }

}


