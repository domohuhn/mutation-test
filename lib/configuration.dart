
import 'dart:io';
import 'package:xml/xml.dart' as xml;
import 'mutations.dart';
import 'commands.dart';
import 'errors.dart';

/// Reads the xml configuration file
class Configuration {
  List<String> files = [];
  List<Mutation> mutations = [];
  List<Command> commands = [];
  bool toplevelFound = false;
  bool verbose;
  bool dry;

  /// Constructs the configuration from an xml file in [path]
  Configuration.fromFile(String path, this.verbose, this.dry) {
    if (verbose) {
      print('Processing $path');
    }
    var file = File(path);
    final contents = file.readAsStringSync();
    final document = xml.XmlDocument.parse(contents);
    for (var element in document.findAllElements('mutations')) {
      _processTopLevel(element);
    }
    if (!toplevelFound) {
      throw InputError('Could not find xml element <mutations>');
    }
  }

  void _processTopLevel(xml.XmlElement root) {
    var str = root.getAttribute('version');
    toplevelFound = true;
    if (str == null) {
      throw InputError('No version attribute found in xml element <mutations>!');
    }
    if (double.parse(str) != 1.0) {
      throw InputError('Configuration file version not supported!');
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
      _processXMLNode(el,'pattern',_addMutationRule);
    });
    if (verbose) {
      print(' ${mutations.length} mutation rules');
    }
    
    _processXMLNode(root,'commands',_addAllCommands);
    if (verbose) {
      print(' ${commands.length} commands will be executed to check for survivors');
    }
  }

  void _processXMLNode(xml.XmlElement root, String type, void Function(xml.XmlElement) functor) {
    for (var element in root.findAllElements(type)) {
      functor(element);
    }
  }

  void _addFile(xml.XmlElement element) {
    final path = element.text;
    if (!File(path).existsSync()) {
      throw InputError('Input file "$path" not found!');
    }
    files.add(element.text);
  }

  void _addAllCommands(xml.XmlElement element) {
    _processXMLNode(element,'command',_addCommand);
  }
  
  void _addCommand(xml.XmlElement element) {
    var text = element.text.split(' ');
    if (text.isEmpty) {
      throw InputError('Received empty text for a <command>');
    }
    final process = text[0];
    final args = <String>[];
    args.addAll(text);
    args.removeAt(0);
    final cmd = Command(process,args);
    final name = element.getAttribute('name');
    if (name != null) {
      cmd.name = name;
    }
    final group = element.getAttribute('group');
    if (group != null) {
      cmd.group = group;
    }
    final expected = element.getAttribute('expected');
    if (expected != null) {
      cmd.expectedReturnValue = int.parse(expected);
    }
    cmd.directory = element.getAttribute('working-directory');
    commands.add(cmd);
  }

  void _addMutationRule(xml.XmlElement element) {
    var str = element.getAttribute('text');
    if (str == null) {
      throw InputError('Each <pattern> must have a text attribute!');
    }
    var mutation = Mutation(str);
    for (var child in element.findAllElements('mutation')) {
      var replacement = child.getAttribute('text');
      if (replacement == null) {
        throw InputError('Each <mutation> must have a text attribute!');
      }
      mutation.replacements.add(replacement);
    }
    if (mutation.replacements.isEmpty) {
      throw InputError('Each <pattern> must have at least a single <mutation> child!');
    }
    mutations.add(mutation);
  }

}



