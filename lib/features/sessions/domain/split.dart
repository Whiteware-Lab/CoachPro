import 'package:cloud_firestore/cloud_firestore.dart';

class Split {
  const Split({
    required this.id,
    required this.athleteId,
    required this.lapNumber,
    required this.elapsedMs,
    required this.recordedAt,
    this.name,
  });

  final String id;
  final String athleteId;
  final int lapNumber;
  final int elapsedMs;
  final DateTime recordedAt;
  final String? name;

  String get displayName =>
      name?.trim().isNotEmpty == true ? name!.trim() : 'Giro $lapNumber';

  factory Split.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Split(
      id: doc.id,
      athleteId: data['athleteId'] as String,
      lapNumber: data['lapNumber'] as int,
      elapsedMs: data['elapsedMs'] as int,
      recordedAt: (data['recordedAt'] as Timestamp).toDate(),
      name: data['name'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'athleteId': athleteId,
      'lapNumber': lapNumber,
      'elapsedMs': elapsedMs,
      'recordedAt': Timestamp.fromDate(recordedAt),
      if (name != null) 'name': name,
    };
  }
}

class AthleteSessionStats {
  const AthleteSessionStats({
    required this.athleteId,
    required this.laps,
    required this.totalMs,
  });

  final String athleteId;
  final List<Split> laps;
  final int totalMs;

  int lapDurationMs(int index) {
    final previousElapsedMs = index == 0 ? 0 : laps[index - 1].elapsedMs;
    final duration = laps[index].elapsedMs - previousElapsedMs;
    return duration < 0 ? 0 : duration;
  }
}

List<AthleteSessionStats> buildAthleteStats(List<Split> splits) {
  final grouped = <String, List<Split>>{};
  for (final split in splits) {
    grouped.putIfAbsent(split.athleteId, () => []).add(split);
  }

  return grouped.entries.map((entry) {
    final laps = [...entry.value]
      ..sort((a, b) => a.lapNumber.compareTo(b.lapNumber));
    final totalMs = laps.isEmpty ? 0 : laps.last.elapsedMs;
    return AthleteSessionStats(
      athleteId: entry.key,
      laps: laps,
      totalMs: totalMs,
    );
  }).toList()..sort((a, b) => a.totalMs.compareTo(b.totalMs));
}
