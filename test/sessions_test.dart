import 'package:coachpro/core/utils/time_format.dart';
import 'package:coachpro/features/sessions/domain/split.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatElapsedMs formats minutes and centiseconds', () {
    expect(formatElapsedMs(45230), '00:45.23');
    expect(formatElapsedMs(3723000), '01:02:03.00');
  });

  test('buildAthleteStats uses last lap as total time', () {
    final splits = [
      Split(
        id: '1',
        athleteId: 'a1',
        lapNumber: 1,
        elapsedMs: 60000,
        recordedAt: DateTime(2026, 1, 1, 10),
      ),
      Split(
        id: '2',
        athleteId: 'a1',
        lapNumber: 2,
        elapsedMs: 125000,
        recordedAt: DateTime(2026, 1, 1, 10, 1),
      ),
      Split(
        id: '3',
        athleteId: 'a2',
        lapNumber: 1,
        elapsedMs: 90000,
        recordedAt: DateTime(2026, 1, 1, 10),
      ),
    ];

    final stats = buildAthleteStats(splits);

    expect(stats.length, 2);
    expect(stats.first.athleteId, 'a2');
    expect(stats.first.totalMs, 90000);
    expect(stats.last.athleteId, 'a1');
    expect(stats.last.totalMs, 125000);
    expect(stats.last.laps.length, 2);
  });
}
