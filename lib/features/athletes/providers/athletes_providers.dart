import 'package:coachpro/features/athletes/data/athletes_repository.dart';
import 'package:coachpro/features/athletes/domain/athlete.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final athletesRepositoryProvider = Provider<AthletesRepository>(
  (ref) => AthletesRepository(),
);

final athletesProvider =
    StreamProvider.family<List<Athlete>, String>((ref, teamId) {
  return ref.watch(athletesRepositoryProvider).watchAthletes(teamId);
});

final athleteCountProvider = Provider.family<int, String>((ref, teamId) {
  return ref.watch(athletesProvider(teamId)).maybeWhen(
        data: (athletes) => athletes.length,
        orElse: () => 0,
      );
});
