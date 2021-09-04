
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
    <literal text="&amp;&amp;">
      <mutation text="||"/>
    </literal>
    <literal text="||">
      <mutation text="&amp;&amp;"/>
    </literal>
    <literal text="+">
      <mutation text="-"/>
      <mutation text="*"/>
    </literal>
    <literal text="-">
      <mutation text="+"/>
      <mutation text="*"/>
    </literal>
    <literal text="*">
      <mutation text="+"/>
      <mutation text="-"/>
    </literal>
    <literal text="/">
      <mutation text="*"/>
      <mutation text="+"/>
    </literal>
    <literal text="==">
      <mutation text="!="/>
    </literal>
    <literal text="&lt;=">
      <mutation text="=="/>
      <mutation text="&lt;"/>
    </literal>
    <literal text="&gt;=">
      <mutation text="=="/>
      <mutation text="&gt;"/>
    </literal>
    <literal text="!=">
      <mutation text="=="/>
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
    <!-- Matches long chains of && -->
    <regex pattern="&amp;([^&amp;()]+?)&amp;" dotAll="true">
      <mutation text="&amp;!($1)&amp;"/>
    </regex>
    <!-- Matches long chains of || -->
    <regex pattern="\|([^|()]+?)\|" dotAll="true">
      <mutation text="|!($1)|"/>
    </regex>
    <regex pattern="\(([^$(]*?)&amp;&amp;([^$()]*?)\)">
      <mutation text="(!($1)&amp;&amp;$2)"/>
      <mutation text="($1&amp;&amp;!($2))"/>
    </regex>
    <regex pattern="\(([^|(]*?)\|\|([^()|]*?)\)">
      <mutation text="(!($1)||$2)"/>
      <mutation text="($1||!($2))"/>
    </regex>
    <!-- Replace start of conditional block -->
    <regex pattern="\(([^|&amp;]*?)([|&amp;][|&amp;])">
      <mutation text="(!($1)$2"/>
    </regex>
    <!-- Replace end of conditional block -->
    <regex pattern="([|&amp;][|&amp;])([^|&amp;]*?)\)">
      <mutation text="$1!($2))"/>
    </regex>
    <regex pattern="([|&amp;][|&amp;])[\s]*?\(" dotAll="true">
      <mutation text="$1!("/>
    </regex>
  </rules>
  <!-- This element creates a blacklist, allowing you to exclude parts from the mutations -->
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
''';
}

/// Returns the builtin mutation rules as String
String builtinMutationRules() {
  return _xmlStart()+_xmlRules()+_xmlEnd();
}

/// Returns a complete example file
String fullXMLFile() {
  return _xmlStart()+_xmlInputs()+_xmlRules()+_xmlEnd();
}






