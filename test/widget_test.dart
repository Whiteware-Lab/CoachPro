import 'package:coachpro/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App theme uses CoachPro primary color', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Center(child: Text('CoachPro')),
        ),
      ),
    );

    final theme = Theme.of(
      tester.element(find.text('CoachPro')),
    );
    expect(theme.colorScheme.primary, const Color(0xFF1A56B0));
  });
}
