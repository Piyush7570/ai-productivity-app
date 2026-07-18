import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/db_service.dart';
import 'core/services/gemini_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_providers.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/main_shell.dart';
import 'features/settings/providers/settings_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize local storage (Hive)
  await DatabaseService.init();

  // 2. Initialize Gemini API Client wrapper
  await GeminiService().init();

  // 3. Initialize Local Notifications reminders plugin
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
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch Auth state to toggle login/shell
    final authState = ref.watch(authControllerProvider);
    // Watch Theme state
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Antigravity AI Workspace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      home: authState.when(
        loading: () => const SplashScreen(),
        error: (err, stack) => Scaffold(
          body: Center(
            child: Text('Initialization Error: $err'),
          ),
        ),
        data: (user) {
          if (user != null) {
            return const MainShell();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

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
              'Antigravity AI',
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
              child: LinearProgressIndicator(minHeight: 2),
            ),
          ],
        ),
      ),
    );
  }
}
