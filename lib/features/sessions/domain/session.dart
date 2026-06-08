import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coachpro/core/utils/date_format.dart';
import 'package:coachpro/features/sessions/domain/session_kind.dart';

class Session {
  const Session({
    required this.id,
    required this.teamId,
    required this.kind,
    required this.sessionDate,
    required this.presentAthleteIds,
    required this.finishedAthleteIds,
    required this.createdBy,
    required this.createdAt,
    this.lapTimerStartedAt,
    this.simpleTimerElapsedMs,
    this.simpleTimerStartedAt,
  });

  final String id;
  final String teamId;
  final SessionKind kind;
  final DateTime sessionDate;
  final List<String> presentAthleteIds;
  final List<String> finishedAthleteIds;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? lapTimerStartedAt;
  final int? simpleTimerElapsedMs;
  final DateTime? simpleTimerStartedAt;

  String get displayTitle => '${kind.label} · ${formatSessionDate(sessionDate)}';

  bool isAthleteFinished(String athleteId) =>
      finishedAthleteIds.contains(athleteId);

  factory Session.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String teamId,
  }) {
    final data = doc.data()!;
    final kind = _parseKind(data);
    final sessionDate = _parseSessionDate(data);

    return Session(
      id: doc.id,
      teamId: teamId,
      kind: kind,
      sessionDate: sessionDate,
      presentAthleteIds: List<String>.from(
        data['presentAthleteIds'] as List? ?? [],
      ),
      finishedAthleteIds: List<String>.from(
        data['finishedAthleteIds'] as List? ?? [],
      ),
      createdBy: data['createdBy'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lapTimerStartedAt: (data['lapTimerStartedAt'] as Timestamp?)?.toDate() ??
          (data['startedAt'] as Timestamp?)?.toDate(),
      simpleTimerElapsedMs: data['simpleTimerElapsedMs'] as int?,
      simpleTimerStartedAt:
          (data['simpleTimerStartedAt'] as Timestamp?)?.toDate(),
    );
  }

  static SessionKind _parseKind(Map<String, dynamic> data) {
    if (data['kind'] != null) {
      return SessionKind.fromValue(data['kind'] as String);
    }
    return SessionKind.allenamento;
  }

  static DateTime _parseSessionDate(Map<String, dynamic> data) {
    if (data['sessionDate'] != null) {
      return (data['sessionDate'] as Timestamp).toDate();
    }
    if (data['createdAt'] != null) {
      return (data['createdAt'] as Timestamp).toDate();
    }
    return DateTime.now();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'kind': kind.value,
      'sessionDate': Timestamp.fromDate(sessionDate),
      'presentAthleteIds': presentAthleteIds,
      'finishedAthleteIds': finishedAthleteIds,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      if (lapTimerStartedAt != null)
        'lapTimerStartedAt': Timestamp.fromDate(lapTimerStartedAt!),
      if (simpleTimerElapsedMs != null)
        'simpleTimerElapsedMs': simpleTimerElapsedMs,
      if (simpleTimerStartedAt != null)
        'simpleTimerStartedAt': Timestamp.fromDate(simpleTimerStartedAt!),
    };
  }
}
