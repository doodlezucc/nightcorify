import 'dart:html';

void onInput(InputElement input, void Function(double v) onValueChange,
    {bool writeToSibling = true, int digits = 0}) {
  void apply() {
    var v = input.valueAsNumber;
    onValueChange(v);
    if (writeToSibling) {
      input.nextElementSibling.text = v.toStringAsFixed(digits);
    }
  }

  listenApply(input.onInput, apply);
  input.onChange.listen((_) {
    apply();
  });
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
