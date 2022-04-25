/// Copyright 2021, domohuhn. 
/// License: BSD-3-Clause
/// See LICENSE for the full text of the license

import 'package:mutation_test/mutations.dart';
import 'package:mutation_test/replacements.dart';
import 'package:mutation_test/range.dart';
import 'package:test/test.dart';

void main() {
  var mut = Mutation('aaa');
  mut.replacements.addAll([LiteralReplacement('bbb'),LiteralReplacement('ccc'),LiteralReplacement('ddd')]);
  var text = 'moo aaa xxx aaa';

  var reg = RegexReplacement(r'$2 masd o\n $3 asdas \\\\$4 \$123a $e $1');

  test('Mutation Iteration with literal replacement', () {
    var index = 0;
    final expected = ['moo bbb xxx aaa','moo ccc xxx aaa','moo ddd xxx aaa', 'moo aaa xxx bbb','moo aaa xxx ccc','moo aaa xxx ddd'];
    for(final modified in mut.allMutations(text,[],[])) {
      expect(modified.text,expected[index]);
      index += 1;
    }
  });
  
  var exclusion = RegexRange(RegExp(r'/[*].*?[*]/',dotAll: true));
  test('Mutation Iteration with literal replacement in exclusion', () {
    var index = 0;
    var text2 = 'moo /* aaa */ xxx /* aaa */';
    for(final modified in mut.allMutations(text2,[],[exclusion])) {
      index += 1;
    }
    expect(index,0);
  });

  test('Mutation with whitelist', () {
    var whitelist = LineRange(3, 10);
    var index = 0;
    var text2 = 'aaa \n aaa \n aaa \n aaa \n';
    final expected = ['aaa \n aaa \n bbb \n aaa \n','aaa \n aaa \n ccc \n aaa \n','aaa \n aaa \n ddd \n aaa \n',
                    'aaa \n aaa \n aaa \n bbb \n','aaa \n aaa \n aaa \n ccc \n','aaa \n aaa \n aaa \n ddd \n'];
    for(final modified in mut.allMutations(text2,[whitelist],[])) {
      expect(modified.text,expected[index]);
      index += 1;
      if(index==1) {
        expect(modified.line.toMarkdown(), '''Line 3:<br>
&nbsp;&nbsp;&nbsp;&nbsp;<span style="background-color: rgb(255, 200, 200);">-  <span style="background-color: rgb(255, 50, 50);">aaa</span> </span><br>
&nbsp;&nbsp;&nbsp;&nbsp;<span style="background-color: rgb(200, 255, 200);">+  <span style="background-color: rgb(50, 255, 50);">bbb</span> </span><br>
''');
        expect(modified.line.toHTML(), '''Line 3:<br>
&nbsp;&nbsp;&nbsp;&nbsp;<span style="background-color: rgb(255, 200, 200);">-  <span style="background-color: rgb(255, 50, 50);">aaa</span> </span><br>
&nbsp;&nbsp;&nbsp;&nbsp;<span style="background-color: rgb(200, 255, 200);">+  <span style="background-color: rgb(50, 255, 50);">bbb</span> </span><br>
''');
        expect(modified.line.toString(), '3: "bbb"');
      }
    }
    expect(index,6);
  });

  test('Regex string without escape sequences', () {
    final expected = '\$2 masd o\n \$3 asdas \\\\\\\$4 \$123a \$e \$1';
    expect(reg.text, expected);
  });

  var mutation2 = Mutation(RegExp(r'([a]+) ([b]+) ([c]+) ([d]+)'));
  
  var reg2 = RegexReplacement(r'($4 $3 $2 $1)');
  mutation2.replacements.add(reg2);
  mutation2.replacements.add(reg);
  test('Mutation Iteration with regex replacement', () {
    final input = 'xxx aa bbbb ccc ddd xxx';
    var index = 0;
    final expected = ['xxx (ddd ccc bbbb aa) xxx',
    'xxx bbbb masd o\n ccc asdas \\\\\\ddd \$123a \$e aa xxx'];
    for(final modified in mutation2.allMutations(input,[],[])) {
      expect(modified.text,expected[index]);
      index += 1;
    }
  });

  test('Mutation Iteration with regex but wrong group count', () {
    var mutation3 = Mutation(RegExp(r'([a]+) ([b]+)'));
    mutation3.replacements.add(reg2);
    expect((){
      final input = 'xxx aa bbbb ccc ddd xxx';
      for(final modified in mutation3.allMutations(input,[],[])) {
        print(modified.text);
      }
    }, throwsException);
  });

}
