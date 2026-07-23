import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'core/services/db_service.dart';
import 'core/services/gemini_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';

import 'features/auth/providers/auth_session_provider.dart';
import 'features/auth/screens/login_screen.dart';

import 'features/dashboard/screens/main_shell.dart';
import 'features/settings/providers/settings_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize local storage
  await DatabaseService.init();

  // Initialize Gemini
  await GeminiService().init();

  // Initialize Notifications
  final notifications = NotificationService();
  await notifications.init();
  await notifications.requestPermissions();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authSessionProvider);
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'TaskNova AI Workspace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      home: authState.when(
        loading: () => const SplashScreen(),
        error: (error, stackTrace) {
          return Scaffold(
            body: Center(
              child: Text(
                "Authentication Error\n$error",
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
        data: (firebaseUser) {
          if (firebaseUser == null) {
            return const LoginScreen();
          }

          return const MainShell();
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bolt_rounded,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'TaskNova AI',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                minHeight: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
