/// Copyright 2021, domohuhn. 
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license

import 'package:mutation_test/progress-bar.dart';
import 'dart:io';
import 'string-helpers.dart';

/// Tracks the current progress and estimates the remaining time.
class MutationProgressBar {
  ProgressBar file;
  ProgressBar total;
  bool verbose;
  double threshold;
  int _width = 0;
  bool quiet = false;
  final Stopwatch _timer = Stopwatch();

  set mutationCount(int v) => total.maximum = v;

  MutationProgressBar(int count, this.verbose, this.threshold, this.quiet) : 
    file = ProgressBar(count, width: 30, showTotal: false, left: 'File ['), 
    total= ProgressBar(count, width: 24, left: 'Total [', widthIncludesText: false);

  void startFile(String path, int count) {
    if (!_timer.isRunning) {
      _timer.start();
    }
    if(!quiet) {
      print('$path : performing $count mutations'.padRight(_width));
    }
    file.current = 0;
    file.maximum = count;
  }

  void endFile(int failed) {
    var pct = 1.0 - failed.toDouble()/file.maximum.toDouble();
    final prefix = 100*pct <= threshold ? 'FAILED' : 'OK';
    var text = '$prefix: $failed/${file.maximum} (${asPercentString(failed, file.maximum)}) mutations passed all tests!'.padRight(_width);
    _writeText(text,true);
  }

  void increment() {
    file.update(1);
    total.update(1);
  }

  void render() {
    var text = '$file $total';
    var duration = _timer.elapsed;
    var max = duration*(1.0/total.progress);
    var remaining = max-duration;
    text += ' ~${formatDuration(remaining)}';
    var next =  text.length;
    _writeText(text.padRight(_width),false);
    _width = next;
  }

  void _writeText(String text,bool newline) {
    if(quiet) {
      return;
    }
    if(verbose) {
      print(text);
    }
    else {
      if (newline) {
        text += '\n';
      }
      stdout.write('\r'+text);
    }
  }
}
