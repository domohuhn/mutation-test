// Copyright 2021, domohuhn.
// License: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:mutation_test/src/mutations.dart';
import 'package:mutation_test/src/replacements.dart';
import 'package:mutation_test/src/range.dart';
import 'package:test/test.dart';

void main() {
  var mut = Mutation(0, 'aaa');
  mut.replacements.addAll([
    LiteralReplacement('bbb'),
    LiteralReplacement('ccc'),
    LiteralReplacement('ddd')
  ]);
  var text = 'moo aaa xxx aaa';

  test('Mutation Iteration with literal replacement', () {
    var index = 0;
    final expected = [
      'moo bbb xxx aaa',
      'moo ccc xxx aaa',
      'moo ddd xxx aaa',
      'moo aaa xxx bbb',
      'moo aaa xxx ccc',
      'moo aaa xxx ddd'
    ];
    for (final modified in mut.allMutations(text, [], [])) {
      expect(modified.text, expected[index]);
      index += 1;
    }
  });

  var exclusion = RegexRange(RegExp(r'/[*].*?[*]/', dotAll: true));
  test('Mutation Iteration with literal replacement in exclusion', () {
    var index = 0;
    var text2 = 'moo /* aaa */ xxx /* aaa */';
    for (final modified in mut.allMutations(text2, [], [exclusion])) {
      index += 1;
      print(modified);
    }
    expect(index, 0);
  });

  test('Mutation with whitelist', () {
    var whitelist = LineRange(3, 10);
    var index = 0;
    var text2 = 'aaa \n aaa \n aaa \n aaa \n';
    final expected = [
      'aaa \n aaa \n bbb \n aaa \n',
      'aaa \n aaa \n ccc \n aaa \n',
      'aaa \n aaa \n ddd \n aaa \n',
      'aaa \n aaa \n aaa \n bbb \n',
      'aaa \n aaa \n aaa \n ccc \n',
      'aaa \n aaa \n aaa \n ddd \n'
    ];
    for (final modified in mut.allMutations(text2, [whitelist], [])) {
      expect(modified.text, expected[index]);
      index += 1;
      if (index == 1) {
        expect(modified.line.toMarkdown(), '''Line 3:<br>
&nbsp;&nbsp;&nbsp;&nbsp;<span style="background-color: rgb(255, 200, 200);">-  <span style="background-color: rgb(255, 50, 50);">aaa</span> </span><br>
&nbsp;&nbsp;&nbsp;&nbsp;<span style="background-color: rgb(200, 255, 200);">+  <span style="background-color: rgb(50, 255, 50);">bbb</span> </span><br>
''');
        expect(modified.line.toHTML(), '''Line 3:<br>
&nbsp;&nbsp;&nbsp;&nbsp;<span style="background-color: rgb(255, 200, 200);">-  <span style="background-color: rgb(255, 50, 50);">aaa</span> </span><br>
&nbsp;&nbsp;&nbsp;&nbsp;<span style="background-color: rgb(200, 255, 200);">+  <span style="background-color: rgb(50, 255, 50);">bbb</span> </span><br>
''');
        expect(modified.line.toString(), '3: "bbb"');
        expect(modified.line.formatMutatedCodeToHTML(),
            '<span class="addedLine">+  <span class="changedTokens">bbb</span> </span>');
      }
    }
    expect(index, 6);
  });
  group('regex', () {
    var reg = RegexReplacement(r'$2 masd o\r\n $3 asdas \\\\$4\t\$123a $e $1');
    test('Regex string without escape sequences', () {
      final expected = '\$2 masd o\r\n \$3 asdas \\\\\\\$4\t\$123a \$e \$1';
      expect(reg.text, expected);
    });
    var mutation2 = Mutation(0, RegExp(r'([a]+) ([b]+) ([c]+) ([d]+)'));

    var reg2 = RegexReplacement(r'($4 $3 $2 $1)');
    mutation2.replacements.add(reg2);
    mutation2.replacements.add(reg);
    test('Mutation Iteration with regex replacement', () {
      final input = 'xxx aa bbbb ccc ddd xxx';
      var index = 0;
      final expected = [
        'xxx (ddd ccc bbbb aa) xxx',
        'xxx bbbb masd o\r\n ccc asdas \\\\\\ddd\t\$123a \$e aa xxx'
      ];
      for (final modified in mutation2.allMutations(input, [], [])) {
        expect(modified.text, expected[index]);
        index += 1;
      }
    });

    test('Mutation Iteration with regex but wrong group count', () {
      var mutation3 = Mutation(0, RegExp(r'([a]+) ([b]+)'));
      mutation3.replacements.add(reg2);
      expect(() {
        final input = 'xxx aa bbbb ccc ddd xxx';
        for (final modified in mutation3.allMutations(input, [], [])) {
          print(modified.text);
        }
      }, throwsException);
    });
  });

  group('mutated line', () {
    test('mutation on linebreak', () {
      var mut = createMutatedLine(
        4,
        8,
        'smoe\n.collapsible {\nsdfsfsf\n',
        'smoe\n-.collapsible {\nsdfsfsf\n',
        Mutation(0, '.'),
      );
      expect(mut.start, 0);
      expect(
          mut.toHTML(),
          'Line 2:<br>\n'
          '&nbsp;&nbsp;&nbsp;&nbsp;<span style="background-color: rgb(255, 200, 200);">- <span style="background-color: rgb(255, 50, 50);">.co</span>llapsible {</span><br>\n'
          '&nbsp;&nbsp;&nbsp;&nbsp;<span style="background-color: rgb(200, 255, 200);">+ <span style="background-color: rgb(50, 255, 50);">-.co</span>llapsible {</span><br>\n'
          '');
      expect(mut.toMarkdown(), mut.toHTML());
      expect(mut.toString(), '2: "-.collapsible {"');
      expect(mut.formatMutatedCodeToHTML(),
          '<span class="addedLine">+ <span class="changedTokens">-.co</span>llapsible {</span>');
    });

    test('range inverted', () {
      var mut = createMutatedLine(
        8,
        4,
        'smoe\n.collapsible {\nsdfsfsf\n',
        'smoe\n-.collapsible {\nsdfsfsf\n',
        Mutation(0, '.'),
      );
      try {
        var str = 'a${mut.toHTML()}';
        str += mut.toMarkdown();
        str += mut.toString();
        str += mut.formatMutatedCodeToHTML();
        expect(str.isNotEmpty, true);
      } catch (e) {
        fail('This code should not thrwo an exception!\nGot: $e');
      }
    });

    test('out of range 1', () {
      var mut = createMutatedLine(
        -10,
        -5,
        'smoe\n.collapsible {\nsdfsfsf\n',
        'smoe\n-.collapsible {\nsdfsfsf\n',
        Mutation(0, '.'),
      );
      try {
        var str = 'a${mut.toHTML()}';
        str += mut.toMarkdown();
        str += mut.toString();
        str += mut.formatMutatedCodeToHTML();
        expect(str.isNotEmpty, true);
      } catch (e) {
        fail('This code should not thrwo an exception!\nGot: $e');
      }
    });

    test('out of range 2', () {
      var mut = createMutatedLine(
        -10,
        4,
        'smoe\n.collapsible {\nsdfsfsf\n',
        'smoe\n-.collapsible {\nsdfsfsf\n',
        Mutation(0, '.'),
      );
      try {
        var str = 'a${mut.toHTML()}';
        str += mut.toMarkdown();
        str += mut.toString();
        str += mut.formatMutatedCodeToHTML();
        expect(str.isNotEmpty, true);
      } catch (e) {
        fail('This code should not thrwo an exception!\nGot: $e');
      }
    });

    test('out of range 3', () {
      var mut = createMutatedLine(
        4,
        500,
        'smoe\n.collapsible {\nsdfsfsf\n',
        'smoe\n-.collapsible {\nsdfsfsf\n',
        Mutation(0, '.'),
      );
      try {
        var str = 'a${mut.toHTML()}';
        str += mut.toMarkdown();
        str += mut.toString();
        str += mut.formatMutatedCodeToHTML();
        expect(str.isNotEmpty, true);
      } catch (e) {
        fail('This code should not thrwo an exception!\nGot: $e');
      }
    });

    test('out of range 4', () {
      var mut = createMutatedLine(
        400,
        500,
        'smoe\n.collapsible {\nsdfsfsf\n',
        'smoe\n-.collapsible {\nsdfsfsf\n',
        Mutation(0, '.'),
      );
      try {
        var str = 'a${mut.toHTML()}';
        str += mut.toMarkdown();
        str += mut.toString();
        str += mut.formatMutatedCodeToHTML();
        expect(str.isNotEmpty, true);
      } catch (e) {
        fail('This code should not thrwo an exception!\nGot: $e');
      }
    });
  });
}
