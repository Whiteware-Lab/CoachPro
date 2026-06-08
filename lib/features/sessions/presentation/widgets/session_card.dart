import 'package:coachpro/app/theme/app_colors.dart';
import 'package:coachpro/features/sessions/domain/session.dart';
import 'package:coachpro/features/sessions/domain/session_kind.dart';
import 'package:flutter/material.dart';

class SessionCard extends StatelessWidget {
  const SessionCard({
    required this.session,
    required this.onTap,
    super.key,
  });

  final Session session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isGara = session.kind == SessionKind.gara;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                isGara ? Icons.emoji_events : Icons.fitness_center,
                color: isGara ? AppColors.secondary : AppColors.primary,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.displayTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${session.presentAthleteIds.length} presenti',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
