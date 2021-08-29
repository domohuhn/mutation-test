


/// Return the builtin mutation rules as String
String builtinMutationRules() {
  return '''<?xml version="1.0" encoding="UTF-8"?>
<mutations version="1.0">
   <rules>
    <pattern text="&#38;&#38;">
      <mutation text="||"/>
    </pattern>
    <pattern text="||">
      <mutation text="&#38;&#38;"/>
    </pattern>
    <pattern text="+">
      <mutation text="-"/>
      <mutation text="*"/>
    </pattern>
    <pattern text="-">
      <mutation text="+"/>
      <mutation text="*"/>
    </pattern>
    <pattern text="*">
      <mutation text="+"/>
      <mutation text="-"/>
    </pattern>
    <pattern text="/">
      <mutation text="*"/>
      <mutation text="+"/>
    </pattern>
    <pattern text="==">
      <mutation text="!="/>
    </pattern>
    <pattern text="!=">
      <mutation text="=="/>
    </pattern>
  </rules>
  <exclude>
    <!-- excludes anything between two tokens  -->
    <token begin="//" end="\n"/>
    <token begin="#" end="\n"/>
    <!-- excludes anything that matches a pattern  -->
    <!-- if the optional value dotAll is set to true, then the . will also match newlines  -->
    <!-- default is false  -->
    <regex pattern="/[*].*?[*]/" dotAll="true"/>
    <!-- exclude loops to prevent infinte tests  -->
    <regex pattern="[\s]for[\s]*\([\s\S].*?\)[\s]*{" dotAll="true"/>
    <regex pattern="[\s]while[\s]*\([\s\S].*?\)[\s]*{" dotAll="true"/>
    <!-- lines can also be excluded  -->
    <!-- line index starts at 1  -->
    <!-- lines begin="1" end="2"/-->
  </exclude>
</mutations>
''';
}








