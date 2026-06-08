import 'package:coachpro/features/auth/providers/auth_providers.dart';
import 'package:coachpro/features/teams/providers/teams_providers.dart';
import 'package:coachpro/features/users/providers/user_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthBootstrap extends ConsumerStatefulWidget {
  const AuthBootstrap({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AuthBootstrap> createState() => _AuthBootstrapState();
}

class _AuthBootstrapState extends ConsumerState<AuthBootstrap> {
  String? _syncedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncUser(ref.read(authStateProvider).value);
    });
  }

  Future<void> _syncUser(User? user) async {
    if (user == null) {
      _syncedUserId = null;
      return;
    }
    if (_syncedUserId == user.uid) {
      return;
    }

    _syncedUserId = user.uid;
    final userRepository = ref.read(userRepositoryProvider);
    final teamsRepository = ref.read(teamsRepositoryProvider);

    await userRepository.syncUser(user);
    if (user.email != null) {
      await teamsRepository.acceptAllPendingInvites(
        email: user.email!,
        userId: user.uid,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      _syncUser(next.value);
    });

    return widget.child;
  }
}
