import 'dart:html';
import 'dart:web_audio';

import 'dart/audio_player.dart';
import 'dart/nightcore.dart';
import 'dart/input_util.dart';

const domain = 'http://localhost:808';

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
      reader.onProgress.listen((event) {
        print('${event.loaded}/${event.total}');
      });
      reader.onLoad.listen((event) {
        print('ON LOAD');
        player.changeSource(reader.result);
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

  //querySelector('#export').onClick.listen((_) => export());

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

// Future<void> export() async {
//   void status(String msg) {
//     querySelector('#exportStatus').text = msg;
//   }

//   var offNc = OfflineNightcoreContext(
//     buffer: buffer,
//   );
//   status('Initializing...');
//   await offNc.initialize();
//   offNc
//     ..amplify = amplify.valueAsNumber
//     ..bassboost = bassboost.valueAsNumber;
//   OfflineAudioContext ctx = offNc.ctx;
//   status('Rendering...');
//   var buffer = await ctx.startRendering();
//   status('Exporting to WAV...');
//   convertToAudio(buffer);
//   // (querySelector('#exportResult') as AudioElement).src =
//   //     Url.createObjectUrlFromBlob(buffer);
// }

void convertToAudio(AudioBuffer buffer) {
  var worker = Worker('js/converter.js');
  worker.onMessage.listen((event) {
    print('MESSAGE FROM WORKER');
    print(event.data);
  });
  worker.postMessage(buffer);
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
