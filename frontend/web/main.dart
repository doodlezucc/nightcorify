import 'dart:html';

import 'dart/audio_player.dart';
import 'dart/nightcore.dart';
import 'dart/input_util.dart';

const domain = 'http://localhost:808';

InputElement urlInput;
InputElement picker;

InputElement amplify;
InputElement bassboost;

NightcoreContext nc;

AudioPlayer player;

void main() async {
  querySelector('#output').text = "doodlezucc's";

  registerAllSliders();

  AudioElement audio = document.querySelector('audio');
  nc = NightcoreContext(audio);

  // Initialize search/URL input
  urlInput = document.getElementById('url')
    ..onKeyDown.listen((e) {
      if (e.keyCode == 13) onUrl();
    });

  // Initialize file picker
  picker = document.getElementById('picker')
    ..onChange.listen((_) {
      player.setSourceUrl(Url.createObjectUrlFromBlob(picker.files[0]));
    });

  await nc.initialize();

  // Listen to slider inputs
  onInput(
    amplify = document.getElementById('amplify'),
    (v) => nc.amplify = v,
  );
  onInput(
    bassboost = document.getElementById('bass'),
    (v) => nc.bassboost = v,
  );

  player = AudioPlayer(
    onVolumeChange: (v) => nc.outputVolume = v,
    audio: audio,
  );

  // Wait for first user interaction so audio context can be started
  await document.onClick.first;
  await nc.ctx.resume();
}

void sendRequest(String action, [dynamic body]) {
  void displayError() {
    print('bruh');
  }

  var req = HttpRequest()
    ..open('GET', '$domain/nightcore/' + action, async: true);

  req.onLoad.listen((event) {
    if (req.status >= 200 && req.status < 300) {
      player.setSourceUrl(Url.createObjectUrlFromBlob(req.response));
    } else {
      print(req.status.toString() + ' | ' + req.statusText);
      displayError();
    }
  });
  req.onError.listen((event) => displayError());
  req.responseType = 'blob';
  req.send();
}

void onUrl() {
  var text = urlInput.value;
  if (text.isNotEmpty) {
    sendRequest('youtube?q=' + text);
  }
}
