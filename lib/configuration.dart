/// Copyright 2021, domohuhn. 
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license
import 'dart:io';
import 'package:xml/xml.dart' as xml;
import 'mutations.dart';
import 'replacements.dart';
import 'commands.dart';
import 'errors.dart';
import 'range.dart';

/// A structure holding the information about the mutation input.
class TargetFile {
  String path;
  List<Range> whitelist;
  TargetFile(this.path,this.whitelist);
}

/// Reads the xml configuration file
class Configuration {
  List<TargetFile> files = [];
  List<Mutation> mutations = [];
  List<Command> commands = [];
  List<Range> exclusions = [];
  bool toplevelFound = false;
  bool verbose;
  bool dry;

  Configuration(this.verbose, this.dry);

  /// Constructs the configuration from an xml file in [path]
  Configuration.fromFile(String path, this.verbose, this.dry) {
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
      throw Error('Could not find xml element <mutations>');
    }
  }

  
  /// Checks if the configuration is valid.
  /// That means at least one input file, one test command and 
  /// one mutation rule.
  void validate() {
    if (files.isEmpty || mutations.isEmpty || commands.isEmpty) {
      throw Error('At least one entry in the configuration for each of the following elements is needed:\n'
      'files: ${files.length} mutation rules: ${mutations.length} verification commands: ${commands.length}');
    }
  }

  void _processTopLevel(xml.XmlElement root) {
    var str = root.getAttribute('version');
    toplevelFound = true;
    if (str == null) {
      throw Error('No version attribute found in xml element <mutations>!');
    }
    if (double.parse(str) != 1.0) {
      throw Error('Configuration file version not supported!');
    }
    if (verbose) {
      print('- configuration file version $str');
    }

    _processXMLNode(root,'files',(xml.XmlElement el) {
      _processXMLNode(el,'file',_addFile);
    });
    if (verbose) {
      print(' ${files.length} input files');
    }

    _processXMLNode(root,'rules',(xml.XmlElement el) {
      _processXMLNode(el,'literal',_addLiteralRule);
      _processXMLNode(el,'regex',_addRegexRule);
    });
    if (verbose) {
      print(' ${mutations.length} mutation rules');
    }

    _processXMLNode(root,'exclude',(xml.XmlElement el) {
      _processXMLNode(el,'token',_addTokenRange);
      _processXMLNode(el,'lines',_addLineRange);
      _processXMLNode(el,'regex',(el) { exclusions.add(RegexRange(_parseRegEx(el))); });
    });
    if (verbose) {
      print(' ${exclusions.length} exclusion rules');
    }
    
    _processXMLNode(root,'commands',(xml.XmlElement el) {
      _processXMLNode(el,'command',_addCommand);
    });
    if (verbose) {
      print(' ${commands.length} commands will be executed to detected mutations');
    }
  }

  void _processXMLNode(xml.XmlElement root, String type, void Function(xml.XmlElement) functor) {
    for (var element in root.findAllElements(type)) {
      functor(element);
    }
  }

  void _addFile(xml.XmlElement element) {
    final path = element.text.trim();
    if (!File(path).existsSync()) {
      throw Error('Input file "$path" not found!');
    }
    var whitelist = <Range>[];
    _processXMLNode(element, 'lines', (el) { whitelist.add(_parseLineRange(el));  });
    files.add(TargetFile(path, whitelist));
  }
  
  void _addTokenRange(xml.XmlElement element) {
    var begin = element.getAttribute('begin');
    var end = element.getAttribute('end');
    if (begin==null || end == null) {
      throw Error('Every <token> needs a begin and end attribute!');
    }
    if (begin=='\\n') {
      begin='\n';
    }
    if (end=='\\n') {
      end='\n';
    }
    if (begin=='\\t') {
      begin='\t';
    }
    if (end=='\\t') {
      end='\t';
    }
    exclusions.add(TokenRange(begin, end));
  }

  LineRange _parseLineRange(xml.XmlElement element) {
    var begin = element.getAttribute('begin');
    var end = element.getAttribute('end');
    if (begin==null || end == null) {
      throw Error('Every <lines> needs a begin and end attribute!');
    }
    return LineRange(int.parse(begin), int.parse(end));
  }

  void _addLineRange(xml.XmlElement element) {
    exclusions.add(_parseLineRange(element));
  }

  RegExp _parseRegEx(xml.XmlElement element) {
    var pattern = element.getAttribute('pattern');
    if (pattern==null) {
      throw Error('Every <regex> needs a pattern!');
    }
    var tmp = element.getAttribute('dotAll');
    var dotMatchesNewlines =  tmp!=null&&tmp=='true';
    return RegExp(pattern, multiLine: true, dotAll: dotMatchesNewlines);
  }
  
  /// Parses a <command> token from [element] and adds it to the interal structure.
  void _addCommand(xml.XmlElement element) {
    var text = element.text.split(' ');
    if (text.isEmpty) {
      throw Error('Received empty text for a <command>');
    }
    final process = text[0].trim();
    final args = <String>[];
    args.addAll(text);
    args.removeAt(0);
    final cmd = Command(element.text,process,args);
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
      throw Error('Each <literal> must have a text attribute!');
    }
    var mutation = Mutation(str);
    for (var child in element.findAllElements('mutation')) {
      var replacement = child.getAttribute('text');
      if (replacement == null) {
        throw Error('Each <mutation> must have a text attribute!');
      }
      mutation.replacements.add(LiteralReplacement(replacement));
    }
    if (mutation.replacements.isEmpty) {
      throw Error('Each <literal> rule must have at least one <mutation> child!');
    }
    mutations.add(mutation);
  }

  /// Adds a regular expression text replacement rule from [element]
  void _addRegexRule(xml.XmlElement element) {
    var mutation = Mutation(_parseRegEx(element));
    for (var child in element.findAllElements('mutation')) {
      var replacement = child.getAttribute('text');
      if (replacement == null) {
        throw Error('Each <mutation> must have a text attribute!');
      }
      mutation.replacements.add(RegexReplacement(replacement));
    }
    if (mutation.replacements.isEmpty) {
      throw Error('Each <regex> rule must have at least one <mutation> child!');
    }
    mutations.add(mutation);
  }

}



