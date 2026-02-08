// Copyright 2021, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/configuration/builtin_rules.dart';
import 'package:mutation_test/src/configuration/configuration.dart';
import 'package:test/test.dart';

import '../core/mock_system_interactions.dart';

void main() {
  final mock = MockSystemInteractions();
  test('Parse builtin rules', () {
    final configuration = Configuration(mock, true);
    configuration.parseXMLString(builtinMutationRules());
    expect(configuration.exclusions.length, 10);
    expect(configuration.mutations.length, 32);
    expect(configuration.files.length, 0);
    expect(configuration.commands.length, 0);
  });

  test('Parse example string', () {
    final configuration = Configuration(mock, true);
    configuration.parseXMLString(fullXMLFile());
    expect(configuration.exclusions.length, 10);
    expect(configuration.mutations.length, 32);
    expect(configuration.files.length, 2);
    expect(configuration.commands.length, 2);
    configuration.validate();
  });

  test('Parse file exclusion', () {
    final configuration = Configuration(mock, true);
    configuration.parseXMLString(_excludeFiles);
    expect(configuration.files.length, 0);
    expect(configuration.excludedPaths.length, 2);
    expect(configuration.excludedPaths[0].isDirectory, false);
    expect(configuration.excludedPaths[0].isFile, true);
    expect(
        configuration.excludedPaths[0].patternParts[0], 'some/file/to/exclude');
    expect(configuration.excludedPaths[1].isDirectory, false);
    expect(configuration.excludedPaths[1].isFile, true);
    expect(configuration.excludedPaths[1].patternParts[0],
        'test/configuration/parse_xml_test.dart');
  });

  test('Parse dir exclusion', () {
    final configuration = Configuration(mock, true);
    configuration.parseXMLString(_excludeDirectory);
    expect(configuration.files.length, 0);
    expect(configuration.excludedPaths.length, 2);
    expect(configuration.excludedPaths[0].isDirectory, true);
    expect(configuration.excludedPaths[0].isFile, false);
    expect(configuration.excludedPaths[0].patternParts[0], 'lib/');
    expect(configuration.excludedPaths[0].patternParts[1], '**');
    expect(configuration.excludedPaths[0].patternParts[2], '/configuration');
    expect(configuration.excludedPaths[1].isDirectory, true);
    expect(configuration.excludedPaths[1].isFile, false);
    expect(
        configuration.excludedPaths[1].patternParts[0], 'test/configuration/');
    expect(configuration.excludedPaths[1].patternParts[1], '*');
    expect(configuration.excludedPaths[1].patternParts[2], '.dart');
  });

  test('Input error - wrong version', () {
    final configuration = Configuration(mock, true);
    expect(() {
      configuration.parseXMLString(_wrongVersion);
    }, throwsException);
  });

  test('Input error - lines', () {
    final configuration = Configuration(mock, true);
    expect(() {
      configuration.parseXMLString(_noLineAttributes);
    }, throwsException);
  });

  test('Input error - token', () {
    final configuration = Configuration(mock, true);
    expect(() {
      configuration.parseXMLString(_noTokenAttributes);
    }, throwsException);
  });

  test('Input error - regex', () {
    final configuration = Configuration(mock, true);
    expect(() {
      configuration.parseXMLString(_noRegexAttributes);
    }, throwsException);
  });

  test('Input error - literal', () {
    final configuration = Configuration(mock, true);
    expect(() {
      configuration.parseXMLString(_noLiteralAttributes);
    }, throwsException);
  });

  test('Input error - mutation', () {
    final configuration = Configuration(mock, true);
    expect(() {
      configuration.parseXMLString(_noMutationAttributes);
    }, throwsException);
  });

  test('Input error - no replacement rule', () {
    final configuration = Configuration(mock, true);
    expect(() {
      configuration.parseXMLString(_noMutationChild);
    }, throwsException);
  });

  test('Read from file', () {
    final configuration =
        Configuration.fromFile('./example/should_timeout.xml', mock, true);
    expect(configuration.exclusions.length, 0);
    expect(configuration.mutations.length, 0);
    expect(configuration.files.length, 1);
    expect(configuration.commands.length, 1);
    expect(() {
      configuration.validate();
    }, throwsException);
  });

  test('Read from file - wildcard1', () {
    final configuration =
        Configuration.fromFile('./example/config5.xml', mock, true);
    expect(configuration.files.length, 3);
  });

  test('Read from file - wildcard2', () {
    final configuration =
        Configuration.fromFile('./example/config4.xml', mock, true);
    expect(configuration.files.length, 4);
  });

  test('Dart default rules', () {
    final xml = dartDefaultConfiguration();
    expect(
        xml,
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<mutations version="1.2">\n'
        '  <directories>\n'
        '    <directory recursive="true">lib\n'
        '      <matching pattern="\\.dart\$"/>\n'
        '    </directory>\n'
        '  </directories>\n'
        '</mutations>\n'
        '');
  });
}

String _wrongVersion = '''
<?xml version="1.0" encoding="UTF-8"?>
<mutations version="0.0">
</mutations>
''';

String _noLineAttributes = '''
<?xml version="1.0" encoding="UTF-8"?>
<mutations version="1.0">
  <exclude>
    <lines/>
  </exclude>
</mutations>
''';

String _noTokenAttributes = '''
<?xml version="1.0" encoding="UTF-8"?>
<mutations version="1.0">
  <exclude>
    <token begin="//"/>
  </exclude>
</mutations>
''';

String _noRegexAttributes = '''
<?xml version="1.0" encoding="UTF-8"?>
<mutations version="1.0">
  <exclude>
    <regex/>
  </exclude>
</mutations>
''';

String _noLiteralAttributes = '''
<?xml version="1.0" encoding="UTF-8"?>
<mutations version="1.0">
  <rules>
    <literal>
      <mutation text="aa"/>
    </literal>
  </rules>
</mutations>
''';

String _noMutationAttributes = '''
<?xml version="1.0" encoding="UTF-8"?>
<mutations version="1.0">
  <rules>
    <literal text="aa">
      <mutation/>
    </literal>
  </rules>
</mutations>
''';

String _noMutationChild = '''
<?xml version="1.0" encoding="UTF-8"?>
<mutations version="1.0">
  <rules>
    <literal text="aa"/>
  </rules>
</mutations>
''';

String _excludeFiles = '''
<?xml version="1.0" encoding="UTF-8"?>
<mutations version="1.0">
  <files>
    <file>test/configuration/parse_xml_test.dart</file>
  </files>
  <exclude>
    <file>some/file/to/exclude</file>
    <file>test/configuration/parse_xml_test.dart</file>
  </exclude>
</mutations>
''';

String _excludeDirectory = '''
<?xml version="1.0" encoding="UTF-8"?>
<mutations version="1.0">
  <files>
    <file>lib/src/configuration/configuration.dart</file>
    <file>test/configuration/parse_xml_test.dart</file>
  </files>
  <exclude>
    <directory>lib/**/configuration</directory>
    <directory>test/configuration/*.dart</directory>
  </exclude>
</mutations>
''';
