import 'package:mutation_test/mutation_test.dart';
import 'package:args/args.dart';
import 'dart:io';

void main(List<String> arguments) {

  final help = 'help';
  final example = 'example';
  final verbose = 'verbose';
  final dry = 'dry';
  final output = 'output';

  final parser = ArgParser()
    ..addFlag(help, abbr: 'h', help: 'Displays this text', negatable: false)
    ..addFlag(example, abbr: 'e', help: 'Shows a simple XML configuration file tha can be used as input', negatable: false)
    ..addFlag(verbose, abbr: 'v', help: 'Verbose output', negatable: false, defaultsTo: false)
    ..addFlag(dry, abbr: 'd', help: 'Dry run - loads the configuration and checks all files, but runs no tests', negatable: false, defaultsTo: false)
    ..addOption(output, abbr: 'o', help: 'Sets the output directory', valueHelp: 'directory', defaultsTo: '.');

  late ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    handleCommandLineError(parser,e.toString());
  }

  if (argResults[help] as bool) {
    printUsage(parser);
  }
  if (argResults[example] as bool) {
    printExample();
  }

  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    handleCommandLineError(parser,e.toString());
  }

  var foundAll = true;
  try {
    for (final file in argResults.rest) {
      var result = runMutationTest(file, argResults[output], argResults[verbose], argResults[dry]);
      foundAll = result && foundAll;
    }
  } catch (e) {
    handleProcessingError(e.toString());
  }
  if(!foundAll) {
    exit(-1);
  }
  exit(0);
}

void handleCommandLineError(var parser, [String errorMessage = '']) {
  if (errorMessage != '') {
    print('Error while parsing command line arguments:\n  '+errorMessage);
  }
  printUsage(parser,2);
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
