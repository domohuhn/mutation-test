import 'package:pedantic/pedantic.dart';
import 'package:test/test.dart';
import 'dart:io';
import 'dart:convert';




void main() async {
  test('Timeout test', () async {
    var timedout = false;
    print('Start!');
    var stopwatch = Stopwatch();
    stopwatch.start();
    var future = await Process.start('ping', ['127.0.0.1', '-n','4']);
    
    var stdout = '';
    var moo1 = future.stdout.transform(Utf8Decoder(allowMalformed: true)).forEach((e) { stdout += e; });
    var stderr = '';
    var moo2 = future.stderr.transform(Utf8Decoder(allowMalformed: true)).forEach((e) { stderr += e; });
    
    var exitCode = await future.exitCode.timeout(Duration(seconds: 10),onTimeout: (){
      print('Time out after: ${stopwatch.elapsed}!');
      future.kill(ProcessSignal.sigterm);
      timedout = true;
      return -1;
    });
    await moo1;
    await moo2;

    print('moo: ${stopwatch.elapsed} $timedout => ec: $exitCode');
    print('stdout: "$stdout"');
    print('stderr: "$stderr"');
  });
}


