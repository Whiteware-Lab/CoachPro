import 'package:cloud_firestore/cloud_firestore.dart';

class SessionNote {
  const SessionNote({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

  factory SessionNote.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SessionNote(
      id: doc.id,
      title: data['title'] as String,
      content: data['content'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
