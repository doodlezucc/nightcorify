import 'dart:html';

void onInput(InputElement input, void Function(double v) onValueChange,
    {bool writeToSibling = true}) {
  void apply() {
    var v = input.valueAsNumber;
    onValueChange(v);
    if (writeToSibling) {
      input.nextElementSibling.text = v.toStringAsFixed(0);
    }
  }

  listenApply(input.onInput, apply);
}

void listenApply(Stream stream, void Function() apply) {
  stream.listen((_) => apply());
  apply();
}
