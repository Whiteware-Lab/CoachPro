import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coachpro/core/utils/date_format.dart';
import 'package:coachpro/features/sessions/domain/session.dart';
import 'package:coachpro/features/sessions/domain/session_kind.dart';
import 'package:coachpro/features/sessions/domain/session_note.dart';
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

  CollectionReference<Map<String, dynamic>> _notes(
    String teamId,
    String sessionId,
  ) =>
      _sessions(teamId).doc(sessionId).collection('notes');

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

  Stream<List<SessionNote>> watchNotes({
    required String teamId,
    required String sessionId,
  }) {
    return _notes(teamId, sessionId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(SessionNote.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<Session> createSession({
    required String teamId,
    required SessionKind kind,
    required DateTime sessionDate,
    required String createdBy,
  }) async {
    final docRef = _sessions(teamId).doc();
    final session = Session(
      id: docRef.id,
      teamId: teamId,
      kind: kind,
      sessionDate: dateOnly(sessionDate),
      presentAthleteIds: const [],
      finishedAthleteIds: const [],
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );

    await docRef.set(session.toFirestore());
    return session;
  }

  Future<void> updatePresentAthletes({
    required String teamId,
    required String sessionId,
    required List<String> presentAthleteIds,
  }) {
    return _sessions(teamId).doc(sessionId).update({
      'presentAthleteIds': presentAthleteIds,
    });
  }

  Future<void> startLapTimer({
    required String teamId,
    required String sessionId,
  }) async {
    await _sessions(teamId).doc(sessionId).update({
      'lapTimerStartedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> resetLapTimer({
    required String teamId,
    required String sessionId,
  }) async {
    final splits = await _splits(teamId, sessionId).get();
    final batch = _firestore.batch();
    for (final doc in splits.docs) {
      batch.delete(doc.reference);
    }
    batch.update(_sessions(teamId).doc(sessionId), {
      'lapTimerStartedAt': FieldValue.delete(),
      'finishedAthleteIds': [],
    });
    await batch.commit();
  }

  Future<void> startSimpleTimer({
    required String teamId,
    required String sessionId,
    required int baseElapsedMs,
  }) {
    return _sessions(teamId).doc(sessionId).update({
      'simpleTimerStartedAt': FieldValue.serverTimestamp(),
      'simpleTimerElapsedMs': baseElapsedMs,
    });
  }

  Future<void> stopSimpleTimer({
    required String teamId,
    required String sessionId,
    required int elapsedMs,
  }) {
    return _sessions(teamId).doc(sessionId).update({
      'simpleTimerStartedAt': FieldValue.delete(),
      'simpleTimerElapsedMs': elapsedMs,
    });
  }

  Future<void> resetSimpleTimer({
    required String teamId,
    required String sessionId,
  }) {
    return _sessions(teamId).doc(sessionId).update({
      'simpleTimerStartedAt': FieldValue.delete(),
      'simpleTimerElapsedMs': FieldValue.delete(),
    });
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
  }) {
    return _sessions(teamId).doc(sessionId).update({
      'finishedAthleteIds': FieldValue.arrayUnion([athleteId]),
    });
  }

  Future<void> addNote({
    required String teamId,
    required String sessionId,
    required String title,
    required String content,
  }) async {
    if (title.trim().isEmpty) {
      throw SessionsException('Il titolo della nota è obbligatorio.');
    }

    await _notes(teamId, sessionId).add({
      'title': title.trim(),
      'content': content.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateNote({
    required String teamId,
    required String sessionId,
    required String noteId,
    required String title,
    required String content,
  }) async {
    if (title.trim().isEmpty) {
      throw SessionsException('Il titolo della nota è obbligatorio.');
    }

    await _notes(teamId, sessionId).doc(noteId).update({
      'title': title.trim(),
      'content': content.trim(),
    });
  }

  Future<void> deleteNote({
    required String teamId,
    required String sessionId,
    required String noteId,
  }) {
    return _notes(teamId, sessionId).doc(noteId).delete();
  }

  Future<void> deleteSession({
    required String teamId,
    required String sessionId,
  }) async {
    await _deleteSubcollection(_splits(teamId, sessionId));
    await _deleteSubcollection(_notes(teamId, sessionId));
    await _sessions(teamId).doc(sessionId).delete();
  }

  Future<void> deleteAllSessions(String teamId) async {
    final sessions = await _sessions(teamId).get();
    for (final session in sessions.docs) {
      await deleteSession(teamId: teamId, sessionId: session.id);
    }
  }

  Future<void> _deleteSubcollection(
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
}

class SessionsException implements Exception {
  SessionsException(this.message);
  final String message;

  @override
  String toString() => message;
}
