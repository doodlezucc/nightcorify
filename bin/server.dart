import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;

import 'nightcore.dart';
import 'random_string.dart';

// For Google Cloud Run, set _hostname to '0.0.0.0'.
const _hostname = 'localhost';

void main(List<String> args) async {
  var doClearJobs = true;

  if (doClearJobs) {
    var jobsDir = Directory('jobs');
    if (await jobsDir.exists()) {
      await jobsDir.delete(recursive: true);
    }
    await jobsDir.create();
    print('Cleared job directory');
  }

  var parser = ArgParser()..addOption('port', abbr: 'p');
  var result = parser.parse(args);

  // For Google Cloud Run, we respect the PORT environment variable
  var portStr = result['port'] ?? Platform.environment['PORT'] ?? '7070';
  var port = int.tryParse(portStr);

  if (port == null) {
    stdout.writeln('Could not parse port value "$portStr" into a number.');
    // 64: command line usage error
    exitCode = 64;
    return;
  }

  shelf.Response _cors(shelf.Response response) => response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, X-Auth-Token',
      });

  var _fixCORS = shelf.createMiddleware(responseHandler: _cors);

  var handler = const shelf.Pipeline()
      .addMiddleware(_fixCORS)
      .addMiddleware(shelf.logRequests())
      .addHandler(_echoRequest);

  var server = await io.serve(handler, _hostname, port);
  print('Serving at http://${server.address.host}:${server.port}');
}

File uniqueFile() => File('jobs/' + getRandomString(8));

Future<File> dataToFile(List<int> data) async {
  return await uniqueFile().writeAsBytes(data);
}

Future<shelf.Response> nightcorifyFileResponse(File file) async {
  var nc = await nightcorify(file);

  return shelf.Response.ok(
    nc.openRead(),
    headers: {'Content-Type': 'audio/mpeg'},
  );
}

String getMimeType(File f) {
  switch (path.extension(f.path)) {
    case '.html':
      return 'text/html';
    case '.css':
      return 'text/css';
    case '.js':
      return 'text/javascript';
    case '.svg':
      return 'image/svg+xml';
    case '.mp3':
      return 'audio/mpeg';
  }
  return '';
}

final audioFiles = <String, File>{};

Future<String> youtubeInfo(String query) async {
  var arguments = [
    '-f',
    'bestaudio',
    '--print-json',
    '-o',
    'jobs/%(id)s',
    query.startsWith('http') ? query : 'ytsearch1:$query'
  ];
  print(arguments);
  var process = await Process.start('youtube-dl', arguments);
  String s;
  process.stdout.listen((data) => s = utf8.decode(data));
  process.stderr.listen((data) => stderr.add(data));

  var exitCode = await process.exitCode;
  print('YTDL Exit Code: $exitCode');

  return s;
}

Future<File> convertToMp3(File input) async {
  var output = File(input.path + '.mp3');
  var arguments = [
    '-i',
    input.path,
    output.path,
  ];
  print(arguments);
  var process = await Process.start('ffmpeg', arguments);
  process.stderr.listen((data) => stdout.add(data));

  var exitCode = await process.exitCode;
  print('FFMPEG Exit Code: $exitCode');

  return output;
}

var client = http.Client();

Future<shelf.Response> _echoRequest(shelf.Request request) async {
  if (request.method == 'OPTIONS') {
    return shelf.Response.ok('Request for "${request.url}"');
  }

  if (request.url.path.isEmpty) {
    return shelf.Response.seeOther('index.html');
  } else if (request.url.path.startsWith('nightcore/')) {
    var action = request.url.path.substring(10);
    var params = request.url.queryParameters;

    if (action == 'info' && params.containsKey('q')) {
      var j = await youtubeInfo(params['q']);

      return shelf.Response.ok(
        j,
        headers: {'Content-Type': 'application/json'},
      );
    } else if (action == 'audio' && params.containsKey('id')) {
      var file = File('jobs/' + params['id']);

      if (await file.exists()) {
        return shelf.Response.ok(file.openRead());
      }
    } else if (action == 'convert') {
      var input = uniqueFile();
      await input.openWrite().addStream(request.read());
      var output = await convertToMp3(input);

      if (await output.exists()) {
        return shelf.Response.ok(output.openRead());
      }
    }
  }

  var file = File('frontend/web/' + request.url.path);
  if (await file.exists()) {
    var type = getMimeType(file);
    return shelf.Response.ok(
      file.openRead(),
      headers: {'Content-Type': type},
    );
  }

  return shelf.Response.notFound('"${request.url}" not found :c');
}
