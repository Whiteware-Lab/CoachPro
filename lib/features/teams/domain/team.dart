import 'package:cloud_firestore/cloud_firestore.dart';

class Team {
  const Team({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.coachIds,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String createdBy;
  final List<String> coachIds;
  final DateTime createdAt;

  bool isCreator(String userId) => createdBy == userId;

  factory Team.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Team(
      id: doc.id,
      name: data['name'] as String,
      createdBy: data['createdBy'] as String,
      coachIds: List<String>.from(data['coachIds'] as List),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'createdBy': createdBy,
      'coachIds': coachIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
