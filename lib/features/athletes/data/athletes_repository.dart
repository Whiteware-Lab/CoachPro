import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coachpro/features/athletes/domain/athlete.dart';

class AthletesRepository {
  AthletesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _athletes(String teamId) =>
      _firestore.collection('teams').doc(teamId).collection('athletes');

  Stream<List<Athlete>> watchAthletes(String teamId) {
    return _athletes(teamId)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(Athlete.fromFirestore)
              .where((athlete) => athlete.active)
              .toList(growable: false),
        );
  }

  Future<Athlete> createAthlete({
    required String teamId,
    required String name,
    String? bibNumber,
    String? notes,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw AthletesException('Il nome dell\'atleta è obbligatorio.');
    }

    final docRef = _athletes(teamId).doc();
    final athlete = Athlete(
      id: docRef.id,
      name: trimmedName,
      bibNumber: _normalizeOptional(bibNumber),
      notes: _normalizeOptional(notes),
      active: true,
      createdAt: DateTime.now(),
    );

    await docRef.set(athlete.toFirestore());
    return athlete;
  }

  Future<void> updateAthlete({
    required String teamId,
    required Athlete athlete,
    required String name,
    String? bibNumber,
    String? notes,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw AthletesException('Il nome dell\'atleta è obbligatorio.');
    }

    await _athletes(teamId).doc(athlete.id).update({
      'name': trimmedName,
      'bibNumber': _normalizeOptional(bibNumber),
      'notes': _normalizeOptional(notes),
    });
  }

  Future<void> deleteAthlete({
    required String teamId,
    required String athleteId,
  }) async {
    await _athletes(teamId).doc(athleteId).update({'active': false});
  }

  Future<void> deleteAllAthletes(String teamId) async {
    final snapshot = await _athletes(teamId).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  String? _normalizeOptional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}

class AthletesException implements Exception {
  AthletesException(this.message);
  final String message;

  @override
  String toString() => message;
}
