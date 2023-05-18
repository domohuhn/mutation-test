// Copyright 2021, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/core/mutated_line.dart';
import 'package:mutation_test/src/reports/file_mutation_results.dart';
import 'package:mutation_test/src/reports/report_data.dart';
import 'package:mutation_test/src/core/system_interactions.dart';
import 'package:mutation_test/src/version.dart';
import 'package:mutation_test/src/reports/string_helpers.dart';

/// Writes the results of the tests to a html file in directory [outpath].
/// The report will be named like the [input], but ending with "-report.html".
/// [data] holds the results of the test run that will be formatted to html
/// documents.
///
/// [system] is used to make the file system interactions testable.
void writeHTMLReport(
    String outpath, String input, ReportData data, SystemInteractions system) {
  var index = createToplevelHtmlFile(data);
  var fname =
      createReportFileName(inputFileOrDefaultName(input), outpath, 'html');
  system.createPathsAndWriteFile(fname, index);
  data.testedFiles.forEach((key, value) {
    var contents = createSourceHtmlFile(data, value, basename(fname));
    var sname = createReportFileName(key, outpath, 'html',
        appendReport: false,
        removeInputExt: false,
        removePathsFromInput: false);
    system.createPathsAndWriteFile(sname, contents);
  });
}

/// Creates the contents of the top level navigation file.
/// [reporter] holds the results of the test run that will be formatted to html
/// documents.
String createToplevelHtmlFile(ReportData reporter) {
  final rv = StringBuffer(createHtmlFileHeader(
      reporter,
      'top level',
      reporter.totalMutations,
      reporter.foundMutations,
      reporter.totalTimeouts,
      true,
      ''));
  rv.write('''
<center>
<table width ="80%" cellspacing="1" border="0">
     <tbody>
     <tr><td width="60%"></td><td width="10%"></td><td width="10%"></td><td width="10%"></td><td width="10%"></td></tr>
     <tr><td class="ItemHead" width="60%">Path</td><td class="ItemHead" width="30%" colspan="3">Detection rate</td><td class="ItemHead" width="10%">Timeouts</td></tr>
''');
  reporter.testedFiles.forEach((key, value) {
    rv.write(createFileReportLine(
        key, value.mutationCount, value.detectedCount, value.timeoutCount));
  });

  rv.write('''
    </tbody>
</table>
</center>


''');
  rv.write(createHtmlFooter());
  return rv.toString();
}

String removeNewline(String s) {
  if (s.endsWith('\n') || s.endsWith('\r')) {
    return s.substring(0, s.length - 1);
  } else if (s.endsWith('\r\n')) {
    return s.substring(0, s.length - 2);
  }
  return s;
}

String _createMutationReportList(
    int line, List<MutatedLine> mutations, String title) {
  final rv = StringBuffer(
      '<b>$title</b>\n<table class="mutationTable" width="100%">\n');
  int i = 1;
  for (final mut in mutations) {
    if (line == mut.line) {
      if (i > 1) rv.write('<tr><td colspan="3"><hr class="ruler"/></td></tr>');

      rv.write('<tr><td class="mutationLabel" width="5%">$i :</td>');

      rv.write('<td class="mutationText" width="87%">'
          '${mut.formatMutatedCodeToHTML()}</td>');

      rv.write('<td class="match">${mut.mutation.pattern}');
      if (mut.mutation.id != null) {
        rv.write('<span class="tooltip">Id: ${mut.mutation.id}</span>');
      }
      rv.write('</td></tr>');

      ++i;
    }
  }
  rv.write('</table>\n');
  return rv.toString();
}

String createMutationList(int line, FileMutationResults file) {
  final rv = StringBuffer('');
  if (file.lineHasUndetectedMutation(line)) {
    rv.write(_createMutationReportList(
        line, file.undetectedMutations, 'Undetected mutations:'));
  }
  if (file.lineHasDetectedMutation(line)) {
    rv.write(_createMutationReportList(
        line, file.detectedMutations, 'Detected mutations:'));
  }
  if (file.lineHasTimeoutMutation(line)) {
    rv.write(_createMutationReportList(
        line, file.timeoutMutations, 'Mutations that caused a time out:'));
  }
  return rv.toString();
}

/// Creates the contents of the top level navigation file.
/// [reporter] holds the results of the test run that will be formatted to html
/// documents.
/// [file] holds the data of the current file.
/// [toplevelFileName] is used to creat a link back to the top level file.
String createSourceHtmlFile(
    ReportData reporter, FileMutationResults file, String toplevelFileName) {
  final rv = StringBuffer(createHtmlFileHeader(
      reporter,
      file.path,
      file.mutationCount,
      file.detectedCount,
      file.timeoutCount,
      false,
      toplevelFileName));
  rv.write(
      '<pre class="fileHeader">          Source code</pre>\n<pre class="fileContents">\n');
  var i = 1;
  for (final src in file.contents.split('\n')) {
    final fmtln = escapeCharsForHtml(removeNewline(src));
    if (file.lineHasMutation(i)) {
      final colorClass = file.lineHasProblem(i) ? 'problem' : 'hit';
      rv.write(
          '''<a name="$i"><button class="collapsible $colorClass"><pre class="fileContents"><span class="lineNumber">${i.toString().padLeft(8)} </span>$fmtln</pre></button>
<div class="content">
${createMutationList(i, file)}
</div></a>''');
    } else {
      rv.write(
          '<a name="$i"><span class="lineNumber">${i.toString().padLeft(8)} </span>$fmtln</a>\n');
    }
    ++i;
  }
  rv.write('</pre>\n');
  rv.write('''
<script>
var coll = document.getElementsByClassName("collapsible");
var i;

for (i = 0; i < coll.length; i++) {
  coll[i].addEventListener("click", function() {
    this.classList.toggle("active");
    var content = this.nextElementSibling;
    if (content.style.maxHeight){
      content.style.maxHeight = null;
    } else {
      content.style.maxHeight = content.scrollHeight + "px";
    }
	for (k = 0; k < coll.length; k++) {
      var content2 = coll[k].nextElementSibling;
      if (content2.style.maxHeight && content.parentElement == content2){
      content2.style.maxHeight = content2.scrollHeight + content.scrollHeight + "px";
    }
      
    }
    
  });
}
</script>''');
  rv.write(createHtmlFooter());
  return rv.toString();
}

String selectColor(double pct) {
  if (pct >= 80.0) {
    return 'ItemReportHigh';
  } else if (pct >= 50.0) {
    return 'ItemReportMedium';
  } else {
    return 'ItemReportLow';
  }
}

String selectBarColor(double pct) {
  if (pct >= 80.0) {
    return 'barHi';
  } else if (pct >= 50.0) {
    return 'barMed';
  } else {
    return 'barLo';
  }
}

String createHtmlFileHeader(ReportData reporter, String current, int total,
    int detected, int timeouts, bool isToplevel, String toplevelFileName) {
  var detectedFraction = total > 0 ? 100.0 * detected / total : 100.0;
  var timeoutFraction = total > 0 ? 100.0 * timeouts / total : 0.0;
  var locationText = current;
  if (!isToplevel) {
    locationText +=
        ' - <a href="${createParentLinkPrefix(current)}$toplevelFileName">back to top</a>';
  }
  final rv = StringBuffer('''
<!DOCTYPE html>
<html lang="en">
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
''');
  rv.write(getCSSFileContents());
  rv.write('</style>\n</head>\n<body>\n');
  rv.write('''
<table width ="100%" cellspacing="0" border="0">
    <tr><td class="title">Mutation test report</td></tr>
     <tr><td><hr class="ruler"/></td></tr>

     <tr>
     <td width="100%">
     <table width="100%" cellpadding="1" border="0">
     <tbody><tr>
     <td class="ItemLabel" width="10%">Current display:</td>
     <td class="ItemText" width="35%">$locationText</td>
     <td width="10%"></td>
     <td class="MiddleHeader" width="15%">Detected</td>
     <td class="MiddleHeader" width="15%">Total</td>
     <td class="MiddleHeader" width="15%">Percentage</td>
     </tr>

     <tr>
     <td class="ItemLabel" width="10%">Date:</td>
     <td class="ItemText" width="35%">${DateTime.now()}</td>
     <td class="ItemLabel" width="10%">Mutations:</td>
     <td class="ItemReport" width="15%">$detected</td>
     <td class="ItemReport" width="15%">$total</td>
     <td class="${selectColor(detectedFraction)}" width="15%">${detectedFraction.toStringAsFixed(1)} %</td>
     </tr>
     
     <tr>
     <td class="ItemLabel" width="10%">Builtin rules:</td>
     <td class="ItemText" width="35%">${reporter.builtinRulesAdded}</td>
     <td class="ItemLabel" width="10%">Timeouts:</td>
     <td class="ItemReport" width="15%">$timeouts</td>
     <td class="ItemReport" width="15%">$total</td>
     <td class="${selectColor(100.0 - timeoutFraction)}" width="15%">${timeoutFraction.toStringAsFixed(1)} %</td>
     </tr>
''');
  if (isToplevel) {
    rv.write('''
     <tr>
     <td class="ItemLabel" width="10%">Quality rating:</td>
     <td class="ItemText" width="35%">${reporter.rating}</td>
     <td class="ItemLabel" width="10%">Success:</td>
     <td class="ItemText" width="15%">${reporter.success}</td>
     <td class="ItemText" width="15%"></td>
     <td class="ItemText" width="15%"></td>
     </tr>
  ''');
  }

  rv.write('''
     </tbody>
     </table>
     </td>
     </tr>
     

     
     <tr><td><hr class="ruler"/></td></tr>
</table>

''');

  return rv.toString();
}

String createFileReportLine(
    String path, int mutations, int detected, int timeouts) {
  var percentage = mutations > 0 ? 100.0 * detected / mutations : 100.0;
  var timeoutpct = mutations > 0 ? 100.0 * timeouts / mutations : 0.0;
  return '''
<tr><td class="FileLink" width="60%"><a href="$path.html">$path</a></td>
  <td class="ItemReport" width="10%">
  <table width="100%" cellpadding="0" border="1"><tr>
    <td class="${selectBarColor(percentage)}" width="$percentage%" height="10"></td>
    <td class="barBg" width="${100.0 - percentage}%" height="10"></td>
  </tr></table>
  </td>
  <td class="${selectColor(percentage)}" width="10%">${percentage.toStringAsFixed(1)} %</td>
  <td class="${selectColor(percentage)}" width="10%">$detected / $mutations</td>
  <td class="${selectColor(100.0 - timeoutpct)}" width="10%">$timeouts / $mutations</td>
</tr>
''';
}

String createHtmlFooter() {
  return '''
<table width ="100%" cellspacing="0" border="0">
  <tr><td><hr class="ruler"/></td></tr>
  <tr><td class="footer">Generated by ${mutationTestVersion()}</td></tr>
</table>
</body>
</html>
''';
}

/// Creates the CSS file contents for the HTML reporting.
String getCSSFileContents() {
  return '''
.collapsible {
  color: black;
  cursor: pointer;
  padding: 0px;
  width: 100%;
  border: none;
  text-align: left;
  outline: none;
}

.hit {
  background-color: #DAE7FE;
}

.hit:hover {
  color: white;
  background-color: #6688D4;
}

.problem {
  background-color: #FF6230;
}

.problem:hover {
  background-color: #FF0000;
}

span.lineNumber
{
  display: inline-block;
  color: black;
  background-color: #EFE383;
}

.addedLine {
background-color: rgb(200, 255, 200)
}
.changedTokens {
background-color: rgb(50, 255, 50)
}

pre
{
  font-family: monospace;
  white-space: pre;
}

pre.fileContents
{
  margin: 0px;
}

.content {
  padding: 0 18px;
  max-height: 0;
  overflow: hidden;
  transition: max-height 0.5s ease-out;
  background-color: #f1f1f1;
}
table{
    border-collapse: collapse;
}

hr.ruler
{
  height:3px;
  border-width:0;
  color:#6688D4;
  background-color:#6688D4
}
td.title
{
  text-align: center;
  padding-bottom: 10px;
  font-family: Helvetica, sans-serif;
  font-size: 20pt;
  font-style: italic;
  font-weight: bold;
}
td.footer {
  text-align: center;
  padding-bottom: 10px;
  font-family: Helvetica, sans-serif;
  font-size: 12pt;
}

td.ItemLabel
{
  text-align: right;
  padding-right: 6px;
  font-family: sans-serif;
  font-weight: bold;
  vertical-align: top;
  white-space: nowrap;
}

td.mutationLabel
{
  text-align: right;
  padding-right: 6px;
  font-weight: bold;
  vertical-align: top;
}

td.mutationText
{
  text-align: left;
  vertical-align: top;
}

td.ItemText
{
  text-align: left;
  padding-right: 6px;
  font-family: sans-serif;
  font-weight: bold;
  color:#6688D4;
  white-space: nowrap;
}

td.ItemReport
{
  text-align: right;
  color: #284FA8;
  font-family: sans-serif;
  font-weight: bold;
  white-space: nowrap;
  padding-left: 6px;
  padding-right: 6px;
  background-color: #DAE7FE;
  border-collapse: unset;
  border: 2px;
  border-color: white;
  border-style: solid;
}

td.FileLink
{
  text-align: left;
  color: #284FA8;
  font-family: sans-serif;
  font-weight: bold;
  white-space: nowrap;
  padding-left: 6px;
  padding-right: 6px;
  background-color: #DAE7FE;
  border-collapse: unset;
  border: 2px;
  border-color: white;
  border-style: solid;
}

td.ItemReportHigh
{
  text-align: right;
  color: black;
  font-family: sans-serif;
  font-weight: bold;
  white-space: nowrap;
  padding-left: 6px;
  padding-right: 6px;
  background-color: #A7FC9D;
  border-collapse: unset;
  border: 2px;
  border-color: white;
  border-style: solid;
}

td.ItemReportMedium
{
  text-align: right;
  color: black;
  font-family: sans-serif;
  font-weight: bold;
  white-space: nowrap;
  padding-left: 6px;
  padding-right: 6px;
  background-color: #FFEA20;
  border-collapse: unset;
  border: 2px;
  border-color: white;
  border-style: solid;
}

td.ItemReportLow
{
  text-align: right;
  color: black;
  font-family: sans-serif;
  font-weight: bold;
  white-space: nowrap;
  padding-left: 6px;
  padding-right: 6px;
  background-color: #FF0000;
  border-collapse: unset;
  border: 2px;
  border-color: white;
  border-style: solid;
}

td.MiddleHeader
{
  text-align: center;
  padding-right: 6px;
  padding-left: 6px;
  font-family: sans-serif;
  white-space: nowrap;
}

td.ItemHead
{
  text-align: center;
  color: white;
  font-family: sans-serif;
  font-weight: bold;
  white-space: nowrap;
  padding-left: 6px;
  padding-right: 6px;
  background-color: #6688D4;
  border-collapse: unset;
  border: 1px;
  border-color: white;
  border-style: solid;
}

td.barHi
{
  background-color: #00eb00;
}

td.barMed
{
  background-color: #FFEA20;
}

td.barLo
{
  background-color: #ff0000;
}

td.barBg
{
  background-color: #FFFFFF;
}

.match {
  text-align: right;
  position: relative;
}

.match .tooltip {
  visibility: hidden;
  background-color: #bbb;
  color: black;
  text-align: center;
  border-radius: 6px;
  padding: 5px 5px;
  position: absolute;
  z-index: 1;
  top: 100%;
  right: 0%;
}

.match:hover .tooltip {
  visibility: visible;
}

@media (prefers-color-scheme: dark) {
  body {
    color: #c9d1d9;
    background: #141517;
  }
  td.ItemReport, td.FileLink, td.ItemReportHigh, td.ItemReportMedium, td.ItemReportLow, td.ItemHead {
    border-color: #152035;
  }
  td.ItemReport, td.FileLink {
    color: #DAE7FE;
    background-color: #141517;
  }
  td.ItemReportHigh, td.ItemReportMedium, td.ItemReportLow, td.barBg {
    background-color: #141517;
  }
  td.ItemReportHigh {
    color: #A7FC9D;
  }
  td.ItemReportMedium {
    color: #FFEA20;
  }
  td.ItemReportLow {
    color: #FF0000;
  }
  span.lineNumber {
    color: white;
    background-color: #26334F;
  }
  .collapsible {
    color: #c9d1d9;
  }
  .content {
    color: #c9d1d9;
    background-color: #1B2539;
  }
  .hit {
    background-color: #26334F;
  }
  .addedLine {
    background-color: rgb(37, 83, 37);
  }
  .changedTokens {
    background-color: rgb(32, 145, 32);
  }
  .problem {
    background-color: #62200B;
  }
  a:link, a:visited  {
	  color: #58a6ff;
	}
  
  .match .tooltip {
    background-color: black;
    color: #fff;
  }
}

''';
}
