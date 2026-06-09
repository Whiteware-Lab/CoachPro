import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coachpro/core/utils/date_format.dart';
import 'package:coachpro/features/sessions/domain/session.dart';
import 'package:coachpro/features/sessions/domain/session_kind.dart';
import 'package:coachpro/features/sessions/domain/session_note.dart';
import 'package:coachpro/features/sessions/domain/split.dart';
import 'package:coachpro/features/sessions/domain/sub_session.dart';
import 'package:coachpro/features/sessions/domain/sub_session_type.dart';

class SessionsRepository {
  SessionsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _sessions(String teamId) =>
      _firestore.collection('teams').doc(teamId).collection('sessions');

  CollectionReference<Map<String, dynamic>> _subSessions(
    String teamId,
    String sessionId,
  ) =>
      _sessions(teamId).doc(sessionId).collection('subSessions');

  CollectionReference<Map<String, dynamic>> _subSessionSplits(
    String teamId,
    String sessionId,
    String subSessionId,
  ) =>
      _subSessions(teamId, sessionId)
          .doc(subSessionId)
          .collection('splits');

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

  Stream<List<SubSession>> watchSubSessions({
    required String teamId,
    required String sessionId,
  }) {
    return _subSessions(teamId, sessionId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => SubSession.fromFirestore(
                  doc,
                  teamId: teamId,
                  sessionId: sessionId,
                ),
              )
              .toList(growable: false),
        );
  }

  Stream<SubSession> watchSubSession({
    required String teamId,
    required String sessionId,
    required String subSessionId,
  }) {
    return _subSessions(teamId, sessionId)
        .doc(subSessionId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        throw StateError('Prova non trovata');
      }
      return SubSession.fromFirestore(
        doc,
        teamId: teamId,
        sessionId: sessionId,
      );
    });
  }

  Stream<List<Split>> watchSubSessionSplits({
    required String teamId,
    required String sessionId,
    required String subSessionId,
  }) {
    return _subSessionSplits(teamId, sessionId, subSessionId)
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

  Future<SubSession> createSubSession({
    required String teamId,
    required String sessionId,
    required String name,
    required SubSessionType type,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw SessionsException('Il nome della prova è obbligatorio.');
    }

    final docRef = _subSessions(teamId, sessionId).doc();
    final subSession = SubSession(
      id: docRef.id,
      teamId: teamId,
      sessionId: sessionId,
      name: trimmed,
      type: type,
      createdAt: DateTime.now(),
      finishedAthleteIds: const [],
    );

    await docRef.set(subSession.toFirestore());
    return subSession;
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
    required String subSessionId,
  }) {
    return _subSessions(teamId, sessionId).doc(subSessionId).update({
      'timerStartedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> startSimpleTimer({
    required String teamId,
    required String sessionId,
    required String subSessionId,
    required int baseElapsedMs,
  }) {
    return _subSessions(teamId, sessionId).doc(subSessionId).update({
      'timerStartedAt': FieldValue.serverTimestamp(),
      'timerElapsedMs': baseElapsedMs,
    });
  }

  Future<void> stopSimpleTimer({
    required String teamId,
    required String sessionId,
    required String subSessionId,
    required int elapsedMs,
  }) {
    return _subSessions(teamId, sessionId).doc(subSessionId).update({
      'timerStartedAt': FieldValue.delete(),
      'timerElapsedMs': elapsedMs,
    });
  }

  Future<void> endSubSession({
    required String teamId,
    required String sessionId,
    required String subSessionId,
    int? finalElapsedMs,
  }) {
    final updates = <String, dynamic>{
      'endedAt': FieldValue.serverTimestamp(),
      'timerStartedAt': FieldValue.delete(),
    };
    if (finalElapsedMs != null) {
      updates['timerElapsedMs'] = finalElapsedMs;
    }
    return _subSessions(teamId, sessionId).doc(subSessionId).update(updates);
  }

  Future<void> resetSubSession({
    required String teamId,
    required String sessionId,
    required String subSessionId,
  }) async {
    final splits = await _subSessionSplits(teamId, sessionId, subSessionId).get();
    final batch = _firestore.batch();
    for (final doc in splits.docs) {
      batch.delete(doc.reference);
    }
    batch.update(_subSessions(teamId, sessionId).doc(subSessionId), {
      'timerStartedAt': FieldValue.delete(),
      'timerElapsedMs': FieldValue.delete(),
      'finishedAthleteIds': [],
    });
    await batch.commit();
  }

  Future<void> recordSplit({
    required String teamId,
    required String sessionId,
    required String subSessionId,
    required String athleteId,
    required int elapsedMs,
    bool singleTapOnly = false,
  }) async {
    final splitsRef = _subSessionSplits(teamId, sessionId, subSessionId);
    final existing =
        await splitsRef.where('athleteId', isEqualTo: athleteId).get();

    if (singleTapOnly && existing.docs.isNotEmpty) {
      return;
    }

    final lapNumber = singleTapOnly ? 1 : existing.docs.length + 1;

    await splitsRef.add({
      'athleteId': athleteId,
      'lapNumber': lapNumber,
      'elapsedMs': elapsedMs,
      'recordedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAthleteFinished({
    required String teamId,
    required String sessionId,
    required String subSessionId,
    required String athleteId,
  }) {
    return _subSessions(teamId, sessionId).doc(subSessionId).update({
      'finishedAthleteIds': FieldValue.arrayUnion([athleteId]),
    });
  }

  Future<void> recordSimpleFinish({
    required String teamId,
    required String sessionId,
    required String subSessionId,
    required String athleteId,
    required int elapsedMs,
  }) async {
    await recordSplit(
      teamId: teamId,
      sessionId: sessionId,
      subSessionId: subSessionId,
      athleteId: athleteId,
      elapsedMs: elapsedMs,
      singleTapOnly: true,
    );
    await markAthleteFinished(
      teamId: teamId,
      sessionId: sessionId,
      subSessionId: subSessionId,
      athleteId: athleteId,
    );
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

  Future<void> deleteSubSession({
    required String teamId,
    required String sessionId,
    required String subSessionId,
  }) async {
    await _deleteSubcollection(
      _subSessionSplits(teamId, sessionId, subSessionId),
    );
    await _subSessions(teamId, sessionId).doc(subSessionId).delete();
  }

  Future<void> deleteSession({
    required String teamId,
    required String sessionId,
  }) async {
    final subSessions = await _subSessions(teamId, sessionId).get();
    for (final subSession in subSessions.docs) {
      await _deleteSubcollection(
        _subSessionSplits(teamId, sessionId, subSession.id),
      );
    }
    await _deleteSubcollection(_subSessions(teamId, sessionId));
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
