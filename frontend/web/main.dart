import 'dart:async';
import 'dart:html';
import 'dart:typed_data';
import 'dart:web_audio';

import 'dart/audio_player.dart';
import 'dart/nightcore.dart';
import 'dart/input_util.dart';

const domain = 'http://localhost:808';

final AnchorElement link = querySelector('#download');
InputElement urlInput;
InputElement picker;

InputElement rate;
InputElement amplify;
InputElement bassboost;

NightcoreContext nc;
AudioPlayer player;

AudioBuffer buffer;

void main() async {
  querySelector('#output').text = "doodlezucc's";

  registerAllSliders();

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
        player.changeSource((reader.result as Uint8List).buffer);
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
  onInput(
    amplify = document.getElementById('amplify'),
    (v) => nc.amplify = v,
  );
  onInput(
    bassboost = document.getElementById('bass'),
    (v) => nc.bassboost = v,
  );

  testAudioRead();

  querySelector('#export').onClick.listen((_) => export());

  // Wait for first user interaction so audio context can be started
  await document.onClick.first;
  await nc.ctx.resume();
}

void testAudioRead() {
  var req = HttpRequest()..open('GET', 'faber.mp3', async: true);

  req.onLoad.listen((event) {
    if (req.status >= 200 && req.status < 300) {
      player.changeSource(req.response);
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

Future<void> export() async {
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
    ..play(0);

  status('Rendering...');

  var buffer = await (offNc.ctx as OfflineAudioContext).startRendering();

  status('Exporting to WAV...');

  var blob = await convertToAudio(buffer);

  download(blob, 'nightcore.wav');

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

void sendRequest(String action, [dynamic body]) {
  void displayError() {
    print('bruh');
  }

  var req = HttpRequest()
    ..open('GET', '$domain/nightcore/' + action, async: true);

  req.onLoad.listen((event) {
    if (req.status >= 200 && req.status < 300) {
      player.changeSource(req.response);
    } else {
      print(req.status.toString() + ' | ' + req.statusText);
      displayError();
    }
  });
  req.onError.listen((event) => displayError());
  req.responseType = 'arraybuffer';
  req.send();
}

void onUrl() {
  var text = urlInput.value;
  if (text.isNotEmpty) {
    sendRequest('youtube?q=' + text);
  }
}
