import 'dart:async';
import 'dart:html';

import 'package:meta/meta.dart';

import 'duration.dart';
import 'input_util.dart';

class AudioPlayer {
  final SpanElement timeSpan = querySelector('#currentTime');
  final InputElement timeSlider = querySelector('#time');
  final SpanElement durationSpan = querySelector('#duration');
  final Element playButton = document.getElementById('playButton');
  InputElement outVolume;

  final void Function(double v) onVolumeChange;
  final AudioElement _audio;

  num get playbackRate => _audio.playbackRate;
  set playbackRate(num rate) {
    _audio.playbackRate = rate;
    updateDuration();
  }

  AudioPlayer({@required this.onVolumeChange, @required AudioElement audio})
      : _audio = audio {
    initPlayPauseButton();
    initTimeSlider();
    initDuration();
    initVolume();
  }

  void setSourceUrl(String src) {
    var rate = _audio.playbackRate;
    _audio.src = src;
    _audio.playbackRate = rate;
    playButton.classes.remove('playing');
    print('Changed source');
  }

  void initVolume() {
    onInput(
      outVolume = document.getElementById('volume'),
      onVolumeChange,
      writeToSibling: false,
    );
  }

  void initPlayPauseButton() {
    playButton.onClick.listen((event) {
      if (_audio.paused) {
        _audio.play();
      } else {
        _audio.pause();
      }
    });

    _audio.onPause.listen((_) => playButton.classes.remove('playing'));
    _audio.onPlay.listen((_) => playButton.classes.add('playing'));
  }

  void initDuration() {
    listenApply(_audio.onDurationChange, updateDuration);
  }

  void updateDuration() {
    durationSpan.text =
        durationString((_audio.duration / playbackRate).floor());
  }

  void initTimeSlider() {
    var isDraggingTime = false;
    timeSlider.onMouseDown.listen((_) async {
      isDraggingTime = true;
      await document.onMouseUp.first;
      _audio.currentTime = timeSlider.valueAsNumber * _audio.duration;
      isDraggingTime = false;
    });

    timeSlider.onInput.listen((_) => setTimeDisplay(
        timeSlider.valueAsNumber * _audio.duration / playbackRate));

    Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (!isDraggingTime) {
        var seconds = _audio.currentTime;
        timeSlider.valueAsNumber = seconds / _audio.duration;
        redrawSlider(timeSlider);
        setTimeDisplay(seconds / playbackRate);
      }
    });
  }

  void setTimeDisplay(num seconds) {
    timeSpan.text = durationString(seconds.floor());
  }
}
