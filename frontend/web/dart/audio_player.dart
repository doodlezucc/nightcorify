import 'dart:async';
import 'dart:html';

import 'package:meta/meta.dart';

import 'duration.dart';
import 'input_util.dart';

class AudioPlayer {
  final SpanElement timeSpan = querySelector('#currentTime');
  final InputElement timeSlider = querySelector('#time');
  final SpanElement durationSpan = querySelector('#duration');
  InputElement outVolume;

  final void Function(double v) onVolumeChange;
  final AudioElement _audio;

  bool _playing = false;

  set playbackRate(num rate) {
    _audio.playbackRate = rate;
    updateDuration();
  }

  num get playbackRate => _audio.playbackRate;

  AudioPlayer({@required this.onVolumeChange, @required AudioElement audio})
      : _audio = audio {
    initPlayPauseButton();
    initTimeSlider();
    initDuration();
    initVolume();
  }

  void setSourceUrl(String src) {
    _audio.src = src;
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
    document.getElementById('playButton').onClick.listen((event) {
      _playing = !_playing;
      (event.target as Element).classes.toggle('playing', _playing);
      if (_playing) {
        _audio.play();
      } else {
        _audio.pause();
      }
    });
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
