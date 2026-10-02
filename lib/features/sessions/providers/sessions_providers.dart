import 'package:coachpro/features/athletes/domain/athlete.dart';
import 'package:coachpro/features/sessions/data/sessions_repository.dart';
import 'package:coachpro/features/sessions/domain/battery.dart';
import 'package:coachpro/features/sessions/domain/session.dart';
import 'package:coachpro/features/sessions/domain/session_note.dart';
import 'package:coachpro/features/sessions/domain/split.dart';
import 'package:coachpro/features/sessions/domain/sub_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sessionsRepositoryProvider = Provider<SessionsRepository>(
  (ref) => SessionsRepository(),
);

final sessionsProvider = StreamProvider.family<List<Session>, String>((
  ref,
  teamId,
) {
  return ref.watch(sessionsRepositoryProvider).watchSessions(teamId);
});

final sessionProvider = StreamProvider.family<Session, SessionKey>((ref, key) {
  return ref
      .watch(sessionsRepositoryProvider)
      .watchSession(teamId: key.teamId, sessionId: key.sessionId);
});

final subSessionsProvider = StreamProvider.family<List<SubSession>, SessionKey>(
  (ref, key) {
    return ref
        .watch(sessionsRepositoryProvider)
        .watchSubSessions(teamId: key.teamId, sessionId: key.sessionId);
  },
);

final batteriesProvider = StreamProvider.family<List<Battery>, SessionKey>((
  ref,
  key,
) {
  return ref
      .watch(sessionsRepositoryProvider)
      .watchBatteries(teamId: key.teamId, sessionId: key.sessionId);
});

final batteryProvider = StreamProvider.family<Battery, BatteryKey>((ref, key) {
  return ref
      .watch(sessionsRepositoryProvider)
      .watchBattery(
        teamId: key.teamId,
        sessionId: key.sessionId,
        batteryId: key.batteryId,
      );
});

final subSessionProvider = StreamProvider.family<SubSession, SubSessionKey>((
  ref,
  key,
) {
  return ref
      .watch(sessionsRepositoryProvider)
      .watchSubSession(
        teamId: key.teamId,
        sessionId: key.sessionId,
        subSessionId: key.subSessionId,
      );
});

final subSessionSplitsProvider =
    StreamProvider.family<List<Split>, SubSessionKey>((ref, key) {
      return ref
          .watch(sessionsRepositoryProvider)
          .watchSubSessionSplits(
            teamId: key.teamId,
            sessionId: key.sessionId,
            subSessionId: key.subSessionId,
          );
    });

final sessionNotesProvider =
    StreamProvider.family<List<SessionNote>, SessionKey>((ref, key) {
      return ref
          .watch(sessionsRepositoryProvider)
          .watchNotes(teamId: key.teamId, sessionId: key.sessionId);
    });

class SessionKey {
  const SessionKey({required this.teamId, required this.sessionId});

  final String teamId;
  final String sessionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionKey &&
          teamId == other.teamId &&
          sessionId == other.sessionId;

  @override
  int get hashCode => Object.hash(teamId, sessionId);
}

class SubSessionKey {
  const SubSessionKey({
    required this.teamId,
    required this.sessionId,
    required this.subSessionId,
  });

  final String teamId;
  final String sessionId;
  final String subSessionId;

  SessionKey get sessionKey => SessionKey(teamId: teamId, sessionId: sessionId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubSessionKey &&
          teamId == other.teamId &&
          sessionId == other.sessionId &&
          subSessionId == other.subSessionId;

  @override
  int get hashCode => Object.hash(teamId, sessionId, subSessionId);
}

class BatteryKey {
  const BatteryKey({
    required this.teamId,
    required this.sessionId,
    required this.batteryId,
  });

  final String teamId;
  final String sessionId;
  final String batteryId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatteryKey &&
          teamId == other.teamId &&
          sessionId == other.sessionId &&
          batteryId == other.batteryId;

  @override
  int get hashCode => Object.hash(teamId, sessionId, batteryId);
}

List<Athlete> sortAthletesForTimer({
  required List<Athlete> athletes,
  required List<String> presentIds,
  required List<String> finishedIds,
  required List<Split> splits,
}) {
  final present = athletes
      .where(
        (athlete) =>
            presentIds.contains(athlete.id) &&
            !finishedIds.contains(athlete.id),
      )
      .toList();

  final lastTap = <String, DateTime>{};
  for (final split in splits) {
    lastTap[split.athleteId] = split.recordedAt;
  }

  present.sort((a, b) {
    final aTap = lastTap[a.id];
    final bTap = lastTap[b.id];
    if (aTap == null && bTap == null) {
      return a.name.compareTo(b.name);
    }
    if (aTap == null) {
      return -1;
    }
    if (bTap == null) {
      return 1;
    }
    return aTap.compareTo(bTap);
  });

  return present;
}

List<Athlete> finishedAthletesForSession({
  required List<Athlete> athletes,
  required List<String> finishedIds,
  required List<Split> splits,
}) {
  final finished = athletes.where((a) => finishedIds.contains(a.id)).toList();
  final totals = <String, int>{};
  for (final split in splits) {
    totals[split.athleteId] = split.elapsedMs;
  }

  finished.sort((a, b) {
    final aTotal = totals[a.id] ?? 0;
    final bTotal = totals[b.id] ?? 0;
    if (aTotal != bTotal) {
      return aTotal.compareTo(bTotal);
    }
    return a.name.compareTo(b.name);
  });

  return finished;
}
