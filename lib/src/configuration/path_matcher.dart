// Copyright 2026, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:io';
import 'dart:math';

/// This class matches a string against a pattern with wildcards * and **.
class PathMatcher {
  bool _isDirectory = false;
  bool get isDirectory => _isDirectory;
  bool get isFile => !isDirectory;
  List<String> patterns = [];

  PathMatcher(String pattern, bool isDirectory) : _isDirectory = isDirectory {
    int lastTokenStart = 0;
    var lastWasWildcard = false;
    final normalized = normalizePath(pattern);
    for (final unit in normalized.codeUnits.indexed) {
      if (unit.$2 == 42) {
        if (lastWasWildcard) {
          patterns.last = '**';
        } else {
          patterns.add(normalized.substring(lastTokenStart, unit.$1));
          patterns.add('*');
        }
        lastTokenStart = unit.$1 + 1;
        lastWasWildcard = true;
      } else {
        lastWasWildcard = false;
      }
    }
    if (lastTokenStart < normalized.length) {
      patterns.add(normalized.substring(lastTokenStart));
    }
  }

  String normalizePath(String text) {
    var normalized = Platform.isWindows ? text.replaceAll('\\', '/') : text;
    while (normalized.contains('//')) {
      normalized = normalized.replaceAll('//', '/');
    }
    return normalized;
  }

  int _countPaths(String text, int start) {
    int count = 0;
    for (int i = start; i < text.length; i++) {
      if (text.codeUnits[i] == 47) {
        count += 1;
      }
    }
    return count;
  }

  // loop over substrings
  // if text -> exact match, move forward
  // if * -> ignore until next /, (or until next pattern, if text) done if last
  // if ** -> search for next text or done if last
  bool matches(String path) {
    final normalized = normalizePath(path);
    int lastChecked = 0;
    //print('=== BEGIN - patterns $patterns');
    for (int index = 0;
        index < patterns.length && lastChecked < normalized.length;
        index++) {
      final compare = patterns[index];
      //print("TO CHECK '$compare' ($lastChecked) '${normalized.substring(lastChecked)}'");
      if (compare == '*') {
        //print("simple wildcard");
        // if last pattern and no more / -> match
        if (index + 1 >= patterns.length) {
          return normalized.length >= lastChecked &&
              (_isDirectory || _countPaths(normalized, lastChecked) == 0);
        } else {
          // ignore until next / or start of next pattern
          final nextDirectory = normalized.indexOf('/', lastChecked);
          final nextMatch =
              normalized.indexOf(patterns[index + 1], lastChecked);
          //print("NEXT $nextDirectory $nextMatch");
          if (nextDirectory > 0 && nextMatch > 0) {
            lastChecked = min(nextMatch, nextDirectory);
          } else if (nextDirectory > 0) {
            lastChecked = nextDirectory;
          } else if (nextMatch > 0) {
            lastChecked = nextMatch;
          } else {
            return false;
          }
        }
      } else if (compare == '**') {
        //print("double wildcard");
        // if last pattern -> match
        if (index + 1 >= patterns.length && normalized.length >= lastChecked) {
          return true;
        } else {
          // ignore until start of next pattern
          final nextMatch =
              normalized.indexOf(patterns[index + 1], lastChecked);
          //print("NEXT $nextMatch");
          if (nextMatch > 0) {
            lastChecked = nextMatch;
          } else {
            return false;
          }
        }
      } else {
        final endOfNextMatch = lastChecked + compare.length;
        //print("string compare ${normalized.length} >= $endOfNextMatch && ${normalized.startsWith(compare,lastChecked)} && (${_nextPatternIsWildcard(index)} || ${_nextPathTokenIsADirectory(compare,normalized,lastChecked)})");
        if (normalized.length >= endOfNextMatch &&
            normalized.startsWith(compare, lastChecked)) {
          if (index + 1 >= patterns.length) {
            //print("default string true ${_isDirectory} || ${normalized.length == endOfNextMatch}");
            return _isDirectory || normalized.length == endOfNextMatch;
          } else {
            //print("default string true - continue");
            lastChecked = endOfNextMatch;
          }
        } else {
          //print("match string false");
          return false;
        }
      }
    }
    //print("default string false");
    return false;
  }
}
