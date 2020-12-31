import 'dart:async';
import 'dart:html';
import 'dart:typed_data';
import 'dart:web_audio';

import 'dart/audio_player.dart';
import 'dart/nightcore.dart';
import 'dart/input_util.dart';

const bool buildMode = true;
const bool useTestAudio = !buildMode;
String domain = buildMode ? '' : 'http://localhost:7070';

final AnchorElement link = querySelector('#download');
InputElement urlInput;
InputElement picker;

InputElement useLimiter;
InputElement rate;
InputElement amplify;
InputElement bassboost;

NightcoreContext nc;
AudioPlayer player;

AudioBuffer buffer;

final serverNeeded = querySelectorAll('.needs-server');

void main() async {
  querySelector('#output').text = "doodlezucc's";

  registerAllSliders();

  var serverParam = Uri.parse(window.location.href).queryParameters['server'];
  if (domain.isEmpty && serverParam != null) {
    domain = serverParam;
    toggleServerFunctions(true);
  } else {
    toggleServerFunctions(false);
  }

  nc = NightcoreContext(AudioContext());

  // Initialize search/URL input
  urlInput = document.getElementById('url')
    ..onKeyDown.listen((e) {
      if (e.keyCode == 13) onUrl();
    });

  // Initialize file picker
  picker = document.getElementById('picker')
    ..onChange.listen((_) {
      var reader = FileReader();
      reader.onLoad.listen((event) {
        player.changeSource(
            (reader.result as Uint8List).buffer, picker.files[0].name);
      });
      reader.readAsArrayBuffer(picker.files[0]);
    });

  await nc.initialize();

  player = AudioPlayer(nc: nc);

  // Listen to slider inputs
  onInput(
    rate = document.getElementById('rate'),
    (v) => player.playbackRate = v,
    digits: 2,
  );
  listenApply(
    (useLimiter = document.getElementById('useLimiter')).onChange,
    () {
      var use = useLimiter.checked;
      useLimiter.nextElementSibling.classes.toggle('hidden', use);
      return nc.useLimiter = use;
    },
  );
  onInput(
    amplify = document.getElementById('amplify'),
    (v) => nc.amplify = v,
  );
  onInput(
    bassboost = document.getElementById('bass'),
    (v) => nc.bassboost = v,
  );

  if (useTestAudio) testAudioRead();

  querySelector('#exportWav').onClick.listen((_) => export(mp3: false));
  querySelector('#exportMp3').onClick.listen((_) => export(mp3: true));

  // Wait for first user interaction so audio context can be started
  await document.onClick.first;
  await nc.ctx.resume();
}

void toggleServerFunctions(bool enabled) {
  serverNeeded
    ..forEach((e) {
      e
        ..classes.toggle('needs-server', !enabled)
        ..title = enabled ? '' : 'This feature requires a server.';
      if (enabled) {
        e.removeAttribute('disabled');
      } else {
        e.setAttribute('disabled', '');
      }
    });
}

void testAudioRead() {
  var req = HttpRequest()..open('GET', 'test.mp3', async: true);

  req.onLoad.listen((event) {
    if (req.status >= 200 && req.status < 300) {
      player.changeSource(req.response, 'Test Audio');
    } else {
      print(req.status.toString() + ' | ' + req.statusText);
    }
  });
  req.responseType = 'arraybuffer';
  req.send();
}

void download(Blob blob, String name) async {
  link.text = 'Click to download.';
  link.setAttribute('download', name);
  link.href = Url.createObjectUrlFromBlob(blob);
  link.click();
}

Future<void> export({bool mp3 = false}) async {
  void status(String msg) {
    querySelector('#exportStatus').text = msg;
  }

  link.text = '';

  status('Initializing...');

  var offNc = OfflineNightcoreContext(
    buffer: player.buffer,
    playbackRate: player.playbackRate,
  );

  await offNc.initialize();
  offNc
    ..amplify = amplify.valueAsNumber
    ..bassboost = bassboost.valueAsNumber
    ..useLimiter = useLimiter.checked
    ..play(0);

  status('Rendering...');

  var buffer = await (offNc.ctx as OfflineAudioContext).startRendering();

  status('Exporting to WAV...');

  var blob = await convertToAudio(buffer);

  if (mp3) {
    status('Converting to MP3...');
    blob = Blob([
      await sendRequest(
        'convert',
        'arraybuffer',
        body: blob,
        method: 'POST',
      )
    ]);
  }

  download(blob, 'nightcore.' + (mp3 ? 'mp3' : 'wav'));

  status('Done!');
}

Future<Blob> convertToAudio(AudioBuffer buffer) {
  var completer = Completer<Blob>();
  var worker = Worker('js/converter.js');
  worker.onMessage.listen((event) {
    if (event.data is Blob) {
      completer.complete(event.data);
    }
  });
  worker.postMessage({
    'sampleRate': buffer.sampleRate,
    'channelL': buffer.getChannelData(0),
    'channelR': buffer.getChannelData(1),
  });

  return completer.future;
}

void displayError() {
  print('bruh');
}

Future<dynamic> sendRequest(String path, String responseType,
    {dynamic body, String method = 'GET'}) {
  var completer = Completer();

  var req = HttpRequest()..open(method, '$domain/nightcore/$path', async: true);

  req.onLoad.listen((event) {
    if (req.status >= 200 && req.status < 300) {
      completer.complete(req.response);
    } else {
      completer.complete();
      displayError();
    }
  });
  req.onError.listen((_) => displayError());
  req.responseType = responseType;
  req.send(body);

  return completer.future;
}

Future<void> requestYouTubeAudio(String query, [dynamic body]) async {
  var oldName = player.fileName;
  player.fileName = 'Searching...';
  var info = await sendRequest('info?q=$query', 'json');
  if (info == null) {
    player.fileName = oldName;
    displayError();
  } else {
    var audio = await sendRequest('audio?id=' + info['id'], 'arraybuffer');
    await player.changeSource(audio, info['title']);
  }
}

void onUrl() {
  var text = urlInput.value;
  if (text.isNotEmpty) {
    requestYouTubeAudio(text);
  }
}
