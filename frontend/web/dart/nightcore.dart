import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:web_audio';

import 'package:js/js_util.dart' as jsu;

class NightcoreContext {
  final BaseAudioContext ctx;
  BiquadFilterNode _filter;
  GainNode _amp;
  GainNode _outGain;

  AudioBuffer _buffer;
  AudioBuffer get buffer => _buffer;
  AudioBufferSourceNode _source;

  set bassboost(double dB) => _filter.gain.value = dB;
  set amplify(double dB) => _amp.gain.value = pow(10, (dB / 20));
  set outputVolume(double v) => _outGain.gain.value = v;

  double _rate = 1;
  double get playbackRate => _rate;
  set playbackRate(double rate) {
    _rate = rate;
    _source?.playbackRate?.value = rate;
  }

  NightcoreContext(this.ctx) {
    _outGain = ctx.createGain()..connectNode(ctx.destination);
  }

  Future<void> setBufferBytes(ByteBuffer audioData) async {
    _buffer = await ctx.decodeAudioData(audioData);
  }

  AudioBufferSourceNode play(num offset) {
    _source?.disconnect();

    return _source = ctx.createBufferSource()
      ..buffer = _buffer
      ..playbackRate.value = playbackRate
      ..connectNode(_amp)
      ..start(ctx.currentTime, offset);
  }

  void stopPlaying() {
    _source?.stop(ctx.currentTime);
  }

  Future<void> initialize() {
    var completer = Completer();

    var worklet = jsu.getProperty(ctx, 'audioWorklet');
    jsu.callMethod(worklet, 'addModule', ['../js/clipper.js']).then(() {
      var clipper = AudioWorkletNode(ctx, 'clipper')..connectNode(_outGain);

      _filter = ctx.createBiquadFilter()
        ..type = 'peaking'
        ..frequency.value = 60
        ..Q.value = 0.9
        ..connectNode(clipper);

      _amp = ctx.createGain()..connectNode(_filter);

      completer.complete();
    });

    return completer.future;
  }
}

class OfflineNightcoreContext extends NightcoreContext {
  OfflineNightcoreContext(
      {AudioBuffer buffer, int sampleRate = 44100, double playbackRate})
      : super(OfflineAudioContext(
            2, sampleRate * buffer.duration ~/ playbackRate, sampleRate)) {
    _buffer = buffer;
    _rate = playbackRate;
  }
}
