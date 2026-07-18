import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/db_service.dart';
import '../../../core/services/gemini_service.dart';
import '../../tasks/providers/task_providers.dart';
import '../../notes/providers/note_providers.dart';
import '../../schedule/providers/schedule_providers.dart';

class SettingsState {
  final ThemeMode themeMode;
  final String geminiApiKey;

  SettingsState({
    required this.themeMode,
    required this.geminiApiKey,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? geminiApiKey,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
      : super(SettingsState(themeMode: ThemeMode.dark, geminiApiKey: '')) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark') ?? true;
    final key = prefs.getString('gemini_api_key') ?? '';
    state = SettingsState(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      geminiApiKey: key,
    );
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final newIsDark = state.themeMode == ThemeMode.light;
    await prefs.setBool('is_dark', newIsDark);
    state = state.copyWith(
      themeMode: newIsDark ? ThemeMode.dark : ThemeMode.light,
    );
  }

  Future<void> updateApiKey(String key) async {
    await GeminiService().updateApiKey(key);
    state = state.copyWith(geminiApiKey: key);
  }

  // Backup data to JSON String
  String exportData() {
    final tasks = DatabaseService.tasksBox.values.toList();
    final notes = DatabaseService.notesBox.values.toList();
    final schedules = DatabaseService.schedulesBox.values.toList();

    final data = {
      'tasks': tasks,
      'notes': notes,
      'schedules': schedules,
    };

    return jsonEncode(data);
  }

  // Restore data from JSON String
  Future<void> importData(String jsonString) async {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

    if (decoded.containsKey('tasks')) {
      final tasks = decoded['tasks'] as List;
      await DatabaseService.tasksBox.clear();
      for (var t in tasks) {
        if (t is Map) {
          await DatabaseService.tasksBox.put(t['id'], t);
        }
      }
    }

    if (decoded.containsKey('notes')) {
      final notes = decoded['notes'] as List;
      await DatabaseService.notesBox.clear();
      for (var n in notes) {
        if (n is Map) {
          await DatabaseService.notesBox.put(n['id'], n);
        }
      }
    }

    if (decoded.containsKey('schedules')) {
      final schedules = decoded['schedules'] as List;
      await DatabaseService.schedulesBox.clear();
      for (var s in schedules) {
        if (s is Map) {
          await DatabaseService.schedulesBox.put(s['id'], s);
        }
      }
    }
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
