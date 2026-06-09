import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coachpro/core/utils/email_utils.dart';
import 'package:coachpro/features/teams/domain/team.dart';
import 'package:coachpro/features/teams/domain/team_invite.dart';

class TeamsRepository {
  TeamsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _teams =>
      _firestore.collection('teams');

  Stream<List<Team>> watchTeams(String userId) {
    return _teams
        .where('coachIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(Team.fromFirestore).toList(growable: false),
        );
  }

  Stream<Team> watchTeam(String teamId) {
    return _teams.doc(teamId).snapshots().map((doc) {
      if (!doc.exists) {
        throw StateError('Squadra non trovata');
      }
      return Team.fromFirestore(doc);
    });
  }

  Future<Team> createTeam({
    required String name,
    required String userId,
  }) async {
    final docRef = _teams.doc();
    final team = Team(
      id: docRef.id,
      name: name.trim(),
      createdBy: userId,
      coachIds: [userId],
      createdAt: DateTime.now(),
    );

    await docRef.set(team.toFirestore());
    return team;
  }

  Future<void> deleteTeam(String teamId) async {
    final teamRef = _teams.doc(teamId);
    final teamDoc = await teamRef.get();
    if (!teamDoc.exists) {
      return;
    }

    await _deleteCollection(teamRef.collection('invites'));
    await _deleteCollection(teamRef.collection('athletes'));
    await _deleteSessions(teamId);
    await teamRef.delete();
  }

  Future<void> _deleteSessions(String teamId) async {
    final sessions = await _teams.doc(teamId).collection('sessions').get();
    for (final session in sessions.docs) {
      final subSessions =
          await session.reference.collection('subSessions').get();
      for (final subSession in subSessions.docs) {
        await _deleteCollection(subSession.reference.collection('splits'));
        await subSession.reference.delete();
      }
      await _deleteCollection(session.reference.collection('splits'));
      await _deleteCollection(session.reference.collection('notes'));
      await session.reference.delete();
    }
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final snapshot = await collection.get();
    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Stream<List<TeamInvite>> watchPendingInvites(String email) {
    final normalized = normalizeEmail(email);
    return _firestore
        .collectionGroup('invites')
        .where('email', isEqualTo: normalized)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => TeamInvite.fromFirestore(
                  doc,
                  teamId: doc.reference.parent.parent!.id,
                ),
              )
              .toList(growable: false),
        );
  }

  Stream<List<TeamInvite>> watchTeamInvites(String teamId) {
    return _teams
        .doc(teamId)
        .collection('invites')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => TeamInvite.fromFirestore(doc, teamId: teamId),
              )
              .toList(growable: false),
        );
  }

  Future<void> inviteCoach({
    required String teamId,
    required String teamName,
    required String email,
    required String invitedBy,
  }) async {
    final normalized = normalizeEmail(email);
    final inviteRef = _teams.doc(teamId).collection('invites').doc(
          inviteDocumentId(normalized),
        );

    final existing = await inviteRef.get();
    if (existing.exists && existing.data()?['status'] == 'pending') {
      throw TeamsException('Questo coach ha già un invito in sospeso.');
    }

    final invite = TeamInvite(
      id: inviteRef.id,
      teamId: teamId,
      teamName: teamName,
      email: normalized,
      status: InviteStatus.pending,
      invitedBy: invitedBy,
      createdAt: DateTime.now(),
    );

    await inviteRef.set(invite.toFirestore());
  }

  Future<void> acceptInvite({
    required String teamId,
    required String email,
    required String userId,
  }) async {
    final normalized = normalizeEmail(email);
    final inviteRef = _teams
        .doc(teamId)
        .collection('invites')
        .doc(inviteDocumentId(normalized));
    final teamRef = _teams.doc(teamId);

    final inviteDoc = await inviteRef.get();
    if (!inviteDoc.exists || inviteDoc.data()?['status'] != 'pending') {
      throw TeamsException('Invito non valido o già gestito.');
    }

    await inviteRef.update({'status': 'accepted'});
    await teamRef.update({
      'coachIds': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> acceptAllPendingInvites({
    required String email,
    required String userId,
  }) async {
    final normalized = normalizeEmail(email);
    final pending = await _firestore
        .collectionGroup('invites')
        .where('email', isEqualTo: normalized)
        .where('status', isEqualTo: 'pending')
        .get();

    for (final doc in pending.docs) {
      final teamId = doc.reference.parent.parent!.id;
      try {
        await acceptInvite(
          teamId: teamId,
          email: normalized,
          userId: userId,
        );
      } catch (_) {
        // Skip invites that fail (e.g. race conditions).
      }
    }
  }

  Future<void> cancelInvite({
    required String teamId,
    required String email,
  }) {
    return _teams
        .doc(teamId)
        .collection('invites')
        .doc(inviteDocumentId(email))
        .delete();
  }
}

class TeamsException implements Exception {
  TeamsException(this.message);
  final String message;

  @override
  String toString() => message;
}
