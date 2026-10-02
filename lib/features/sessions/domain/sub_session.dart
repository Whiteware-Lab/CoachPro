import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coachpro/features/sessions/domain/sub_session_type.dart';

class SubSession {
  const SubSession({
    required this.id,
    required this.teamId,
    required this.sessionId,
    required this.name,
    required this.type,
    required this.createdAt,
    required this.finishedAthleteIds,
    this.batteryId,
    this.batteryName,
    this.participantAthleteIds,
    this.endedAt,
    this.timerStartedAt,
    this.timerElapsedMs,
  });

  final String id;
  final String teamId;
  final String sessionId;
  final String name;
  final SubSessionType type;
  final DateTime createdAt;
  final DateTime? endedAt;
  final DateTime? timerStartedAt;
  final int? timerElapsedMs;
  final List<String> finishedAthleteIds;
  final String? batteryId;
  final String? batteryName;
  final List<String>? participantAthleteIds;

  bool get isActive => endedAt == null;

  bool isAthleteFinished(String athleteId) =>
      finishedAthleteIds.contains(athleteId);

  List<String> participantsOr(List<String> legacyPresentAthleteIds) =>
      participantAthleteIds ?? legacyPresentAthleteIds;

  factory SubSession.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String teamId,
    required String sessionId,
  }) {
    final data = doc.data()!;
    return SubSession(
      id: doc.id,
      teamId: teamId,
      sessionId: sessionId,
      name: data['name'] as String,
      type: SubSessionType.fromValue(data['type'] as String),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
      timerStartedAt: (data['timerStartedAt'] as Timestamp?)?.toDate(),
      timerElapsedMs: data['timerElapsedMs'] as int?,
      finishedAthleteIds: List<String>.from(
        data['finishedAthleteIds'] as List? ?? [],
      ),
      batteryId: data['batteryId'] as String?,
      batteryName: data['batteryName'] as String?,
      participantAthleteIds: data.containsKey('participantAthleteIds')
          ? List<String>.from(data['participantAthleteIds'] as List? ?? [])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type.value,
      'createdAt': Timestamp.fromDate(createdAt),
      if (endedAt != null) 'endedAt': Timestamp.fromDate(endedAt!),
      if (timerStartedAt != null)
        'timerStartedAt': Timestamp.fromDate(timerStartedAt!),
      if (timerElapsedMs != null) 'timerElapsedMs': timerElapsedMs,
      'finishedAthleteIds': finishedAthleteIds,
      if (batteryId != null) 'batteryId': batteryId,
      if (batteryName != null) 'batteryName': batteryName,
      if (participantAthleteIds != null)
        'participantAthleteIds': participantAthleteIds,
    };
  }
}
