import 'dart:async';
import 'dart:html';
import 'dart:typed_data';
import 'dart:web_audio';

import 'package:meta/meta.dart';

import 'duration.dart';
import 'input_util.dart';
import 'nightcore.dart';

class AudioPlayer {
  final SpanElement timeSpan = querySelector('#currentTime');
  final InputElement timeSlider = querySelector('#time');
  final SpanElement durationSpan = querySelector('#duration');
  final Element playButton = document.getElementById('playButton');
  InputElement outVolume;

  final NightcoreContext nc;

  num _lastInteractTime = 0; // last context time media was started/stopped
  num currentTime = 0;

  AudioContext get ctx => nc.ctx;
  AudioBuffer get buffer => nc.buffer;

  num get playbackRate => nc.playbackRate;
  set playbackRate(num rate) {
    if (playing) {
      currentTime += (ctx.currentTime - _lastInteractTime) * playbackRate;
    }
    _lastInteractTime = ctx.currentTime;
    nc.playbackRate = rate;
    _updateDuration();
    _calculateTime();
  }

  bool _playing = false;
  bool get playing => _playing;
  set playing(bool v) {
    _playing = v;
    playButton.classes.toggle('playing', v);
    if (v) {
      nc.play(currentTime);
    } else {
      currentTime += ctx.currentTime - _lastInteractTime;
      nc.stopPlaying();
    }
    _lastInteractTime = ctx.currentTime;
  }

  AudioPlayer({@required this.nc}) {
    _initPlayPauseButton();
    _initTimeSlider();
    _initVolume();
  }

  Future<void> changeSource(ByteBuffer audioData) async {
    await nc.setBufferBytes(audioData);
    _onStop();
    _updateDuration();
    print('Changed source');
  }

  void _initVolume() {
    onInput(
      outVolume = document.getElementById('volume'),
      (v) => nc.outputVolume = v,
      writeToSibling: false,
    );
  }

  void _initPlayPauseButton() {
    playButton.onClick.listen((_) => playing = !playing);
  }

  void _onStop() {
    currentTime = 0;
    playButton.classes.remove('playing');
  }

  void _updateDuration() {
    durationSpan.text =
        durationString(((buffer?.duration ?? 0) / playbackRate).floor());
  }

  void _initTimeSlider() {
    var isDraggingTime = false;
    timeSlider.onMouseDown.listen((_) async {
      isDraggingTime = true;
      await document.onMouseUp.first;
      currentTime = timeSlider.valueAsNumber * buffer.duration;
      _lastInteractTime = ctx.currentTime;
      isDraggingTime = false;
      if (playing) {
        nc.stopPlaying();
        nc.play(currentTime);
      }
    });

    timeSlider.onInput.listen((_) => setTimeDisplay(
        timeSlider.valueAsNumber * buffer.duration / playbackRate));

    Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (!isDraggingTime && playing) _calculateTime();
    });
  }

  void _calculateTime() {
    var scaledDuration = (buffer?.duration ?? 0) / playbackRate;

    var seconds =
        ctx.currentTime - _lastInteractTime + currentTime / playbackRate;

    if (playing && seconds >= scaledDuration) {
      playing = false;
      seconds = 0;
      currentTime = 0;
    }
    timeSlider.valueAsNumber = seconds / scaledDuration;
    redrawSlider(timeSlider);
    setTimeDisplay(seconds);
  }

  void setTimeDisplay(num seconds) {
    timeSpan.text = durationString(seconds.floor());
  }
}
