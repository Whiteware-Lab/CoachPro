import 'package:coachpro/core/utils/email_utils.dart';
import 'package:coachpro/features/teams/domain/team.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeEmail lowercases and trims', () {
    expect(normalizeEmail('  Coach@Example.COM '), 'coach@example.com');
  });

  test('inviteDocumentId uses normalized email', () {
    expect(inviteDocumentId('Coach@Example.com'), 'coach@example.com');
  });

  test('Team.isCreator identifies creator', () {
    final team = Team(
      id: 't1',
      name: 'Test',
      createdBy: 'user1',
      coachIds: ['user1'],
      createdAt: DateTime(2026, 1, 1),
    );
    expect(team.isCreator('user1'), isTrue);
    expect(team.isCreator('user2'), isFalse);
  });
}
