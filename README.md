# Mutation testing

[![Dart](https://github.com/domohuhn/mutation-test/actions/workflows/dart.yml/badge.svg)](https://github.com/domohuhn/mutation-test/actions/workflows/dart.yml)

When writing test cases for software, you often rely on metrics like
code coverage to verify that your test cases actually test your program.
However, this cannot be determined with a simple metric. It is possible to reach high code coverage, while you are only asserting a fraction of the observable behaviour of your units. You can evaluate your tests by modifying your program in a small way and the verify that your tests are sensitive to that change. This process is called [Mutation testing](https://en.wikipedia.org/wiki/Mutation_testing).

This repository contains a simple command line program that automate these tests on any code. It can be customized to 
your needs, because all rules on how to modify the source code and
run the tests are defined in XML documents. The program is fully self contained, so just grab the binary and start testing!
```bash
# Run the tests in directory "example":
mutation-test example/config.xml
# or fully configured
mutation-test -f md -o output --rules mutation-rules.xml inputset1.xml inputset2.xml
```
## Features
  - Fully configurable mutation rules via XML documents and regular expressions
  - Sections of files can be whitelisted on a per file basis
  - You can add global exclusion rules for e.g. comments, loop conditions via regular expressions
  - Different report formats are supported: html, markdown and XML

## A brief description of the program
mutation-test is a program that mutates your source code and verifies that the test commands
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
input documents for a single program start. The inputs are split into two categories:

  - a rules file
  - all other input files

If a rules file is provided via the option "--rules", then the builtin mutation
rules are disabled. Instead, the provided rules document will be used. The rest
of the input files is processed individually, so at most the rules from 2 files
are loaded. 
The rules file and the input files use the same syntax, so both files may define
mutation rules, inputs, exclusions or test commands.

## Reports
After a input file is processed, a report is generated. You can choose multiple output formats for the reports. As default, a html file is generated, but you can also choose markdown or XML. You can see examples
for the produced outputs in the [example folder](example/config-report.md).

## Input XML documents

This chapter explains the structure of the input XML documents. They must use the following structure:
```Xml
<?xml version="1.0" encoding="UTF-8"?>
<mutations version="1.0">
    <files>
    ...
    </files>
    <commands>
    ...
    </commands>
    <exclude>
    ...
    </exclude>
    <rules>
    ...
    </rules>
</mutations>
```
You can see an example for an input document in the example folder, or the application can generate one by running one of these commands:
```bash
# Shows a XML document with the complete syntax:
mutation-test -s
# Shows the builtin mutation rules and exclusions:
mutation-test -g
```
The generated documents also contain some helpful comments on how to create your own rules. You should usually provide two different documents: one with the mutation rules given as argument to "-r" and another one with the input files. The reason why mutation-test always loads two files (unless you disable the builtin ruleset via "--no-builtin" and don't provide your own rules file) is that you can reuse the same set of rules for many different input files.

### Files
The children of "files" elements are individual files:
```Xml
<files>
    <file>example/source.dart</file>
    <file>example/source2.dart
    <!-- lines can be whitelisted  -->
    <!-- if there is no whitelist, the whole file is used  -->
    <!-- line index starts at 1  -->
    <lines begin="13" end="24"/>
    <lines begin="29" end="35"/>
    </file>
</files>
```
The application will perform the mutation tests in sequence on the listed files. All mutations that are not in an exclusion or inside a whitelisted area will be applied.
### Commands
The commands block lets you specify the command line programs to verify that a mutation is detected. The commands are run in document sequence and must be each a single command line call.
```Xml
<!-- Specify the test commands here with the command element -->
<!-- The text of the command element will be executed as shell process -->
<!-- The return value of the command will used to check for success -->
<!-- If all commands execute successfully, a mutation counts as undetected -->
<commands>
  <!-- All attributes here are optional -->
  <!-- name: is used to show statistics for the commands -->
  <!-- group: is used to show statistics for the commands -->
  <!-- expected-return: this value is compared to the return value of the command. Must be an integer -->
  <!-- working-directory: Where the program is executed. Defaults to . -->
  <!-- tiemout: Timeout in seconds. Must be an integer. If not present, the commands will run until they are finished. -->
  <command name="make" group="compile" expected-return="0" working-directory=".">make -j8</command>
  <command name="ctest" group="test" expected-return="0" working-directory="." timeout="10">ctest -j8</command>
</commands>
```
### Exclude
You can create rules to exclude protions of the source files from mutations:
```Xml
<exclude>
  <!-- excludes anything between two tokens  -->
  <token begin="//" end="\n"/>
  <token begin="#" end="\n"/>
  <!-- excludes anything that matches a pattern  -->
  <regex pattern="/[*].*?[*]/" dotAll="true"/>
  <!-- exclude loops to prevent infinte tests -->
  <regex pattern="[\s]for[\s]*\(.*?\)[\s]*{" dotAll="true"/>
  <regex pattern="[\s]while[\s]*\(.*?\)[\s]*{.*?}" dotAll="true"/>
  <!-- lines can also be globally excluded  -->
  <!-- line index starts at 1  -->
  <!-- lines begin="1" end="2"/-->
</exclude>
```
### Rules
This element is the most important part of the document. It defines what is mutated, and how it is changed.
```Xml
<!-- The rules element describes all mutations done during a mutation test -->
<!-- The following children are parsed: literal and regex -->
<!-- A literal element matches the literal text -->
<!-- A regex element mutates source code if the regular expression matches -->
<!-- Each of them must have at least one mutation child -->
<rules>
  <!-- A literal element matches the literal text and replaces it with the list of mutations  -->
  <!-- This will replace any "+" with "-" or "*". -->
  <literal text="+">
    <mutation text="-"/>
    <mutation text="*"/>
  </literal>
  <!-- It is also possible to match a regular expression with capture groups. -->
  <!-- If the optional attribute dotAll is set to true, then the . will also match newlines.  -->
  <!-- If not present, the default value for dotAll is false.  -->
  <!-- Here, we capture everything inside of the braces of "if ()" -->
  <regex pattern="[\s]if[\s]*\((.*?)\)[\s]*{" dotAll="true">
    <!-- You can access groups via $1. -->
    <!-- If your string contains a $ followed by a number that should not be replaced, escape the dollar \$ -->
    <!-- If your string contains a \$ followed by a number that should not be replaced, escape the slash \\$ -->
    <!-- Tabs and newlines should also be escaped. -->
    <mutation text=" if (!($1)) {"/>
  </regex>
</rules>
```
### Table of XML elements

Here is a table of all XML elements that are parsed by this program:

| Element   | Children                        | Attributes  | Description |
| --------- | ------------------------------- | ----------- | ----------- |
| mutations | files, rules, exclude, commands | version     | Top level element |
| files     | file                            |             | Holds the list of files to mutate |
| exclude   | token, regex, lines             |             | Holds the list of exclusions from mutations. |
| commands  | command                         |             | Holds the list of commands to run |
| rules     | literal, regex                  |             | Holds the list of mutation rules |
| file      | lines                           |             | Contains the path the to file as text. If there are lines children present, only the given lines are mutated. |
| lines     |                                 | begin, end  | Specifies an interval of lines \[begin,end\] in the source file. |
| command   |                                 | name, group, expected-return, timeout      | Contains the command to execute as text. All attributes are optional. |
| token     |                                 | begin, end  | A range in the source file delimited by the begin and end tokens. |
| literal   | mutation                        | text        | Matches the string in attribute text and replaces it with its children. |
| regex     | mutation                        | pattern, dotAll | A pattern for a regular expression. The expression is always multiline and processes the complete file. You can use "." to match newlines if the optional attribute dotAll is set to true. |
| mutation  |                                 | text        | A replacement for a match. If this element is a child of a regex node, then capture groups can be used in the text via $i. |

## Command line arguments

```bash
mutation-test <options> <input xml files...>
```
The program accepts the following command line arguments:

| Short          | Long                      | Description                                                                                               |
| -------------- | ------------------------- | --------------------------------------------------------------------------------------------------------- |
| -h             | --help                    | Displays the help message                                                                                 |
|                | --version                 | Prints the version                                                                                        |
|                | --about                   | Prints information about the application                                                                  |
| -n             | --no-builtin              | Removes the builtin ruleset - has no effect in combination with -r                                        |
| -s             | --show-example            | Prints a XML file to the console with every possible option                                               |
| -g             | --generate-rules          | Prints the builtin ruleset as XML string                                                                  |
| -v             | --verbose                 | Verbose output                                                                                            |
| -d             | --dry                     | Dry run - loads the configuration and counts the possible mutations in all files, but runs no tests       |
| -o             | --output=<directory>      | Sets the output directory (defaults to ".")                                                               |
| -f             | --format                  | Sets the report file format [html (default), md, xml, all, none]                                          |
| -r             | --rules=<path to XML file>| Overrides the builtin ruleset with the rules in the given XML Document                                    |

The rest are excepted to be paths to input XML configuration files.

## License
mutation-test is free software, as in "free beer" and "free speech". 
All Code is licensed with the BSD-3-Clause license, see file "LICENSE"

