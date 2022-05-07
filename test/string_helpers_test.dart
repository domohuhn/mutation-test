/// Copyright 2021, domohuhn.
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license
import 'package:mutation_test/src/string_helpers.dart';
import 'package:test/test.dart';

void main() {
  var text = '''  This is a long string.
  Another line.
  More!
  MORE!
  MOOOOORE!

  Ok, this may be enough lines.
  ''';
  test('Find line number', () {
    expect(findLineFromPosition(text, 45), 3);
  });

  test('Find start of line', () {
    expect(findBeginOfLineFromPosition(text, 45), 41);
  });

  test('Find end of line', () {
    expect(findEndOfLineFromPosition(text, 45), 48);
  });

  test('report file name', () {
    var moo = createReportFileName('input.cpp', 'output', 'html');
    expect(moo, 'output/input-report.html');
  });

  test('report file name forwardslash', () {
    var moo = createReportFileName('before/input.cpp', 'output', 'html');
    expect(moo, 'output/input-report.html');
  });

  test('report file name backslash', () {
    var moo = createReportFileName('before\\input.cpp', 'output', 'html');
    expect(moo, 'output/input-report.html');
  });

  test('percent string', () {
    var moo = asPercentString(25, 100);
    expect(moo, '25.00%');
  });

  test('convert to xml', () {
    var moo = convertToXML('<&"\'>');
    expect(moo, '&lt;&amp;&quot;&apos;&gt;');
  });

  test('formatDuration', () {
    var moo = formatDuration(Duration(hours: 1));
    expect(moo, '1h 0m 0s');
  });

  test('convertToMarkdown', () {
    // ignore: unnecessary_string_escapes
    var moo = convertToMarkdown('\*');
    // ignore: unnecessary_string_escapes
    expect(moo, '\\\*');
  });

  test('get directory forwardslash', () {
    expect(getDirectory('somefile.cpp'), '');
    expect(getDirectory('path/somefile.cpp'), 'path/');
    expect(getDirectory('more/dirs/path/somefile.cpp'), 'more/dirs/path/');
  });
  test('get directory backslash', () {
    expect(getDirectory('somefile.cpp'), '');
    expect(getDirectory('path\\somefile.cpp'), 'path\\');
    expect(getDirectory('more\\dirs\\path\\somefile.cpp'), 'more\\dirs\\path\\');
  });

  test('create link prefix', () {
    expect(createParentLinkPrefix('somefile.cpp'), './');
    expect(createParentLinkPrefix('path/somefile.cpp'), '../');
    expect(createParentLinkPrefix('more/dirs/path/somefile.cpp'), '../../../');
    expect(createParentLinkPrefix('path\\somefile.cpp'), '../');
    expect(createParentLinkPrefix('more\\dirs\\path\\somefile.cpp'), '../../../');
  });

  test('report file name 2', () {
    var moo = createReportFileName('input.cpp', 'output', 'html', removeInputExt: false);
    expect(moo, 'output/input.cpp-report.html');
  });
}
