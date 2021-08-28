import 'dart:math';

int findLineFromPosition(String text, int position) {
  var rv = 0;
  for(var i=0; i<min(text.length,position); i++) {
    if(text[i]=='\n') {
      rv += 1;
    }
  }
  return rv+1;
}


int findBeginOfLineFromPosition(String text, int position) {
  var rv = 0;
  for(var i=0; i<min(text.length-1,position); i++) {
    if(text[i]=='\n') {
      rv = i + 1;
    }
  }
  return rv;
}

int findEndOfLineFromPosition(String text, int position) {
  var rv = position;
  for(var i=position; i<text.length; i++) {
    if(text[i]=='\n') {
      return i;
    }
  }
  return rv;
}

