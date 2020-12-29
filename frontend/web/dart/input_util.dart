import 'dart:html';

import 'dart:math' as math;

void onInput(InputElement main, void Function(double v) onValueChange,
    {bool writeToSibling = true, int digits = 0}) {
  var min = double.parse(main.min);
  var max = double.parse(main.max);
  var sib = main.nextElementSibling;

  num validate(num v) {
    if (v.isNaN) v = 0;
    return math.min(max, math.max(min, v));
  }

  void apply([InputElement a, InputElement b]) {
    var v = (a ?? main).valueAsNumber;
    v = validate(v);
    onValueChange(v);
    if (writeToSibling) {
      var vString = v.toStringAsFixed(digits);
      (b ?? sib as InputElement).value = vString;
      if (b != null) {
        _redraw(b, v, min, max);
      }
    }
  }

  if (writeToSibling && sib is InputElement) {
    sib
      ..value = main.value
      ..min = main.min
      ..max = main.max
      ..step = main.step;
    sib.onInput.listen((_) {
      apply(sib, main);
    });
    sib.onBlur.listen((_) => sib.value = main.value);
    sib.onKeyDown.listen((e) {
      // Unfocus input on Esc or Enter key
      if (e.keyCode == 13 || e.keyCode == 27) {
        sib.blur();
      }
    });
  }

  listenApply(main.onInput, apply);
  main.onChange.listen((_) => apply());
}

void listenApply(Stream stream, void Function() apply) {
  stream.listen((_) => apply());
  apply();
}

const lower = 'var(--color-main)';
const upper = '#ccc';

void registerAllSliders() {
  querySelectorAll('input[type=range]').forEach((e) => registerSlider(e));
}

void registerSlider(InputElement range) {
  var min = double.parse(range.min);
  var max = double.parse(range.max);
  onInput(range, (v) {
    _redraw(range, v, min, max);
  }, writeToSibling: false);
}

void _redraw(Element range, num v, num min, num max) {
  var value = (v - min) / (max - min) * 100;
  range.style.background =
      'linear-gradient(to right, $lower $value%, $upper $value%)';
}

void redrawSlider(InputElement range) {
  var min = double.parse(range.min);
  var max = double.parse(range.max);
  _redraw(range, range.valueAsNumber, min, max);
}
