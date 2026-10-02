import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coachpro/app/app.dart';
import 'package:coachpro/app/auth_bootstrap.dart';
import 'package:coachpro/app/theme/app_colors.dart';
import 'package:coachpro/app/theme/app_theme.dart';
import 'package:coachpro/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  String? _versionLabel;
  Object? _startupError;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final minimumSplashDuration = Future<void>.delayed(
      const Duration(milliseconds: 1200),
    );
    final versionFuture = _loadVersion();

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
      await Future.wait([minimumSplashDuration, versionFuture]);
      if (mounted) {
        setState(() => _isReady = true);
      }
    } catch (error) {
      await minimumSplashDuration;
      if (mounted) {
        setState(() => _startupError = error);
      }
    }
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform().timeout(
        const Duration(seconds: 2),
      );
      if (mounted) {
        setState(() {
          _versionLabel =
              'Versione ${packageInfo.version} (${packageInfo.buildNumber})';
        });
      }
    } catch (_) {
      // La versione non deve impedire l'avvio dell'app.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady) {
      return const AuthBootstrap(child: CoachProApp());
    }

    return MaterialApp(
      title: 'CoachPro',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: SplashScreen(
        versionLabel: _versionLabel,
        startupError: _startupError,
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({
    required this.versionLabel,
    this.startupError,
    super.key,
  });

  final String? versionLabel;
  final Object? startupError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Image.asset(
                'assets/images/logo.png',
                width: 220,
                height: 220,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              Text(
                'CoachPro',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Allenamenti e gare, sotto controllo.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (startupError == null)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Text(
                  'Impossibile avviare l’app. Controlla la connessione e riprova.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.error),
                ),
              const SizedBox(height: 16),
              AnimatedOpacity(
                opacity: versionLabel == null ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  versionLabel ?? 'Versione',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
