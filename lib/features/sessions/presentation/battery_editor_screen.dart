import 'package:coachpro/app/theme/app_colors.dart';
import 'package:coachpro/features/athletes/providers/athletes_providers.dart';
import 'package:coachpro/features/sessions/data/sessions_repository.dart';
import 'package:coachpro/features/sessions/domain/battery.dart';
import 'package:coachpro/features/sessions/providers/sessions_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BatteryEditorScreen extends ConsumerStatefulWidget {
  const BatteryEditorScreen({
    required this.teamId,
    required this.sessionId,
    this.batteryId,
    super.key,
  });

  final String teamId;
  final String sessionId;
  final String? batteryId;

  @override
  ConsumerState<BatteryEditorScreen> createState() =>
      _BatteryEditorScreenState();
}

class _BatteryEditorScreenState extends ConsumerState<BatteryEditorScreen> {
  final _nameController = TextEditingController();
  final Set<String> _selectedIds = {};
  bool _initialized = false;
  bool _isSaving = false;

  SessionKey get _sessionKey =>
      SessionKey(teamId: widget.teamId, sessionId: widget.sessionId);

  BatteryKey? get _batteryKey => widget.batteryId == null
      ? null
      : BatteryKey(
          teamId: widget.teamId,
          sessionId: widget.sessionId,
          batteryId: widget.batteryId!,
        );

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final repository = ref.read(sessionsRepositoryProvider);
      if (widget.batteryId == null) {
        await repository.createBattery(
          teamId: widget.teamId,
          sessionId: widget.sessionId,
          name: _nameController.text,
          athleteIds: _selectedIds.toList(),
        );
      } else {
        await repository.updateBattery(
          teamId: widget.teamId,
          sessionId: widget.sessionId,
          batteryId: widget.batteryId!,
          name: _nameController.text,
          athleteIds: _selectedIds.toList(),
        );
      }
      if (mounted) {
        context.pop();
      }
    } on SessionsException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildEditor(
    BuildContext context,
    List<Battery> batteries,
    Battery? battery,
  ) {
    final athletesAsync = ref.watch(athletesProvider(widget.teamId));
    return athletesAsync.when(
      data: (athletes) {
        if (!_initialized) {
          _nameController.text =
              battery?.name ?? 'Batteria ${batteries.length + 1}';
          _selectedIds.addAll(battery?.athleteIds ?? const []);
          _initialized = true;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              battery == null ? 'Nuova batteria' : 'Modifica batteria',
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nome batteria',
                    prefixIcon: Icon(Icons.groups_outlined),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_selectedIds.length} selezionati',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: athletes.isEmpty
                          ? null
                          : () => setState(
                              () => _selectedIds
                                ..clear()
                                ..addAll(athletes.map((athlete) => athlete.id)),
                            ),
                      child: const Text('Tutti'),
                    ),
                    TextButton(
                      onPressed: () => setState(_selectedIds.clear),
                      child: const Text('Nessuno'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: athletes.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Aggiungi prima gli atleti alla squadra.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: athletes.length,
                        itemBuilder: (context, index) {
                          final athlete = athletes[index];
                          final selected = _selectedIds.contains(athlete.id);
                          return Card(
                            child: CheckboxListTile(
                              value: selected,
                              onChanged: (value) => setState(() {
                                if (value ?? false) {
                                  _selectedIds.add(athlete.id);
                                } else {
                                  _selectedIds.remove(athlete.id);
                                }
                              }),
                              title: Text(athlete.name),
                              subtitle: athlete.bibNumber == null
                                  ? null
                                  : Text('Pett. ${athlete.bibNumber}'),
                              secondary: CircleAvatar(
                                backgroundColor: selected
                                    ? AppColors.secondaryContainer
                                    : AppColors.primaryContainer,
                                foregroundColor: selected
                                    ? AppColors.secondary
                                    : AppColors.primary,
                                child: Text(athlete.name[0].toUpperCase()),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              battery == null
                                  ? 'Crea batteria'
                                  : 'Salva modifiche',
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Errore: $error')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final batteriesAsync = ref.watch(batteriesProvider(_sessionKey));
    final key = _batteryKey;
    final batteryAsync = key == null ? null : ref.watch(batteryProvider(key));

    return batteriesAsync.when(
      data: (batteries) {
        if (batteryAsync == null) {
          return _buildEditor(context, batteries, null);
        }
        return batteryAsync.when(
          data: (battery) => _buildEditor(context, batteries, battery),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Errore: $error')),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Errore: $error')),
      ),
    );
  }
}
