// Copyright 2021, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:xml/xml.dart' as xml;
import 'package:mutation_test/src/core/core.dart';
import 'package:mutation_test/src/reports/ratings.dart';

/// A structure holding the information about the mutation input.
class TargetFile {
  String path;
  List<Range> whitelist;
  TargetFile(this.path, this.whitelist);
}

/// Reads the xml configuration file
class Configuration {
  /// The list of source files that will be mutated
  List<TargetFile> files;

  /// The list files that are excluded
  List<String> excludedFiles;

  /// The mutation rules added from the rules
  List<Mutation> mutations;

  /// The commands to execute to detect mutations
  List<Command> commands;

  /// Lists the excluded sections in files
  List<Range> exclusions;

  Ratings ratings;
  bool dry;
  bool topLevelFound = false;
  SystemInteractions system;

  Configuration(this.system, this.dry)
      : files = [],
        excludedFiles = [],
        mutations = [],
        commands = [],
        exclusions = [],
        ratings = Ratings();

  /// Constructs the configuration from an xml file in [path]
  Configuration.fromFile(String path, this.system, this.dry)
      : files = [],
        excludedFiles = [],
        mutations = [],
        commands = [],
        exclusions = [],
        ratings = Ratings() {
    addRulesFromFile(path);
  }

  /// Add all rules from [path]
  void addRulesFromFile(String path) {
    system.verboseWriteLine('Processing $path');
    final contents = system.readFile(path);
    parseXMLString(contents);
  }

  /// Removes all input source files from the target file list
  /// that were explicitly excluded in the rules file.
  void _removeExcludedSourceFiles() {
    for (final excluded in excludedFiles) {
      files.removeWhere((element) {
        if (element.path == excluded) {
          system.verboseWriteLine('Excluding file: $excluded');
          return true;
        }
        return false;
      });
    }
  }

  /// Parses an XML string with the given [contents]
  void parseXMLString(String contents) {
    final document = xml.XmlDocument.parse(contents);
    for (var element in document.findAllElements('mutations')) {
      _processTopLevel(element);
    }
    if (!topLevelFound) {
      throw MutationError('Could not find xml element <mutations>');
    }
    _removeExcludedSourceFiles();
  }

  /// Tries to infer validation commands if no commands are present.
  ///
  /// The method will check if a pubspec.yaml file is found in the current directory.
  /// If there is one, it will check if flutter test or dart test should be used by
  /// checking if the file contains .
  void inferCommandsIfEmpty() {
    if (commands.isNotEmpty) {
      return;
    }
    system.verboseWriteLine('Trying to detect test commands...');
    const path = 'pubspec.yaml';
    if (!system.fileExists(path)) {
      system.writeLine(
          'Failed to detect test commands: no "$path" found in the current working directory!');
      return;
    }
    final pubspec = system.readFile(path);
    // Infer if we should use flutter test by checking for the strings "flutter:" and "sdk: flutter"
    // see https://docs.flutter.dev/tools/pubspec
    if (pubspec.contains('flutter:') &&
        pubspec.contains(RegExp(r'sdk:[ \t]*flutter'))) {
      system.verboseWriteLine(
          'Assuming a flutter project based on the contents of "$path". Using "flutter test".');
      _addInferredCommand('flutter test', 'flutter', ['test']);
    } else {
      system.verboseWriteLine(
          'Assuming a dart project based on the contents of "$path". Using "dart test".');
      _addInferredCommand('dart test', 'dart', ['test']);
    }
  }

  void _addInferredCommand(String text, String program, List<String> args) {
    var cmd = Command(text, program, args);
    cmd.expectedReturnValue = 0;
    cmd.group = 'test';
    cmd.timeout = Duration(seconds: 60);
    commands.add(cmd);
  }

  /// Checks if the configuration is valid.
  /// That means at least one input file, one test command and
  /// one mutation rule.
  void validate() {
    if ((files.isEmpty) || mutations.isEmpty || commands.isEmpty) {
      throw MutationError(
          'At least one entry in the configuration for each of the following elements is needed:\n'
          'files: ${files.length} mutation rules: ${mutations.length} verification commands: ${commands.length}');
    }
    ratings.sanitize();
  }

  void _processTopLevel(xml.XmlElement root) {
    var str = root.getAttribute('version');
    topLevelFound = true;
    if (str == null) {
      throw MutationError(
          'No version attribute found in xml element <mutations>!');
    }
    double version = double.parse(str);
    if (version != 1.0 && version != 1.1) {
      throw MutationError('Configuration file version not supported!');
    }
    system.verboseWriteLine('- configuration file version $str');

    _processXMLNode(root, 'files', (xml.XmlElement el) {
      _processXMLNode(el, 'file', _addFile);
    });

    _processXMLNode(root, 'directories', (xml.XmlElement el) {
      _processXMLNode(el, 'directory', _addDirectory);
    });
    system.verboseWriteLine(' ${files.length} input files');

    _processXMLNode(root, 'rules', (xml.XmlElement el) {
      _processXMLNode(el, 'literal', _addLiteralRule);
      _processXMLNode(el, 'regex', _addRegexRule);
    });
    system.verboseWriteLine(' ${mutations.length} mutation rules');

    _processXMLNode(root, 'exclude', (xml.XmlElement el) {
      _processXMLNode(el, 'token', _addTokenRange);
      _processXMLNode(el, 'lines', _addLineRange);
      _processXMLNode(el, 'regex', (el) {
        exclusions.add(RegexRange(_parseRegEx(el)));
      });
      _processXMLNode(el, 'file', _addExcludedFile);
    });
    system.verboseWriteLine(' ${exclusions.length} exclusion rules');

    _processXMLNode(root, 'commands', (xml.XmlElement el) {
      _processXMLNode(el, 'command', _addCommand);
    });
    system.verboseWriteLine(
        ' ${commands.length} commands will be executed to detect mutations');

    _processXMLNode(root, 'threshold', _parseThreshold);
  }

  void _processXMLNode(
      xml.XmlElement root, String type, void Function(xml.XmlElement) functor) {
    for (var element in root.findAllElements(type)) {
      functor(element);
    }
  }

  void _addFile(xml.XmlElement element) {
    final path = element.innerText.trim();
    if (!system.fileExists(path)) {
      throw MutationError('Input file "$path" not found!');
    }
    var whitelist = <Range>[];
    _processXMLNode(element, 'lines', (el) {
      whitelist.add(_parseLineRange(el));
    });
    files.add(TargetFile(path, whitelist));
  }

  void _addExcludedFile(xml.XmlElement element) {
    excludedFiles.add(element.innerText.trim());
  }

  void _addDirectory(xml.XmlElement element) {
    final path = element.innerText.trim();
    if (!system.directoryExists(path)) {
      throw MutationError('Input directory "$path" not found!');
    }
    var recurseStr = element.getAttribute('recursive');
    var recurse = recurseStr != null && recurseStr == 'true';
    List<RegExp> patterns = [];
    _processXMLNode(element, 'matching', (el) {
      var pat = el.getAttribute('pattern');
      if (pat == null) {
        throw MutationError(
            '<matching> tokens must have a pattern as attribute!');
      }
      patterns.add(RegExp(pat));
    });
    files.addAll(system
        .listDirectoryContents(path, recurse, patterns)
        .map((e) => TargetFile(e, [])));
  }

  void _parseThreshold(xml.XmlElement element) {
    if (ratings.initialized) {
      throw MutationError(
          'There must be only one <threshold> element in the inputs!');
    }
    var failure = element.getAttribute('failure');
    if (failure == null) {
      throw MutationError('<threshold> needs attribute "failure"');
    }
    ratings.failure = double.parse(failure);

    _processXMLNode(element, 'rating', (el) {
      var lowerBound = el.getAttribute('over');
      var name = el.getAttribute('name');
      if (lowerBound == null || name == null) {
        throw MutationError(
            '<rating> needs attributes "over" and "name" - got $lowerBound, $name');
      }
      ratings.addRating(double.parse(lowerBound), name);
    });

    system.verboseWriteLine(' $ratings');
  }

  void _addTokenRange(xml.XmlElement element) {
    var begin = element.getAttribute('begin');
    var end = element.getAttribute('end');
    if (begin == null || end == null) {
      throw MutationError('Every <token> needs a begin and end attribute!');
    }
    if (begin == '\\n') {
      begin = '\n';
    }
    if (end == '\\n') {
      end = '\n';
    }
    if (begin == '\\t') {
      begin = '\t';
    }
    if (end == '\\t') {
      end = '\t';
    }
    exclusions.add(TokenRange(begin, end));
  }

  LineRange _parseLineRange(xml.XmlElement element) {
    var begin = element.getAttribute('begin');
    var end = element.getAttribute('end');
    if (begin == null || end == null) {
      throw MutationError('Every <lines> needs a begin and end attribute!');
    }
    return LineRange(int.parse(begin), int.parse(end));
  }

  void _addLineRange(xml.XmlElement element) {
    exclusions.add(_parseLineRange(element));
  }

  RegExp _parseRegEx(xml.XmlElement element) {
    var pattern = element.getAttribute('pattern');
    if (pattern == null) {
      throw MutationError('Every <regex> needs a pattern!');
    }
    var tmp = element.getAttribute('dotAll');
    var dotMatchesNewlines = tmp != null && tmp == 'true';
    return RegExp(pattern, multiLine: true, dotAll: dotMatchesNewlines);
  }

  /// Parses a <command> token from [element] and adds it to the internal structure.
  void _addCommand(xml.XmlElement element) {
    final original = element.innerText;
    var text = original.split(' ');
    if (text.isEmpty) {
      throw MutationError('Received empty text for a <command>');
    }
    final process = text[0].trim();
    final args = <String>[];
    args.addAll(text);
    args.removeAt(0);
    final cmd = Command(original, process, args);
    final group = element.getAttribute('group');
    if (group != null) {
      cmd.group = group;
    }
    final expected = element.getAttribute('expected');
    if (expected != null) {
      cmd.expectedReturnValue = int.parse(expected);
    }
    final timeout = element.getAttribute('timeout');
    if (timeout != null) {
      cmd.timeout = Duration(seconds: int.parse(timeout));
    }
    cmd.directory = element.getAttribute('working-directory');
    commands.add(cmd);
  }

  /// Adds a literal text replacement rule from [element]
  void _addLiteralRule(xml.XmlElement element) {
    var str = element.getAttribute('text');
    if (str == null) {
      throw MutationError('Each <literal> must have a text attribute!');
    }
    var mutation =
        Mutation(mutations.length, str, id: element.getAttribute('id'));
    for (var child in element.findAllElements('mutation')) {
      var replacement = child.getAttribute('text');
      if (replacement == null) {
        throw MutationError('Each <mutation> must have a text attribute!');
      }
      mutation.replacements.add(LiteralReplacement(replacement));
    }
    if (mutation.replacements.isEmpty) {
      throw MutationError(
          'Each <literal> rule must have at least one <mutation> child!');
    }
    mutations.add(mutation);
  }

  /// Adds a regular expression text replacement rule from [element]
  void _addRegexRule(xml.XmlElement element) {
    var mutation = Mutation(mutations.length, _parseRegEx(element),
        id: element.getAttribute('id'));
    for (var child in element.findAllElements('mutation')) {
      var replacement = child.getAttribute('text');
      if (replacement == null) {
        throw MutationError('Each <mutation> must have a text attribute!');
      }
      mutation.replacements.add(RegexReplacement(replacement));
    }
    if (mutation.replacements.isEmpty) {
      throw MutationError(
          'Each <regex> rule must have at least one <mutation> child!');
    }
    mutations.add(mutation);
  }
}
