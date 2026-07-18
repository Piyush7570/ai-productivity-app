import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_providers.dart';
import '../../tasks/providers/task_providers.dart';
import '../../notes/providers/note_providers.dart';
import '../../schedule/providers/schedule_providers.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _keyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _keyController.text = ref.read(settingsProvider).geminiApiKey;
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  void _saveApiKey() {
    final key = _keyController.text.trim();
    ref.read(settingsProvider.notifier).updateApiKey(key);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gemini API Key updated successfully!'), backgroundColor: AppColors.success),
    );
  }

  void _exportBackup() {
    try {
      final jsonBackup = ref.read(settingsProvider.notifier).exportData();
      Clipboard.setData(ClipboardData(text: jsonBackup));
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Backup Exported'),
          content: const Text(
            'Your tasks, notes, and schedules backup has been successfully copied to your clipboard as JSON data. Paste it somewhere safe!'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _importBackup() {
    final importController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Paste your exported JSON backup data here:'),
            const SizedBox(height: 8),
            TextField(
              controller: importController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '{"tasks":[], "notes":[], ...}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final jsonStr = importController.text.trim();
              Navigator.pop(ctx);
              if (jsonStr.isEmpty) return;

              try {
                await ref.read(settingsProvider.notifier).importData(jsonStr);
                // Trigger updates in other providers
                ref.read(taskListProvider.notifier).loadTasks();
                ref.read(noteListProvider.notifier).loadNotes();
                ref.read(scheduleProvider.notifier).loadSchedules();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup data restored successfully!'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Import failed: Invalid backup format. $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).value;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Profile Card
              GlassCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                      child: Icon(Icons.person_rounded, size: 36, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Guest User',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            user?.email ?? 'offline.guest@example.com',
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Settings Items List
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // Theme Switcher
                    SwitchListTile(
                      title: Text('Dark Theme Mode', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      value: settings.themeMode == ThemeMode.dark,
                      onChanged: (_) {
                        ref.read(settingsProvider.notifier).toggleTheme();
                      },
                    ),
                    const Divider(),
                    // Backup & Restore
                    ListTile(
                      title: Text('Export JSON Backup', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Copies your tasks and notes to clipboard'),
                      trailing: const Icon(Icons.copy_rounded),
                      onTap: _exportBackup,
                    ),
                    const Divider(),
                    ListTile(
                      title: Text('Import JSON Backup', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Restore backup from clipboard JSON String'),
                      trailing: const Icon(Icons.settings_backup_restore_rounded),
                      onTap: _importBackup,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // API Key Card
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Gemini API Credentials',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your API Key from Google AI Studio to unlock priority suggestion, note assistant, schedule draft generator, and writing models.',
                      style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _keyController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Gemini API Key',
                        prefixIcon: Icon(Icons.key_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _saveApiKey,
                      child: const Text('Save Key'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Logout Button
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).signOut();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withOpacity(0.1),
                  foregroundColor: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
