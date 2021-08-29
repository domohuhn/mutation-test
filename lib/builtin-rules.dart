


/// Return the builtin mutation rules as String
String builtinMutationRules() {
  return r'''<?xml version="1.0" encoding="UTF-8"?>
<mutations version="1.0">
   <rules>
    <!-- Matches the literal text and replaces it with the list of mutations  -->
    <literal text="&#38;&#38;">
      <mutation text="||"/>
    </literal>
    <literal text="||">
      <mutation text="&#38;&#38;"/>
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
    <literal text="!=">
      <mutation text="=="/>
    </literal>
  </rules>
  <!-- The rules here will exclude anything that matches from the mutations -->
  <exclude>
    <!-- excludes anything between two tokens  -->
    <token begin="//" end="\n"/>
    <token begin="#" end="\n"/>
    <!-- excludes anything that matches a pattern  -->
    <!-- if the optional value dotAll is set to true, then the . will also match newlines  -->
    <!-- default is false  -->
    <regex pattern="/[*].*?[*]/" dotAll="true"/>
    <!-- exclude loops to prevent infinte tests  -->
    <regex pattern="[\s]for[\s]*\(.*?\)[\s]*{" dotAll="true"/>
    <regex pattern="[\s]while[\s]*\(.*?\)[\s]*{.*?}" dotAll="true"/>
    <!-- lines can also be excluded  -->
    <!-- line index starts at 1  -->
    <!-- lines begin="1" end="2"/-->
  </exclude>
</mutations>
''';
}








