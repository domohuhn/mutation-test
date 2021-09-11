/// Copyright 2021, domohuhn. 
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license
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
  final version = 'version';
  final about = 'about';
  final dry = 'dry';
  final output = 'output';
  final format = 'format';

  final parser = ArgParser()
    ..addFlag(help, abbr: 'h', help: 'Displays a description of the program', negatable: false)
    ..addFlag(version, help: 'Prints the version', negatable: false, defaultsTo: false)
    ..addFlag(about, help: 'Prints information about the application', negatable: false, defaultsTo: false)
    ..addFlag(builtin, abbr: 'n', help: 'Removes the builtin ruleset - has no effect in combination with -r', negatable: false)
    ..addFlag(show, abbr: 's', help: 'Prints a XML file to the console with every possible option', negatable: false)
    ..addFlag(generate_rules,abbr: 'g',help: 'Prints the builtin ruleset as XML string',negatable: false)
    ..addFlag(verbose,abbr: 'v', help: 'Verbose output', negatable: false, defaultsTo: false)
    ..addFlag(dry,abbr: 'd',help:'Dry run - loads the configuration and counts the possible mutations in all files, but runs no tests', negatable: false, defaultsTo: false)
    ..addOption(output, abbr: 'o', help: 'Sets the output directory', valueHelp: 'directory', defaultsTo: '.')
    ..addOption(format, abbr: 'f', help: 'Sets the report file format', allowed: ['html', 'md', 'xml', 'all', 'none'], defaultsTo: 'html')
    ..addMultiOption(rules, abbr: 'r', help: 'Overrides the builtin ruleset with the rules in the given XML Document', valueHelp: 'path to XML file');

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
  }
  if (argResults[help] as bool) {
    printVersion();
    printHelp(parser);
  }
  if (argResults[show] as bool) {
    printExample();
  }
  if (argResults[generate_rules] as bool) {
    printExampleRules();
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

  ProcessSignal.sigint.watch().listen((signal) {
    print('Received system interrupt!');
    abortMutationTest();
  });

  var foundAll = true;
  try {
    for (final file in argResults.rest) {
      var result = await runMutationTest(
          file, argResults[output], argResults[verbose], argResults[dry], fmt,
          ruleFiles: argResults[rules],
          addBuiltin: !argResults[builtin]);
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

mutation-test contains a set of builtin rules, that allow you to start 
testing right away. However, all rules defining the behaviour of this program
can be customized. It is defined in XML documents, and you can change:
  - input files and whitelist lines for mutations
  - compile/test commands, expected return codes and timeouts
  - provide exclusion zones via regular expressions
  - mutation rules as simple text replacement or via regular
    expressions including capture groups
You can view a complete example with every possible XML element parsed by 
this program by running "mutation-test -s". The printed document also 
contains comments explaining the syntax of the XML file. You can provide multiple
input documents for a single program start. The inputs are split into three 
categories:
  - a rules xml document
  - xml documents
  - all other input files
If a rules file is provided via the option "--rules", then the builtin mutation
rules are disabled. Instead, the provided rules document will be used. The rest
of the input files is processed individually. If the file extension is ".xml", 
then the file will be parsed as additional rules file. The rules from both files
are applied to all files listed in the <files> elements. At most the rules from 
2 files are used for a single mutation test run. Any other file is interpreted 
as mutation target and processed with the rules from the documents provided via
 "--rules". The rules files and the input xml files use the same syntax, so both 
files may define mutation rules, inputs, exclusions or test commands.

mutation-test is free software, as in "free beer" and "free speech".

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
  print('''Copyright 2021, domohuhn. 

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the name of the copyright holder nor the names of its 
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.''');
  exit(0);
}
