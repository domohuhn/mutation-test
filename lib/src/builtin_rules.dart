// Copyright 2021, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

/// Start of a XML file.
String _xmlStart() {
  return '''<?xml version="1.0" encoding="UTF-8"?>
<mutations version="1.0">\n''';
}

/// End of a XML file.
String _xmlEnd() {
  return '''</mutations>\n''';
}

/// A XML snippet for a rules file.
String _xmlInputs() {
  return r'''
  <!-- List all input files here -->
  <!-- The text of the file element must contain a valid path to a file -->
  <!-- You can specify which lines should be mutated with the lines child elements -->
  <!-- If there are no lines specified, the whole file is used -->
  <files>
    <file>example/source.dart</file>
    <file>example/source2.dart
      <!-- lines can be whitelisted  -->
      <!-- line index starts at 1  -->
      <lines begin="13" end="24"/>
      <lines begin="29" end="35"/>
    </file>
  </files>
  <!-- You can list all input directories here -->
  <directories>
    <directory recursive="true">lib
      <!-- Without matching elements, all files will be added. -->
      <!-- Select all files ending in .cpp, .cxx and .c. -->
      <matching pattern="\.cpp$"/>
      <matching pattern="\.cxx$"/>
      <matching pattern="\.c$"/>
    </directory>
  </directories>
  <!-- Specify the test commands here with the command element -->
  <!-- The text of the command element will be executed as shell process -->
  <!-- The return value of the command will used to check for success -->
  <!-- If all commands execute successfully, a mutation counts as undetected -->
  <commands>
    <!-- All attributes here are optional -->
    <!-- group: is used to show statistics for the commands -->
    <!-- expected-return: this value is compared to the return value of the command. Must be an integer -->
    <!-- working-directory: Where the program is executed. Defaults to . -->
    <!-- tiemout: Timeout in seconds. Must be an integer. If not present, the commands will run until they are finished. -->
    <command group="compile" expected-return="0" working-directory=".">make -j8</command>
    <command group="test" expected-return="0" working-directory="." timeout="10">ctest -j8</command>
  </commands>
''';
}

/// A XML snippet for a rules file.
String _xmlRules() {
  return r'''
  <!-- The rules element describes all mutations done during a mutation test -->
  <!-- The following children are parsed: literal and regex -->
  <!-- A literal element matches the literal text -->
  <!-- A regex element mutates source code if the regular expression matches -->
  <!-- Each of them must have at least one mutation child -->
  <rules>
    <!-- A literal element matches the literal text and replaces it with the list of mutations  -->
    <!-- Replaces 'and' and 'or'  with each other -->
    <literal text="&amp;&amp;" id="builtin.and">
      <mutation text="||"/>
    </literal>
    <literal text="||" id="builtin.or">
      <mutation text="&amp;&amp;"/>
    </literal>
    <!-- Replaces assignments with other assignments -->
    <literal text="+=" id="builtin.op.add_assign">
      <mutation text="="/>
    </literal>
    <literal text="-=" id="builtin.op.sub_assign">
      <mutation text="="/>
    </literal>
    <literal text="*=" id="builtin.op.mul_assign">
      <mutation text="="/>
    </literal>
    <literal text="/=" id="builtin.op.div_assign">
      <mutation text="="/>
    </literal>
    <literal text="&=" id="builtin.op.and_assign">
      <mutation text="="/>
    </literal>
    <literal text="^=" id="builtin.op.or_assign">
      <mutation text="="/>
    </literal>
    <!-- Replaces comparison operators -->
    <literal text="==" id="builtin.op.eq">
      <mutation text="!="/>
    </literal>
    <literal text="!=" id="builtin.op.neq">
      <mutation text="=="/>
    </literal>
    <literal text="&lt;=" id="builtin.op.leq">
      <mutation text="=="/>
      <mutation text="&lt;"/>
    </literal>
    <literal text="&gt;=" id="builtin.op.geq">
      <mutation text="=="/>
      <mutation text="&gt;"/>
    </literal>
    <!-- It is also possible to match a regular expression with capture groups. -->
    <!-- If the optional attribute dotAll is set to true, then the . will also match newlines.  -->
    <!-- If not present, the default value for dotAll is false.  -->
    <!-- Here, we capture everything inside of the braces of "if ()" -->
    <regex pattern="[\s]if[\s]*\((.*?)\)[\s]*{" dotAll="true" id="builtin.if">
      <!-- You can access groups via $1. -->
      <!-- If your string contains a $ followed by a number that should not be replaced, escape the dollar \$ -->
      <!-- If your string contains a \$ followed by a number that should not be replaced, escape the slash \\$ -->
      <!-- Tabs and newlines should also be escaped. -->
      <mutation text=" if (!($1)) {"/>
    </regex>
    <!-- Matches long chains of && -->
    <regex pattern="&amp;([^&amp;()]+?)&amp;" dotAll="true" id="builtin.logical.and_chain">
      <mutation text="&amp;!($1)&amp;"/>
    </regex>
    <!-- Matches long chains of || -->
    <regex pattern="\|([^|()]+?)\|" dotAll="true" id="builtin.logical.or_chain">
      <mutation text="|!($1)|"/>
    </regex>
    <regex pattern="\(([^$(]*?)&amp;&amp;([^$()]*?)\)" id="builtin.logical.and_chain2">
      <mutation text="(!($1)&amp;&amp;$2)"/>
      <mutation text="($1&amp;&amp;!($2))"/>
    </regex>
    <regex pattern="\(([^|(]*?)\|\|([^()|]*?)\)" id="builtin.logical.or_chain2">
      <mutation text="(!($1)||$2)"/>
      <mutation text="($1||!($2))"/>
    </regex>
    <!-- Replace start of conditional block -->
    <regex pattern="if\s*\(([^|&amp;\)]*?)([|&amp;][|&amp;])" id="builtin.if.start">
      <mutation text="if (!($1)$2"/>
    </regex>
    <!-- Replace end of conditional block -->
    <regex pattern="([|&amp;][|&amp;])([^|&amp;]*?)\)" id="builtin.if.end">
      <mutation text="$1!($2))"/>
    </regex>
    <regex pattern="([|&amp;][|&amp;])[\s]*?\(" dotAll="true" id="builtin.logical.chain_not">
      <mutation text="$1!("/>
    </regex>
    <!-- Replaces numbers with negative values -->
    <regex pattern="([\s=\(])([1-9\.]+[0-9]+|0\.0*[1-9])" id="builtin.number.negative">
      <mutation text="$1-$2"/>
    </regex>
    <!-- checks if neighboring arguments may have been mixed up -->
    <!-- switch function call arguments. Matches 2 args -->
    <regex pattern="([\s][a-zA-Z]+?[^(;\s{}]*?)\s*\(([^,;{}(]+?),([^,;{}(]+?)\)\s*;" id="builtin.function.arg2">
      <mutation text="$1($3,$2);"/>
    </regex>
    <!-- switch function call arguments. Matches 3 args -->
    <regex pattern="([\s][a-zA-Z]+?[^\(;\s{}]*?)\s*\(([^,;{}(]+?),([^,;{}(]+?),([^,;{}(]+?)\)\s*;" id="builtin.function.arg3">
      <mutation text="$1($3,$2,$4);"/>
      <mutation text="$1($2,$4,$3);"/>
    </regex>
    <!-- switch function call arguments. Matches 4 args -->
    <regex pattern="([\s][a-zA-Z]+?[^\(;\s{}]*?)\s*\(([^,;{}(]+?),([^,;{}(]+?),([^,;{}(]+?),([^,;{}(]+?)\)\s*;"  id="builtin.function.arg4">
      <mutation text="$1($3,$2,$4,$5);"/>
      <mutation text="$1($2,$4,$3,$5);"/>
      <mutation text="$1($2,$3,$5,$4);"/>
    </regex>
    <!-- Replaces arithmetic operators with their opposite -->
    <regex pattern="\+([^=])" id="builtin.arith.add">
      <mutation text="-$1"/>
    </regex>
    <regex pattern="-([^=])" id="builtin.arith.sub">
      <mutation text="+$1"/>
    </regex>
    <regex pattern="\*([^=])" id="builtin.arith.mul">
      <mutation text="/$1"/>
    </regex>
    <regex pattern="/([^=])" id="builtin.arith.div">
      <mutation text="*$1"/>
    </regex>
  </rules>
  <!-- This element creates a blacklist, allowing you to exclude parts from the mutations -->
  <exclude>
    <!-- excludes anything between two tokens  -->
    <!-- single line comments  -->
    <token begin="//" end="\n"/>
    <!-- exclude dart exports and imports  -->
    <token begin="export &apos;" end="&apos;;"/>
    <token begin="import &apos;" end="&apos;;"/>
    <token begin="export &quot;" end="&quot;;"/>
    <token begin="import &quot;" end="&quot;;"/>
    <!-- excludes anything that matches a pattern  -->
    <!-- multi line comments  -->
    <regex pattern="/[*].*?[*]/" dotAll="true"/>
    <!-- exclude increment and decrement operators. Produces mostly false positives.  -->
    <regex pattern="\+\+"/>
    <regex pattern="--"/>
    <!-- excludes loops from mutations to prevent tests to run forever -->
    <regex pattern="[\s]for[\s]*\(.*?\)[\s]*{" dotAll="true"/>
    <regex pattern="[\s]while[\s]*\(.*?\)[\s]*{.*?}" dotAll="true"/>
    <!-- lines can also be globally excluded  -->
    <!-- line index starts at 1  -->
    <!-- lines begin="1" end="2"/-->
    <!-- It is possible to exclude files using the file element. -->
    <!-- <file>path/to/exclude.dart</file> -->
  </exclude>
  <!-- Configures the reporting thresholds as percentage of detected mutations -->
  <!-- Attribute failure is required and must be a floating point number. -->
  <!-- Note: There can only be one threshold element in all input files! -->
  <!-- If no threshold element is found, these values will be used. -->
  <threshold failure="80">
    <!-- Provides reliability rating levels. Attributes are required. -->
    <rating over="95" name="A"/>
    <rating over="80" name="B"/>
    <rating over="60" name="C"/>
    <rating over="40" name="D"/>
    <rating over="20" name="E"/>
    <rating over="0" name="F"/>
  </threshold>
''';
}

/// Returns the builtin mutation rules as String
String builtinMutationRules() {
  return _xmlStart() + _xmlRules() + _xmlEnd();
}

/// Returns a complete example file
String fullXMLFile() {
  return _xmlStart() + _xmlInputs() + _xmlRules() + _xmlEnd();
}

/// Returns the file and test command for default dart libs.
String _xmlDartInputs() {
  return r'''
  <directories>
    <directory recursive="true">lib
      <matching pattern="\.dart$"/>
    </directory>
  </directories>
  <commands>
    <command group="test" expected-return="0" working-directory="." timeout="60">dart test</command>
  </commands>
''';
}

/// Returns the default dart configuration
String dartDefaultConfiguration() {
  return _xmlStart() + _xmlDartInputs() + _xmlEnd();
}
