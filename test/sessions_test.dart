import 'package:coachpro/core/utils/time_format.dart';
import 'package:coachpro/features/sessions/domain/split.dart';
import 'package:coachpro/features/sessions/domain/session.dart';
import 'package:coachpro/features/sessions/domain/session_kind.dart';
import 'package:coachpro/features/sessions/domain/sub_session.dart';
import 'package:coachpro/features/sessions/domain/sub_session_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('session uses custom name and preserves generated fallback', () {
    final base = Session(
      id: 's1',
      teamId: 't1',
      kind: SessionKind.allenamento,
      sessionDate: DateTime(2026, 10, 2),
      presentAthleteIds: const [],
      finishedAthleteIds: const [],
      createdBy: 'u1',
      createdAt: DateTime(2026, 10, 2),
    );
    final named = Session(
      id: 's2',
      teamId: 't1',
      kind: SessionKind.gara,
      sessionDate: DateTime(2026, 10, 2),
      presentAthleteIds: const [],
      finishedAthleteIds: const [],
      createdBy: 'u1',
      createdAt: DateTime(2026, 10, 2),
      name: 'Test 400 metri',
    );

    expect(base.displayTitle, base.defaultTitle);
    expect(named.displayTitle, 'Test 400 metri');
  });

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
    expect(stats.last.lapDurationMs(0), 60000);
    expect(stats.last.lapDurationMs(1), 65000);
  });

  test('sub-session participants preserve battery snapshot', () {
    final subSession = SubSession(
      id: 'p1',
      teamId: 't1',
      sessionId: 's1',
      name: '100 metri',
      type: SubSessionType.simple,
      createdAt: DateTime(2026, 1, 1),
      finishedAthleteIds: const [],
      participantAthleteIds: const ['a1', 'a2'],
    );

    expect(subSession.participantsOr(const ['legacy']), ['a1', 'a2']);
  });

  test('legacy sub-session falls back to session attendance', () {
    final subSession = SubSession(
      id: 'p1',
      teamId: 't1',
      sessionId: 's1',
      name: 'Vecchia prova',
      type: SubSessionType.lap,
      createdAt: DateTime(2026, 1, 1),
      finishedAthleteIds: const [],
    );

    expect(subSession.participantsOr(const ['a1']), ['a1']);
  });
}
