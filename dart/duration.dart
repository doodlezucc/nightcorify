String durationString(int sec) {
  var out = (sec % Duration.secondsPerMinute).toString().padLeft(2, '0');
  var min = (sec ~/ 60) % Duration.minutesPerHour;
  var h = ((sec / 60) ~/ 60);
  if (h > 0) {
    out = '$h:' + min.toString().padLeft(2, '0') + ':$out';
  } else {
    out = '$min:$out';
  }
  return out;
}
