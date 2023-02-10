import 'package:mutation_test/src/builtin_rules.dart';
import 'package:mutation_test/src/configuration.dart';
import 'package:test/test.dart';

void main() {
  test('Switch 2 function arguments 1', () {
    final configuration = Configuration(false, true);
    configuration.parseXMLString(builtinMutationRules());
    final testSource = '''
double testfunc(double x) {
  double y = other(x);
  return add(x,y);
}
''';
    for (final mut in configuration.mutations) {
      for (final moo in mut.allMutations(testSource, [], [])) {
        expect(moo.line.start, 8);
        expect(moo.line.end, 18);
        expect(moo.line.mutated, '  return add(y,x);');
        expect(moo.line.original, '  return add(x,y);');
      }
    }
  });

  test('Switch 2 function arguments 2', () {
    final configuration = Configuration(false, true);
    configuration.parseXMLString(builtinMutationRules());
    final testSource = '''
// somestuff

super(name, false) {
  throw Err('bla name');
}
''';
    for (final mut in configuration.mutations) {
      for (final moo
          in mut.allMutations(testSource, [], configuration.exclusions)) {
        print(moo);
        fail('There should be no matches!');
      }
    }
  });

  test('Switch 3 function arguments', () {
    final configuration = Configuration(false, true);
    configuration.parseXMLString(builtinMutationRules());
    final testSource = '''
double testfunc(double x) {
  double y = other(x);
  return add(x,y,x);
}
''';
    for (final mut in configuration.mutations) {
      for (final moo in mut.allMutations(testSource, [], [])) {
        expect(moo.line.start, 8);
        expect(moo.line.end, 20);
      }
    }
  });

  test('Switch 3 function arguments 2', () {
    final configuration = Configuration(false, true);
    configuration.parseXMLString(builtinMutationRules());
    final testSource = '''
// somestuff

super(name, false) {
  throw Err('bla name',two);
}
''';
    for (final mut in configuration.mutations) {
      for (final moo
          in mut.allMutations(testSource, [], configuration.exclusions)) {
        expect(moo.line.line, 4);
      }
    }
  });

  test('Switch 4 function arguments', () {
    final configuration = Configuration(false, true);
    configuration.parseXMLString(builtinMutationRules());
    final testSource = '''
double testfunc(double x) {
  double y = other(x);
  return add(x,y,z,a);
}
''';
    for (final mut in configuration.mutations) {
      for (final moo in mut.allMutations(testSource, [], [])) {
        expect(moo.line.start, 8);
        expect(moo.line.end, 22);
      }
    }
  });

  test('Switch 4 function arguments 2', () {
    final configuration = Configuration(false, true);
    configuration.parseXMLString(builtinMutationRules());
    final testSource = '''
// somestuff

super(name, false) {
  throw Err('bla name',two,three);
}
''';
    for (final mut in configuration.mutations) {
      for (final moo
          in mut.allMutations(testSource, [], configuration.exclusions)) {
        expect(moo.line.line, 4);
      }
    }
  });
}
