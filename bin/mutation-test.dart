import 'package:mutation_test/mutation-test.dart';
import 'package:args/args.dart';
import 'dart:io';

void main(List<String> arguments) {
  final help = 'help';
  final generate_rules = 'generate-rules';
  final rules = 'rules';
  final verbose = 'verbose';
  final dry = 'dry';
  final output = 'output';
  final format = 'format';

  final parser = ArgParser()
    ..addFlag(help, abbr: 'h', help: 'Displays this text', negatable: false)
    ..addFlag(generate_rules,
        abbr: 'g',
        help: 'Prints the builtin ruleset as XML string',
        negatable: false)
    ..addFlag(verbose,
        abbr: 'v', help: 'Verbose output', negatable: false, defaultsTo: false)
    ..addFlag(dry,
        abbr: 'd',
        help:
            'Dry run - loads the configuration and counts the possible mutations in all files, but runs no tests',
        negatable: false,
        defaultsTo: false)
    ..addOption(output,
        abbr: 'o',
        help: 'Sets the output directory',
        valueHelp: 'directory',
        defaultsTo: '.')
    ..addOption(format,
        abbr: 'f',
        help: 'Sets the report file format',
        allowed: ['html', 'md', 'xml', 'all', 'none'],
        defaultsTo: 'html')
    ..addOption(rules,
        abbr: 'r',
        help:
            'Overrides the builtint ruleset with the rules in the given XML Document',
        valueHelp: 'path to XML file');

  late ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    handleCommandLineError(parser, e.toString());
  }

  if (argResults[help] as bool) {
    printUsage(parser);
  }
  if (argResults[generate_rules] as bool) {
    printExample();
  }

  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    handleCommandLineError(parser, e.toString());
  }

  if (argResults.rest.isEmpty) {
    print('No input files present!');
    printUsage(parser);
  }

  var reportFormatStr = argResults[format];
  var fmt = ReportFormat.NONE;
  if (reportFormatStr == 'html') {
    fmt = ReportFormat.HTML;
  } else if (reportFormatStr == 'md') {
    fmt = ReportFormat.MARKDOWN;
  } else if (reportFormatStr == 'xml') {
    fmt = ReportFormat.XML;
  } else if (reportFormatStr == 'none') {
    fmt = ReportFormat.NONE;
  } else if (reportFormatStr == 'all') {
    fmt = ReportFormat.ALL;
  } else {
    print('Unsupported output format: $reportFormatStr');
    printUsage(parser);
  }

  var foundAll = true;
  try {
    for (final file in argResults.rest) {
      var result = runMutationTest(
          file, argResults[output], argResults[verbose], argResults[dry], fmt,
          ruleFile: argResults[rules]);
      foundAll = result && foundAll;
    }
  } catch (e) {
    handleProcessingError(e.toString());
  }
  if (!foundAll) {
    exit(-1);
  }
  exit(0);
}

void handleCommandLineError(var parser, [String errorMessage = '']) {
  if (errorMessage != '') {
    print('Error while parsing command line arguments:\n  ' + errorMessage);
  }
  printUsage(parser, 2);
}

void handleProcessingError([String errorMessage = '']) {
  print('Error while processing:\n  $errorMessage');
  exit(1);
}

void printUsage(var parser, [int exitCode = 0]) {
  print('\nUsage : mutation-test <options> <input xml file>\n');
  print('A program that runs mutation tests on your source code and checks the results.');
  print('All options and rules are read from the specified XML file.\n\n');
  print('Options:');
  print(parser.usage);
  exit(exitCode);
}

void printExample() {
  print('''<?xml version="1.0" encoding="UTF-8"?>
<mutations version="1.0">
  <files>
    <file>example/source.dart</file>
  </files>
  <rules>
    <pattern text="&#38;&#38;">
      <mutation text="||"/>
      <mutation text="&#38;&#38; !"/>
    </pattern>
    <pattern text="||">
      <mutation text="&#38;&#38;"/>
    </pattern>
    <pattern text="+">
      <mutation text="-"/>
      <mutation text="*"/>
    </pattern>
    <pattern text="-">
      <mutation text="+"/>
      <mutation text="*"/>
    </pattern>
    <pattern text="*">
      <mutation text="+"/>
      <mutation text="-"/>
    </pattern>
    <pattern text="/">
      <mutation text="*"/>
      <mutation text="+"/>
    </pattern>
  </rules>
  <commands>
    <command name="make" group="compile" expected-return="0" working-directory=".">make -j4</command>
    <command name="ctest" group="test" expected-return="0" working-directory=".">ctest -j4</command>
  </commands>
</mutations>
''');
  exit(0);
}
