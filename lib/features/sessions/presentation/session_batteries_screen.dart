import 'package:coachpro/app/theme/app_colors.dart';
import 'package:coachpro/features/sessions/domain/battery.dart';
import 'package:coachpro/features/sessions/providers/sessions_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SessionBatteriesScreen extends ConsumerWidget {
  const SessionBatteriesScreen({
    required this.teamId,
    required this.sessionId,
    super.key,
  });

  final String teamId;
  final String sessionId;

  SessionKey get _sessionKey =>
      SessionKey(teamId: teamId, sessionId: sessionId);

  Future<void> _deleteBattery(
    BuildContext context,
    WidgetRef ref,
    Battery battery,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina batteria'),
        content: Text('Vuoi eliminare “${battery.name}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    await ref
        .read(sessionsRepositoryProvider)
        .deleteBattery(
          teamId: teamId,
          sessionId: sessionId,
          batteryId: battery.id,
        );
  }

  void _openNew(BuildContext context) {
    context.pushNamed(
      'battery-new',
      pathParameters: {'teamId': teamId, 'sessionId': sessionId},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batteriesAsync = ref.watch(batteriesProvider(_sessionKey));

    return Scaffold(
      appBar: AppBar(title: const Text('Batterie')),
      body: batteriesAsync.when(
        data: (batteries) {
          if (batteries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.groups_outlined,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nessuna batteria',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Crea una batteria e scegli gli atleti che vi partecipano.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _openNew(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Crea batteria'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: batteries.length,
            itemBuilder: (context, index) {
              final battery = batteries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.secondaryContainer,
                    foregroundColor: AppColors.secondary,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(battery.name),
                  subtitle: Text(
                    '${battery.athleteIds.length} '
                    '${battery.athleteIds.length == 1 ? 'partecipante' : 'partecipanti'}',
                  ),
                  onTap: () => context.pushNamed(
                    'battery-edit',
                    pathParameters: {
                      'teamId': teamId,
                      'sessionId': sessionId,
                      'batteryId': battery.id,
                    },
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        context.pushNamed(
                          'battery-edit',
                          pathParameters: {
                            'teamId': teamId,
                            'sessionId': sessionId,
                            'batteryId': battery.id,
                          },
                        );
                      } else if (value == 'delete') {
                        _deleteBattery(context, ref, battery);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Modifica'),
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
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Errore: $error')),
      ),
      floatingActionButton: batteriesAsync.value?.isNotEmpty == true
          ? FloatingActionButton.extended(
              onPressed: () => _openNew(context),
              icon: const Icon(Icons.add),
              label: const Text('Batteria'),
            )
          : null,
    );
  }
}
