


/// Return the builtin mutation rules as String
String builtinMutationRules() {
  return r'''<?xml version="1.0" encoding="UTF-8"?>
<mutations version="1.0">
   <rules>
    <!-- Matches the literal text and replaces it with the list of mutations  -->
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
  <!-- The rules here will exclude anything that matches from the mutations -->
  <exclude>
    <!-- excludes anything between two tokens  -->
    <token begin="//" end="\n"/>
    <token begin="#" end="\n"/>
    <!-- excludes anything that matches a pattern  -->
    <regex pattern="/[*].*?[*]/" dotAll="true"/>
    <!-- exclude loops to prevent infinte tests  -->
    <regex pattern="[\s]for[\s]*\(.*?\)[\s]*{" dotAll="true"/>
    <regex pattern="[\s]while[\s]*\(.*?\)[\s]*{.*?}" dotAll="true"/>
    <!-- lines can also be globally excluded  -->
    <!-- line index starts at 1  -->
    <!-- lines begin="1" end="2"/-->
  </exclude>
</mutations>
''';
}








