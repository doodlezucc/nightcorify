import 'dart:html';

import 'nightcore.dart';

const domain = 'http://localhost:808';

InputElement urlInput;
InputElement picker;
InputElement amplify;
InputElement outVolume;
InputElement bassboost;
AudioElement audio;
NightcoreContext ctx;
bool playing = false;

void main() async {
  querySelector('#output').text = 'Your Dart app is running.';

  audio = (document.querySelector('audio') as AudioElement);
  ctx = NightcoreContext(audio);
  await ctx.initialize();

  document.getElementById('playButton').onClick.listen((event) {
    playing = !playing;
    (event.target as Element).classes.toggle('playing', playing);
    if (playing) {
      if (ctx.ctx.currentTime == 0) ctx.ctx.resume();
      audio.play();
    } else {
      audio.pause();
    }
  });

  picker = document.getElementById('picker')
    ..onChange.listen((_) {
      var reader = FileReader();
      reader.onLoad.listen((_) => sendRequest('upload', reader.result));
      reader.readAsArrayBuffer(picker.files[0]);
    });

  urlInput = document.getElementById('url')
    ..onKeyDown.listen((e) {
      if (e.keyCode == 13) onUrl();
    });

  writeValueToSibling(outVolume = document.getElementById('volume'),
      (v) => ctx.outputVolume = v,
      multiply: 100);
  writeValueToSibling(
      amplify = document.getElementById('amplify'), (v) => ctx.amplify = v);
  writeValueToSibling(
      bassboost = document.getElementById('bass'), (v) => ctx.bassboost = v);
}

void writeValueToSibling(InputElement range, void Function(double v) param,
    {double multiply = 1, int digits = 0}) {
  void apply() {
    var v = range.valueAsNumber;
    param(v);
    range.nextElementSibling.text = (v * multiply).toStringAsFixed(digits);
  }

  range.onInput.listen((event) => apply());

  apply();
}

void sendRequest(action, body) {
  var req = HttpRequest()
    ..open('POST', '$domain/nightcore/' + action, async: true)
    ..responseType = 'blob';

  req
    ..onLoad.listen((event) {
      if (req.status >= 200 && req.status < 300) {
        print(req);
        audio.src = Url.createObjectUrlFromBlob(req.response);
      } else {
        print(req.status.toString() + ' | ' + req.statusText);
      }
    })
    ..setRequestHeader('Content-Type',
        action == 'upload' ? 'application/octet-stream' : 'application/json')
    ..send(body);
}

void onUrl() {
  var text = urlInput.value;
  if (text.isNotEmpty) {
    sendRequest('youtube?q=' + text, {
      'amplify': amplify.valueAsNumber,
      'bassboost': bassboost.valueAsNumber
    });
  }
}
