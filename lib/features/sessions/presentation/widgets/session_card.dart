import 'package:coachpro/app/theme/app_colors.dart';
import 'package:coachpro/features/sessions/domain/session.dart';
import 'package:coachpro/features/sessions/domain/session_kind.dart';
import 'package:flutter/material.dart';

class SessionCard extends StatelessWidget {
  const SessionCard({
    required this.session,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    super.key,
  });

  final Session session;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

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
                    if (session.hasCustomName) ...[
                      const SizedBox(height: 4),
                      Text(
                        session.defaultTitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Azioni sessione',
                onSelected: (value) {
                  if (value == 'rename') {
                    onRename();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'rename',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Rinomina'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.delete_outline),
                      title: Text('Elimina'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
