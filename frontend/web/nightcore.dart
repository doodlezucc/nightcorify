import 'dart:async';
import 'dart:html';
import 'dart:math';
import 'dart:web_audio';

import 'package:js/js_util.dart' as jsu;

class NightcoreContext {
  final BaseAudioContext ctx;
  BiquadFilterNode _filter;
  GainNode _amp;
  GainNode _outGain;
  MediaElementAudioSourceNode _source;

  set bassboost(double dB) => _filter.gain.value = dB;
  set amplify(double dB) => _amp.gain.value = pow(10, (dB / 20));
  set outputVolume(double v) => _outGain.gain.value = v;

  NightcoreContext(MediaElement source, {bool offline = false})
      : ctx = offline ? OfflineAudioContext(2) : AudioContext() {
    _outGain = ctx.createGain()..connectNode(ctx.destination);
    _source = ctx.createMediaElementSource(source);
  }

  Future<void> initialize() {
    var completer = Completer();

    var worklet = jsu.getProperty(ctx, 'audioWorklet');
    jsu.callMethod(worklet, 'addModule', ['./clipper.js']).then(() {
      var clipper = AudioWorkletNode(ctx, 'clipper')..connectNode(_outGain);

      _filter = ctx.createBiquadFilter()
        ..type = 'peaking'
        ..frequency.value = 60
        ..Q.value = 0.9
        ..connectNode(clipper);

      _amp = ctx.createGain()..connectNode(_filter);

      _source.connectNode(_amp);

      completer.complete();
    });

    return completer.future;
  }
}
