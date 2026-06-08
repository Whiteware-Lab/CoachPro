import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coachpro/features/sessions/domain/session_status.dart';
import 'package:coachpro/features/sessions/domain/session_type.dart';

class Session {
  const Session({
    required this.id,
    required this.teamId,
    required this.name,
    required this.type,
    required this.status,
    required this.presentAthleteIds,
    required this.finishedAthleteIds,
    required this.createdBy,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
  });

  final String id;
  final String teamId;
  final String name;
  final SessionType type;
  final SessionStatus status;
  final List<String> presentAthleteIds;
  final List<String> finishedAthleteIds;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;

  bool isAthleteFinished(String athleteId) =>
      finishedAthleteIds.contains(athleteId);

  factory Session.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String teamId,
  }) {
    final data = doc.data()!;
    return Session(
      id: doc.id,
      teamId: teamId,
      name: data['name'] as String,
      type: SessionType.fromValue(data['type'] as String),
      status: SessionStatus.fromValue(data['status'] as String),
      presentAthleteIds: List<String>.from(data['presentAthleteIds'] as List),
      finishedAthleteIds: List<String>.from(
        data['finishedAthleteIds'] as List? ?? [],
      ),
      createdBy: data['createdBy'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type.value,
      'status': status.value,
      'presentAthleteIds': presentAthleteIds,
      'finishedAthleteIds': finishedAthleteIds,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      if (startedAt != null) 'startedAt': Timestamp.fromDate(startedAt!),
      if (endedAt != null) 'endedAt': Timestamp.fromDate(endedAt!),
    };
  }
}
