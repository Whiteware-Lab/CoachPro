import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coachpro/features/sessions/domain/session.dart';
import 'package:coachpro/features/sessions/domain/session_status.dart';
import 'package:coachpro/features/sessions/domain/session_type.dart';
import 'package:coachpro/features/sessions/domain/split.dart';

class SessionsRepository {
  SessionsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _sessions(String teamId) =>
      _firestore.collection('teams').doc(teamId).collection('sessions');

  CollectionReference<Map<String, dynamic>> _splits(
    String teamId,
    String sessionId,
  ) =>
      _sessions(teamId).doc(sessionId).collection('splits');

  Stream<List<Session>> watchSessions(String teamId) {
    return _sessions(teamId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Session.fromFirestore(doc, teamId: teamId))
              .toList(growable: false),
        );
  }

  Stream<Session> watchSession({
    required String teamId,
    required String sessionId,
  }) {
    return _sessions(teamId).doc(sessionId).snapshots().map((doc) {
      if (!doc.exists) {
        throw StateError('Sessione non trovata');
      }
      return Session.fromFirestore(doc, teamId: teamId);
    });
  }

  Stream<List<Split>> watchSplits({
    required String teamId,
    required String sessionId,
  }) {
    return _splits(teamId, sessionId)
        .orderBy('recordedAt')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(Split.fromFirestore).toList(growable: false),
        );
  }

  Future<Session> createSession({
    required String teamId,
    required String name,
    required SessionType type,
    required List<String> presentAthleteIds,
    required String createdBy,
  }) async {
    if (name.trim().isEmpty) {
      throw SessionsException('Il nome della sessione è obbligatorio.');
    }
    if (presentAthleteIds.isEmpty) {
      throw SessionsException('Seleziona almeno un atleta presente.');
    }

    final docRef = _sessions(teamId).doc();
    final session = Session(
      id: docRef.id,
      teamId: teamId,
      name: name.trim(),
      type: type,
      status: SessionStatus.active,
      presentAthleteIds: presentAthleteIds,
      finishedAthleteIds: const [],
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );

    await docRef.set(session.toFirestore());
    return session;
  }

  Future<void> startSession({
    required String teamId,
    required String sessionId,
  }) async {
    await _sessions(teamId).doc(sessionId).update({
      'startedAt': FieldValue.serverTimestamp(),
      'status': SessionStatus.active.value,
    });
  }

  Future<void> completeSession({
    required String teamId,
    required String sessionId,
  }) async {
    await _sessions(teamId).doc(sessionId).update({
      'endedAt': FieldValue.serverTimestamp(),
      'status': SessionStatus.completed.value,
    });
  }

  Future<void> resetSession({
    required String teamId,
    required String sessionId,
  }) async {
    final splits = await _splits(teamId, sessionId).get();
    final batch = _firestore.batch();
    for (final doc in splits.docs) {
      batch.delete(doc.reference);
    }
    batch.update(_sessions(teamId).doc(sessionId), {
      'startedAt': FieldValue.delete(),
      'endedAt': FieldValue.delete(),
      'finishedAthleteIds': [],
      'status': SessionStatus.active.value,
    });
    await batch.commit();
  }

  Future<void> recordSplit({
    required String teamId,
    required String sessionId,
    required String athleteId,
    required int elapsedMs,
  }) async {
    final existing = await _splits(teamId, sessionId)
        .where('athleteId', isEqualTo: athleteId)
        .get();
    final lapNumber = existing.docs.length + 1;

    await _splits(teamId, sessionId).add({
      'athleteId': athleteId,
      'lapNumber': lapNumber,
      'elapsedMs': elapsedMs,
      'recordedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAthleteFinished({
    required String teamId,
    required String sessionId,
    required String athleteId,
  }) async {
    await _sessions(teamId).doc(sessionId).update({
      'finishedAthleteIds': FieldValue.arrayUnion([athleteId]),
    });
  }

  Future<void> deleteSession({
    required String teamId,
    required String sessionId,
  }) async {
    final splits = await _splits(teamId, sessionId).get();
    final batch = _firestore.batch();
    for (final doc in splits.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_sessions(teamId).doc(sessionId));
    await batch.commit();
  }

  Future<void> deleteAllSessions(String teamId) async {
    final sessions = await _sessions(teamId).get();
    for (final session in sessions.docs) {
      await deleteSession(teamId: teamId, sessionId: session.id);
    }
  }
}

class SessionsException implements Exception {
  SessionsException(this.message);
  final String message;

  @override
  String toString() => message;
}
