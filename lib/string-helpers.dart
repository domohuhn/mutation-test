import 'dart:math';

/// Finds the line number at [position] in a multiline [text].
/// Indexing starts at 1.
int findLineFromPosition(String text, int position) {
  var rv = 0;
  for(var i=0; i<min(text.length,position); i++) {
    if(text[i]=='\n') {
      rv += 1;
    }
  }
  return rv+1;
}

/// Finds the start position of the line at [position] in a multiline [text].
int findBeginOfLineFromPosition(String text, int position) {
  var rv = 0;
  for(var i=0; i<min(text.length-1,position); i++) {
    if(text[i]=='\n') {
      rv = i + 1;
    }
  }
  return rv;
}

/// Finds the end position of the line at [position] in a multiline [text].
int findEndOfLineFromPosition(String text, int position) {
  var rv = position;
  for(var i=position; i<text.length; i++) {
    if(text[i]=='\n') {
      return i;
    }
  }
  return rv;
}

/// Converts the inputs to a percentage string "[fraction]/[total]%"
String asPercentString(int fraction, int total) {
  var percent = 0.0;
  if (total>0) {
    percent = 100.0*fraction/total;
  }
  return '${percent.toStringAsFixed(2)}%';
}

