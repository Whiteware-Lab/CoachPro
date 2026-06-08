import 'package:cloud_firestore/cloud_firestore.dart';

class Athlete {
  const Athlete({
    required this.id,
    required this.name,
    required this.active,
    required this.createdAt,
    this.bibNumber,
    this.notes,
  });

  final String id;
  final String name;
  final String? bibNumber;
  final String? notes;
  final bool active;
  final DateTime createdAt;

  factory Athlete.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Athlete(
      id: doc.id,
      name: data['name'] as String,
      bibNumber: data['bibNumber'] as String?,
      notes: data['notes'] as String?,
      active: data['active'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'bibNumber': bibNumber,
      'notes': notes,
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Athlete copyWith({
    String? name,
    String? bibNumber,
    String? notes,
    bool? active,
  }) {
    return Athlete(
      id: id,
      name: name ?? this.name,
      bibNumber: bibNumber ?? this.bibNumber,
      notes: notes ?? this.notes,
      active: active ?? this.active,
      createdAt: createdAt,
    );
  }
}
