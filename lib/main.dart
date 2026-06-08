import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coachpro/app/app.dart';
import 'package:coachpro/app/auth_bootstrap.dart';
import 'package:coachpro/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  runApp(
    const ProviderScope(
      child: AuthBootstrap(
        child: CoachProApp(),
      ),
    ),
  );
}
