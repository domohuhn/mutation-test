import 'configuration.dart';
import 'dart:io';

class TestRunner {
  Map<String,int> groupStatistics = {};
  Map<String,int> commandStatistics = {};
  int totalFound = 0;
  int totalRuns = 0;

  
  void prepare(Configuration config) {
    for (final cmd in config.commands) {
      if (cmd.group.isNotEmpty) {
        groupStatistics[cmd.group] = 0;
      }
      if (cmd.name.isNotEmpty) {
        commandStatistics[cmd.name] = 0;
      }
    }
  }

  bool run(Configuration config) {
    totalRuns += 1;
    for (final cmd in config.commands) {
      var result = Process.runSync(cmd.command, cmd.arguments, workingDirectory: cmd.directory);
      if (result.exitCode != cmd.expectedReturnValue) {
        if (config.verbose) {
          print('Test failed: ${cmd.command} with return code ${result.exitCode}');
        }
        if (cmd.group.isNotEmpty) {
          groupStatistics.update(cmd.group, (v) => v+1, ifAbsent: () => 1);
        }
        if (cmd.name.isNotEmpty) {
          commandStatistics.update(cmd.name, (v) => v+1, ifAbsent: () => 1);
        }
        totalFound += 1;
        return false;
      }
    }
    if (config.verbose) {
      print('All Tests ok');
    }
    return true;
  }

  void printResults() {
    print('  --- Results ---');
    print('Test command statistics:');
    commandStatistics.forEach((k, v) => print('  Command : $k, Found mutations: $v'));
    print('Test group statistics:');
    groupStatistics.forEach((k, v) => print('  Group : $k, Found mutations: $v'));
    print('\nTotal tests: $totalRuns\nSurviving Mutations: ${totalRuns-totalFound-1}');
  }

  bool get foundAll => totalRuns-1-totalFound == 0;

}




