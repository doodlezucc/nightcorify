const audio = document.getElementsByTagName('audio')[0];
audio.volume = 0.1;

const picker = document.getElementById('picker');
picker.onchange = onFile;

const urlInput = document.getElementById('url');
urlInput.onkeydown = function(e) {
    if (e.keyCode == 13) {
        onUrl();
    }
};

const volume = document.getElementById('volume');
volume.oninput = writeValueToSibling;
const bassboost = document.getElementById('bass');
bassboost.oninput = writeValueToSibling;

function writeValueToSibling() {
    this.nextSibling.textContent = this.value;
}

function onFile() {
    const reader = new FileReader();
    reader.onload = function() {
        sendRequest('upload', reader.result);
    }
    reader.readAsArrayBuffer(picker.files[0]);
}

function sendRequest(action, body) {
    const req = new XMLHttpRequest();
    req.open('POST', 'nightcore/' + action, true);
    req.responseType = 'blob';

    req.addEventListener('load', function(event) {
        if (req.status >= 200 && req.status < 300) {
            console.log(req);
            audio.src = URL.createObjectURL(req.response);
        } else {
            console.warn(req.statusText, req.responseText);
        }
    });

    req.setRequestHeader('Content-Type', action === 'upload' ? 'application/octet-stream' : 'application/json');
    req.send(body);
}

function onUrl() {
    var text = urlInput.value;
    if (text.length > 0) {
        sendRequest('youtube?q=' + text, {
            amplify: parseFloat(volume.value),
            bassboost: parseFloat(bassboost.value)
        });
    }
}