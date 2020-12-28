import 'dart:html';
import 'dart:math';
import 'dart:web_audio';

class NightcoreContext {
  final BaseAudioContext ctx;
  BiquadFilterNode _filter;
  GainNode _gain;
  MediaElementAudioSourceNode _source;

  set bassboost(double dB) => _filter.gain.value = dB;
  set amplify(double dB) => _gain.gain.value = pow(10, (dB / 20));

  NightcoreContext(MediaElement source, {bool offline = false})
      : ctx = offline ? OfflineAudioContext(2) : AudioContext() {
    _filter = ctx.createBiquadFilter()
      ..type = 'peaking'
      ..frequency.value = 60
      ..Q.value = 1
      ..connectNode(ctx.destination);
    _gain = ctx.createGain()..connectNode(_filter);
    _source = ctx.createMediaElementSource(source)..connectNode(_gain);
  }
}
