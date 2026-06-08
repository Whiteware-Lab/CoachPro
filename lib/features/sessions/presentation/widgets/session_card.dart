import 'package:coachpro/app/theme/app_colors.dart';
import 'package:coachpro/core/utils/time_format.dart';
import 'package:coachpro/features/sessions/domain/session.dart';
import 'package:coachpro/features/sessions/domain/session_status.dart';
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
    final isActive = session.status == SessionStatus.active;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                isActive ? Icons.timer : Icons.check_circle_outline,
                color: isActive ? AppColors.secondary : AppColors.success,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${session.type.label} · '
                      '${session.presentAthleteIds.length} atleti · '
                      '${_formatDate(session.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (session.startedAt != null && session.endedAt != null)
                      Text(
                        'Durata: ${formatElapsedMs(session.endedAt!.difference(session.startedAt!).inMilliseconds)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              Chip(
                label: Text(isActive ? 'In corso' : 'Completata'),
                backgroundColor: isActive
                    ? AppColors.secondaryContainer
                    : AppColors.primaryContainer,
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
