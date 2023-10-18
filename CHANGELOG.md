## 1.6.0
 - Added the option to exclude lines not covered by tests. You can pass a file with coverage information in the lcov format via
   the command line flag "--coverage".
 - Added the (experimental) option to strings from the mutations via command line switch.

## 1.5.1
 - Fixed a bug that causes the mutation test to stop in case the mutation reduces the code size near the end of the file.

## 1.5.0
 - Optional function arguments are no longer swapped
 - If no test command is given, the program will try to infer it from pubspec.yaml
 - A single invocation of the program will now always produce a single report named mutation-test in the given output directory

## 1.4.0
 - Added junit/xunit style XML reports to conform to the standard for test tools.
   It should now be possible to upload the results in tools like Polarion.
 - Performing a dry run will now generate the specified outputs. All mutations
   defined by the rules will be marked as undetected.
 - Added optional "id" attribute to rules in the xml configuration file
 - xml configuration file version increased to 1.1
 - Added a column in the generated html report that shows the mutation pattern and id
 - Require dart 3

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
 - Added exclusion rules for dart import and export statements in the default rule set.

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
