import 'package:coachpro/features/athletes/domain/athlete.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Athlete.copyWith updates fields', () {
    final athlete = Athlete(
      id: 'a1',
      name: 'Luca Bianchi',
      bibNumber: '42',
      notes: 'Velocista',
      active: true,
      createdAt: DateTime(2026, 1, 1),
    );

    final updated = athlete.copyWith(name: 'Luca B.', bibNumber: '7');

    expect(updated.name, 'Luca B.');
    expect(updated.bibNumber, '7');
    expect(updated.notes, 'Velocista');
    expect(updated.active, isTrue);
  });
}
