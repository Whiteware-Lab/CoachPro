import 'package:cloud_firestore/cloud_firestore.dart';

class Battery {
  const Battery({
    required this.id,
    required this.teamId,
    required this.sessionId,
    required this.name,
    required this.athleteIds,
    required this.createdAt,
  });

  final String id;
  final String teamId;
  final String sessionId;
  final String name;
  final List<String> athleteIds;
  final DateTime createdAt;

  factory Battery.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String teamId,
    required String sessionId,
  }) {
    final data = doc.data()!;
    return Battery(
      id: doc.id,
      teamId: teamId,
      sessionId: sessionId,
      name: data['name'] as String,
      athleteIds: List<String>.from(data['athleteIds'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'athleteIds': athleteIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
