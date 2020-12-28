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
  final AudioElement audio;

  bool playing = false;

  AudioPlayer({@required this.onVolumeChange, @required this.audio}) {
    initPlayPauseButton();
    initTimeSlider();
    initDuration();
    initVolume();
  }

  void setSourceUrl(String src) {
    audio.src = src;
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
      playing = !playing;
      (event.target as Element).classes.toggle('playing', playing);
      if (playing) {
        print(audio);
        print(audio.src);
        audio.play();
      } else {
        audio.pause();
      }
    });
  }

  void initDuration() {
    listenApply(audio.onDurationChange, () {
      durationSpan.text = durationString(audio.duration.floor());
    });
  }

  void initTimeSlider() {
    var isDraggingTime = false;
    timeSlider.onMouseDown.listen((_) async {
      isDraggingTime = true;
      await document.onMouseUp.first;
      audio.currentTime = timeSlider.valueAsNumber * audio.duration;
      isDraggingTime = false;
    });

    timeSlider.onInput.listen(
        (_) => setTimeDisplay(timeSlider.valueAsNumber * audio.duration));

    Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (!isDraggingTime) {
        var seconds = audio.currentTime;
        timeSlider.valueAsNumber = seconds / audio.duration;
        setTimeDisplay(seconds);
      }
    });
  }

  void setTimeDisplay(num seconds) {
    timeSpan.text = durationString(seconds.floor());
  }
}
