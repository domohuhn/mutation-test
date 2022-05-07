/// Copyright 2021, domohuhn.
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license
import 'dart:io';
import 'package:xml/xml.dart' as xml;
import 'package:mutation_test/src/mutations.dart';
import 'package:mutation_test/src/replacements.dart';
import 'package:mutation_test/src/commands.dart';
import 'package:mutation_test/src/errors.dart';
import 'package:mutation_test/src/range.dart';
import 'package:mutation_test/src/ratings.dart';

/// A structure holding the information about the mutation input.
class TargetFile {
  String path;
  List<Range> whitelist;
  TargetFile(this.path, this.whitelist);
}

/// Reads the xml configuration file
class Configuration {
  List<TargetFile> files;
  List<Mutation> mutations;
  List<Command> commands;
  List<Range> exclusions;
  Ratings ratings;
  bool toplevelFound = false;
  bool verbose;
  bool dry;

  Configuration(this.verbose, this.dry)
      : files = [],
        mutations = [],
        commands = [],
        exclusions = [],
        ratings = Ratings();

  /// Constructs the configuration from an xml file in [path]
  Configuration.fromFile(String path, this.verbose, this.dry)
      : files = [],
        mutations = [],
        commands = [],
        exclusions = [],
        ratings = Ratings() {
    addRulesFromFile(path);
  }

  /// Add all rules from [path]
  void addRulesFromFile(String path) {
    if (verbose) {
      print('Processing $path');
    }
    var file = File(path);
    final contents = file.readAsStringSync();
    parseXMLString(contents);
  }

  /// Parses an XML string with the given [contents]
  void parseXMLString(String contents) {
    final document = xml.XmlDocument.parse(contents);
    for (var element in document.findAllElements('mutations')) {
      _processTopLevel(element);
    }
    if (!toplevelFound) {
      throw MutationError('Could not find xml element <mutations>');
    }
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
    toplevelFound = true;
    if (str == null) {
      throw MutationError(
          'No version attribute found in xml element <mutations>!');
    }
    if (double.parse(str) != 1.0) {
      throw MutationError('Configuration file version not supported!');
    }
    if (verbose) {
      print('- configuration file version $str');
    }

    _processXMLNode(root, 'files', (xml.XmlElement el) {
      _processXMLNode(el, 'file', _addFile);
    });

    _processXMLNode(root, 'directories', (xml.XmlElement el) {
      _processXMLNode(el, 'directory', _addDirectory);
    });

    if (verbose) {
      print(' ${files.length} input files');
    }

    _processXMLNode(root, 'rules', (xml.XmlElement el) {
      _processXMLNode(el, 'literal', _addLiteralRule);
      _processXMLNode(el, 'regex', _addRegexRule);
    });
    if (verbose) {
      print(' ${mutations.length} mutation rules');
    }

    _processXMLNode(root, 'exclude', (xml.XmlElement el) {
      _processXMLNode(el, 'token', _addTokenRange);
      _processXMLNode(el, 'lines', _addLineRange);
      _processXMLNode(el, 'regex', (el) {
        exclusions.add(RegexRange(_parseRegEx(el)));
      });
    });
    if (verbose) {
      print(' ${exclusions.length} exclusion rules');
    }

    _processXMLNode(root, 'commands', (xml.XmlElement el) {
      _processXMLNode(el, 'command', _addCommand);
    });
    if (verbose) {
      print(
          ' ${commands.length} commands will be executed to detect mutations');
    }

    _processXMLNode(root, 'threshold', _parseThreshold);
  }

  void _processXMLNode(
      xml.XmlElement root, String type, void Function(xml.XmlElement) functor) {
    for (var element in root.findAllElements(type)) {
      functor(element);
    }
  }

  void _addFile(xml.XmlElement element) {
    final path = element.text.trim();
    if (!File(path).existsSync()) {
      throw MutationError('Input file "$path" not found!');
    }
    var whitelist = <Range>[];
    _processXMLNode(element, 'lines', (el) {
      whitelist.add(_parseLineRange(el));
    });
    files.add(TargetFile(path, whitelist));
  }

  void _addDirectory(xml.XmlElement element) {
    final path = element.text.trim();
    if (!Directory(path).existsSync()) {
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
    var tree = Directory(path).listSync(recursive: recurse);
    for (var f in tree) {
      if (patterns.isNotEmpty) {
        for (var pat in patterns) {
          if (pat.hasMatch(f.path) && f is! Link) {
            files.add(TargetFile(f.path, []));
          }
        }
      } else {
        files.add(TargetFile(f.path, []));
      }
    }
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
      var lowerbound = el.getAttribute('over');
      var name = el.getAttribute('name');
      if (lowerbound == null || name == null) {
        throw MutationError(
            '<rating> needs attributes "over" and "name" - got $lowerbound, $name');
      }
      ratings.addRating(double.parse(lowerbound), name);
    });

    if (verbose) {
      print(' $ratings');
    }
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

  /// Parses a <command> token from [element] and adds it to the interal structure.
  void _addCommand(xml.XmlElement element) {
    var text = element.text.split(' ');
    if (text.isEmpty) {
      throw MutationError('Received empty text for a <command>');
    }
    final process = text[0].trim();
    final args = <String>[];
    args.addAll(text);
    args.removeAt(0);
    final cmd = Command(element.text, process, args);
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
    var mutation = Mutation(str);
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
    var mutation = Mutation(_parseRegEx(element));
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
