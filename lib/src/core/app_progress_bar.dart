// Copyright 2021, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/core/progress_bar.dart';
import 'package:mutation_test/src/core/system_interactions.dart';
import 'package:mutation_test/src/reports/string_helpers.dart';

/// Tracks the current progress and estimates the remaining time.
class AppProgressBar {
  ProgressBar file;
  ProgressBar total;
  double threshold;
  int _width = 0;
  SystemInteractions system;
  final Stopwatch _timer = Stopwatch();

  set mutationCount(int v) => total.maximum = v;

  AppProgressBar(int count, this.threshold, this.system)
      : file = ProgressBar(count, width: 30, showTotal: false, left: 'File ['),
        total = ProgressBar(count,
            width: 27, left: 'Total [', widthIncludesText: false);

  /// Starts the progress bar for a new file.
  /// Prints the [path] of the file and the number of mutations [count] for that file.
  /// [count] is also used to compute the percentage of progress.
  void startFile(String path, int count) {
    if (!_timer.isRunning) {
      _timer.start();
    }
    system.writeLine('$path : $count mutations'.padRight(_width));
    file.current = 0;
    file.maximum = count;
  }

  /// Writes the end of file message to the console with the count of [failed] tests.
  void endFile(int failed) {
    var pct = 1.0 - failed.toDouble() / file.maximum.toDouble();
    final prefix = 100 * pct <= threshold ? 'FAILED' : 'OK';
    var text =
        '\r$prefix: $failed/${file.maximum} (${asPercentString(failed, file.maximum)}) mutations were not detected!'
            .padRight(_width + 1);
    system.writeLine(text);
  }

  /// Increments the progress bar with one additional test.
  void increment() {
    file.update(1);
    total.update(1);
  }

  /// Updates the progress bar in the console by writing a new line.
  void render() {
    var text = _createText();
    var next = text.length;
    system.write('\r${text.padRight(_width)}');
    system.verboseWriteLine('');
    _width = next;
  }

  /// Creates the text to update the progress bar
  String _createText() {
    var text = '$file $total';
    var duration = _timer.elapsed;
    var max = duration * (1.0 / total.progress);
    var remaining = max - duration;
    text += ' ~${formatDuration(remaining)}';
    text.padRight(_width);
    return text;
  }
}
