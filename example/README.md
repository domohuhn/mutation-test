# Example files

This directory contains example files for the mutation-test program.

## Example configuration 1

This command produces the example [outputs](https://domohuhn.github.io/mutation-test/output/config-report.html).
```bash
# Run the tests in directory "example":
# Write output to docs/output
# pruduce all report file formats
./mutation-test example/config.xml -o docs/output -f all
```

## Example configuration 2

This command would performs the mutation tests on itself. Requires about 30min to complete.
```bash
# Run the tests in directory "example":
# output defaults to directory ./mutation-test-report
# report format defaults to html
./mutation-test example/config2.xml
```