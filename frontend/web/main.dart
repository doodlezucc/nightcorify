import 'dart:html';

const domain = 'http://localhost:808';

InputElement urlInput;
InputElement picker;
InputElement volume;
InputElement bassboost;
AudioElement audio;

void main() {
  querySelector('#output').text = 'Your Dart app is running.';

  audio = (document.querySelector('audio') as AudioElement)..volume = 0.1;

  picker = document.getElementById('picker')
    ..onChange.listen((_) {
      var reader = FileReader();
      reader.onLoad.listen((event) {
        sendRequest('upload', reader.result);
      });
      reader.readAsArrayBuffer(picker.files[0]);
    });

  urlInput = document.getElementById('url')
    ..onKeyDown.listen((e) {
      if (e.keyCode == 13) onUrl();
    });

  writeValueToSibling(volume = document.getElementById('volume'));
  writeValueToSibling(bassboost = document.getElementById('bass'));
}

void writeValueToSibling(InputElement range) {
  void apply() {
    range.nextElementSibling.text = range.value;
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
      'amplify': volume.valueAsNumber,
      'bassboost': bassboost.valueAsNumber
    });
  }
}
