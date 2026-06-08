import 'package:cloud_firestore/cloud_firestore.dart';

enum InviteStatus { pending, accepted }

class TeamInvite {
  const TeamInvite({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.email,
    required this.status,
    required this.invitedBy,
    required this.createdAt,
  });

  final String id;
  final String teamId;
  final String teamName;
  final String email;
  final InviteStatus status;
  final String invitedBy;
  final DateTime createdAt;

  bool get isPending => status == InviteStatus.pending;

  factory TeamInvite.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String teamId,
  }) {
    final data = doc.data()!;
    return TeamInvite(
      id: doc.id,
      teamId: teamId,
      teamName: data['teamName'] as String,
      email: data['email'] as String,
      status: data['status'] == 'accepted'
          ? InviteStatus.accepted
          : InviteStatus.pending,
      invitedBy: data['invitedBy'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'teamName': teamName,
      'email': email,
      'status': status == InviteStatus.accepted ? 'accepted' : 'pending',
      'invitedBy': invitedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
