import 'package:coachpro/app/theme/app_colors.dart';
import 'package:coachpro/features/auth/providers/auth_providers.dart';
import 'package:coachpro/features/teams/data/teams_repository.dart';
import 'package:coachpro/features/teams/domain/team_invite.dart';
import 'package:coachpro/features/teams/providers/teams_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PendingInvitesBanner extends ConsumerWidget {
  const PendingInvitesBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(pendingInvitesProvider);

    return invitesAsync.when(
      data: (invites) {
        if (invites.isEmpty) {
          return const SizedBox.shrink();
        }
        return _PendingInvitesCard(invites: invites);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _PendingInvitesCard extends ConsumerStatefulWidget {
  const _PendingInvitesCard({required this.invites});

  final List<TeamInvite> invites;

  @override
  ConsumerState<_PendingInvitesCard> createState() =>
      _PendingInvitesCardState();
}

class _PendingInvitesCardState extends ConsumerState<_PendingInvitesCard> {
  bool _isProcessing = false;

  Future<void> _acceptAll() async {
    final user = ref.read(authStateProvider).value;
    if (user?.email == null) {
      return;
    }

    setState(() => _isProcessing = true);
    try {
      await ref.read(teamsRepositoryProvider).acceptAllPendingInvites(
            email: user!.email!,
            userId: user.uid,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inviti accettati')),
        );
      }
    } on TeamsException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.secondaryContainer,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.mail_outline, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text(
                  'Inviti in sospeso (${widget.invites.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...widget.invites.map(
              (invite) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('• ${invite.teamName}'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
              onPressed: _isProcessing ? null : _acceptAll,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Accetta tutti'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
