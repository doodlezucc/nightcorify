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
const bassBoost = document.getElementById('bass');
bassBoost.oninput = writeValueToSibling;

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

function sendRequest(action, arrayBuffer) {
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

    if (action === 'upload') {
        req.setRequestHeader('Content-Type', 'application/octet-stream');
    }
    req.send(arrayBuffer);
}

function onUrl() {
    var text = urlInput.value;
    if (text.length > 0) {
        sendRequest('youtube?q=' + text);
    }
}