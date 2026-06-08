String formatElapsedMs(int milliseconds, {bool showMillis = true}) {
  final totalSeconds = milliseconds ~/ 1000;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  final millis = (milliseconds % 1000) ~/ 10;

  final hoursPart = hours > 0 ? '${hours.toString().padLeft(2, '0')}:' : '';
  final base =
      '$hoursPart${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

  if (!showMillis) {
    return base;
  }
  return '$base.${millis.toString().padLeft(2, '0')}';
}
