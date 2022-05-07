/// Copyright 2021, domohuhn.
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license

import 'package:mutation_test/mutation_test.dart';
import 'package:args/args.dart';
import 'dart:io';

void main(List<String> arguments) async {
  final help = 'help';
  final generateRules = 'generate-rules';
  final show = 'show-example';
  final rules = 'rules';
  final builtin = 'builtin';
  final verbose = 'verbose';
  final version = 'version';
  final about = 'about';
  final dry = 'dry';
  final output = 'output';
  final format = 'format';
  final quiet = 'quiet';

  final parser = ArgParser()
    ..addFlag(help,
        abbr: 'h',
        help: 'Displays a description of the program',
        negatable: false)
    ..addFlag(version,
        help: 'Prints the version', negatable: false, defaultsTo: false)
    ..addFlag(about,
        help: 'Prints information about the application',
        negatable: false,
        defaultsTo: false)
    ..addFlag(builtin,
        abbr: 'b',
        help: 'Add the builtin ruleset',
        negatable: true,
        defaultsTo: true)
    ..addFlag(show,
        abbr: 's',
        help: 'Prints a XML file to the console with every possible option',
        negatable: false)
    ..addFlag(generateRules,
        abbr: 'g',
        help: 'Prints the builtin ruleset as XML string',
        negatable: false)
    ..addFlag(verbose,
        abbr: 'v', help: 'Verbose output', negatable: false, defaultsTo: false)
    ..addFlag(quiet,
        abbr: 'q',
        help: 'Suppress output to console. Overrides verbose.',
        negatable: false,
        defaultsTo: false)
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
        defaultsTo: 'mutation-test-report')
    ..addOption(format,
        abbr: 'f',
        help: 'Sets the report file format',
        allowed: ['html', 'md', 'xml', 'all', 'none'],
        defaultsTo: 'html')
    ..addMultiOption(rules,
        abbr: 'r',
        help: 'Load the rules from the given XML Document',
        valueHelp: 'path to XML file');

  late ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    handleCommandLineError(parser, e.toString());
  }

  if (argResults[version] as bool) {
    printVersion();
    exit(0);
  }
  if (argResults[about] as bool) {
    printAbout();
    exit(0);
  }
  if (argResults[help] as bool) {
    printVersion();
    printHelp(parser);
    exit(0);
  }
  if (argResults[show] as bool) {
    printExample();
    exit(0);
  }
  if (argResults[generateRules] as bool) {
    printExampleRules();
    exit(0);
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

  var ruleDocuments = argResults[rules];
  var _verbose = argResults[verbose];
  var _quiet = argResults[quiet];

  if (_quiet) {
    _verbose = false;
  }

  var _builtin = (ruleDocuments.isNotEmpty &&
          argResults.wasParsed(builtin) &&
          argResults[builtin]) ||
      (ruleDocuments.isEmpty && argResults[builtin]);
  var mutations = MutationTest(
      argResults.rest, argResults[output], _verbose, argResults[dry], fmt,
      ruleFiles: ruleDocuments, builtinRules: _builtin, quiet: _quiet);

  ProcessSignal.sigint.watch().listen((signal) {
    print('\nReceived system interrupt!');
    mutations.abortMutationTest();
  });

  var foundAll = true;
  try {
    foundAll = await mutations.runMutationTest();
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

void printHelp(var parser) {
  print('''
Usage : mutation-test <options> <input xml or source files...>  
A program that mutates your source code and verifies that the test commands
specified in the input xml files are sensitive to those changes. Mutations
are done as simple text replacements with regular expressions, so any text
file can be mutated. Once one of the files has been mutated, all provided
test commands are run as a separate process. The exit code of these
commands is used to verify that the mutation was detected. If all tests
return the expected return value, then the mutation was undetected and is
added to the results. After all mutations were done, the results will be 
written to the terminal and a report file is generated.
mutation-test is free software, as in "free beer" and "free speech".

mutation-test contains a set of builtin rules, that allow you to start 
testing right away. However, all rules defining the behaviour of this program
can be customized. They are defined in XML documents, and you can change:
  - input files and whitelist lines for mutations
  - compile/test commands, expected return codes and timeouts
  - provide exclusion zones via regular expressions
  - mutation rules as simple text replacement or via regular
    expressions including capture groups
  - the quality gate and quality ratings
You can view a complete example with every possible XML element parsed by 
this program by invoking "mutation-test -s". This will print a XML document to
the standard output. The displayed document also contains comments explaining 
the syntax of the XML file. You can provide multiple input documents for a 
single program start. The inputs are split into three categories:
  - xml rules documents: The mutation rules for all other files are parsed
    from these documents and added globally. Rules are specified via "--rules".
  - xml documents: These files will be parsed like the rules documents, but
    anything defined in them applies only inside this document. 
  - all other input files
If a rules file is provided via the command line flag "--rules", then the
builtin rules are disabled, unless you specifically add them by passing "-b".
You can provide as many rule sets as you like, and all of them will be added
globally. The rest of the input files is processed individually. If the file 
extension is ".xml", then the file will be parsed like an additional rules file.
However, this document must have a <files> element that lists all mutation
targets. Any other file is interpreted as mutation target and processed with 
the rules from the documents provided via "--rules". 

The rules documents and the input xml files use the same syntax, so both 
files may define mutation rules, inputs, exclusions or test commands.
However, a quality threshold may only be defined once. 


Options:''');
  print(parser.usage);
}

void printUsage(var parser, [int exitCode = 0]) {
  print('''
Usage : mutation-test <options> <input xml or source files...>  
Options:''');
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

void printVersion() {
  print(mutationTestVersion());
}

void printAbout() {
  printVersion();
  print(createLicenseText());
  exit(0);
}
