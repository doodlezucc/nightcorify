import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

void main(List<String> args) {
  nightcorify(File('tests/hmltn.mp3')).then((value) => print(value));
}

Future<void> finishffmpeg(Process process) async {
  var completer = Completer();

  process.stderr.listen(
    (data) {
      stdout.add(data);
    },
    onDone: () => completer.complete(),
  );

  return await completer.future;
}

Future<int> getSampleRate(File f) async {
  var ffprobe = await Process.start('ffprobe', [
    '-v',
    '0',
    '-select_streams',
    'a:0',
    '-show_entries',
    'stream=sample_rate',
    '-of',
    'compact=p=0:nk=1',
    f.path,
  ]);
  var completer = Completer<int>();
  ffprobe.stdout.listen(
    (data) {
      var s = utf8.decode(data).trim();
      completer.complete(int.parse(s));
    },
  );
  return await completer.future;
}

Future<File> nightcorify(File input, {double playbackRate = 1.3}) async {
  var sampleRate = await getSampleRate(input);
  var output = File('jobs/${path.basenameWithoutExtension(input.path)}-nc.mp3');
  var process = await Process.start('ffmpeg', [
    '-i',
    input.path,
    '-af',
    "asetrate=$sampleRate*$playbackRate,aresample=$sampleRate,firequalizer=gain_entry='entry(0,0);entry(100,30);entry(150,0)',volume=50",
    '-y',
    output.path,
  ]);
  await finishffmpeg(process);
  print('Done!');
  return output;
}
