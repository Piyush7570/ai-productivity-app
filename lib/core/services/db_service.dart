import 'package:hive_flutter/hive_flutter.dart';

class DatabaseService {
  static const String tasksBoxName = 'tasks_box';
  static const String notesBoxName = 'notes_box';
  static const String schedulesBoxName = 'schedules_box';
  static const String settingsBoxName = 'settings_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Open boxes to hold JSON Map data directly
    // This avoids dependency on build_runner code-generation, making compilation bulletproof.
    await Hive.openBox<Map>(tasksBoxName);
    await Hive.openBox<Map>(notesBoxName);
    await Hive.openBox<Map>(schedulesBoxName);
    await Hive.openBox<String>(settingsBoxName); // For key-value configurations like settings
  }

  // Get tasks box
  static Box<Map> get tasksBox => Hive.box<Map>(tasksBoxName);

  // Get notes box
  static Box<Map> get notesBox => Hive.box<Map>(notesBoxName);

  // Get schedules box
  static Box<Map> get schedulesBox => Hive.box<Map>(schedulesBoxName);

  // Get settings box
  static Box<String> get settingsBox => Hive.box<String>(settingsBoxName);
}
