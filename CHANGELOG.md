## 1.3.4
 - Improved mutation rules that switch function arguments
 - Updated dependencies

## 1.3.3
 - Improve builtin rules with operators like "+=". There should be less useless mutations that are always detected now.
 - The \<exclude\> element in xml rule definitions now supports the exclusion of files by listing them as \<file\> element.

## 1.3.2
 - Added builtin rules to swap arguments on function calls.
 - Added a dark theme (prefers-color-scheme: dark) for html reports.

## 1.3.1
 - Fixed bugs when creating reports.
 - Added additional unit tests so that the files are listed in coverage metrics

## 1.3.0
 - Files without mutations are now no longer reported as NaN % mutations
 - Detected and mutations with timeouts are reported in the generated html
 - Updated the builtin rules to not test for +-0 and to exclude ++ and --

## 1.2.2
 - Fixed minor problems with the generated html files. Source code strings are escaped and a table was fixed.

## 1.2.1
 - Renamed executable to "mutation_test" follow dart file conventions.
 - Added exclusion rules for dart import and export statements in the default ruleset.

## 1.2.0

- Html reports are prettier. The look of the files is inspired by the lcov reports.
- Running the program without any arguments no longer causes an error. Instead, the program
  will assume that you are using a dart project, so alle files in lib/ will be mutated and
  tested via dart test.

## 1.1.2

- Licenses of transitive dependencies are now also shown with argument "--about"

## 1.1.1

- All licenses are automatically collected and displayed via about
- The progress bars for file and total have the same length
- Archives should have correct layout for linux and mac


## 1.1.0

- Fixed bug on release creation
- Multiple rules can be provided via command line
- Input files can be source files and not just xml

## 1.0.0

- Initial version.
