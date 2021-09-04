import 'package:mutation_test/mutation-test.dart';
import 'package:args/args.dart';
import 'dart:io';

void main(List<String> arguments) async {
  final help = 'help';
  final generate_rules = 'generate-rules';
  final show = 'show-example';
  final rules = 'rules';
  final builtin = 'no-builtin';
  final verbose = 'verbose';
  final dry = 'dry';
  final output = 'output';
  final format = 'format';

  final parser = ArgParser()
    ..addFlag(help, abbr: 'h', help: 'Displays this text', negatable: false)
    ..addFlag(builtin, abbr: 'n', help: 'Removes the builtin ruleset - has no effect in combination with -r', negatable: false)
    ..addFlag(show, abbr: 's', help: 'Prints a XML file to the console with every possible option', negatable: false)
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
            'Overrides the builtin ruleset with the rules in the given XML Document',
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
  if (argResults[show] as bool) {
    printExample();
  }
  if (argResults[generate_rules] as bool) {
    printExampleRules();
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
      var result = await runMutationTest(
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
  print('All options and rules are read from the specified XML files.\n');
  print('The rules file and the input files use the same syntax, so both files may define\nmutation rules, inputs, exclusions or test commands.\n\n');
  print('Options:');
  print(parser.usage);
  exit(exitCode);
}

void printExample() {
  print(fullXMLFile());
  exit(0);
}

void printExampleRules() {
  print(builtinMutationRules());
  exit(0);
}
