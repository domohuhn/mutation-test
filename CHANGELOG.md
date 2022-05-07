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
