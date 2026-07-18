import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/db_service.dart';
import '../models/task_model.dart';

class TaskRepository {
  final FirebaseFirestore? _firestore;

  TaskRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  bool get _useFirebase {
    try {
      return _firestore != null;
    } catch (_) {
      return false;
    }
  }

  // Fetch all tasks from Hive (with optional Firestore sync behind the scenes)
  Future<List<TaskModel>> getTasks(String userId) async {
    final box = DatabaseService.tasksBox;
    final localTasks = box.values
        .map((map) => TaskModel.fromMap(map))
        .where((task) => task.userId == userId)
        .toList();

    if (_useFirebase) {
      try {
        final snapshot = await _firestore!
            .collection('tasks')
            .where('userId', isEqualTo: userId)
            .get();
            
        final remoteTasks = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // Map document ID
          return TaskModel.fromMap(data);
        }).toList();

        // Sync remote to local Hive
        for (var task in remoteTasks) {
          await box.put(task.id, task.toMap());
        }

        return remoteTasks;
      } catch (_) {
        // Fallback silently to local cache on Firestore error
        return localTasks;
      }
    }
    return localTasks;
  }

  // Save/Update Task
  Future<void> saveTask(TaskModel task) async {
    // 1. Save to local database (Hive)
    await DatabaseService.tasksBox.put(task.id, task.toMap());

    // 2. Sync to firestore if online
    if (_useFirebase) {
      try {
        await _firestore!
            .collection('tasks')
            .doc(task.id)
            .set(task.toMap());
      } catch (_) {
        // Queue/sync later or fail silently
      }
    }
  }

  // Delete Task
  Future<void> deleteTask(String id) async {
    // 1. Delete from local database (Hive)
    await DatabaseService.tasksBox.delete(id);

    // 2. Delete from firestore if online
    if (_useFirebase) {
      try {
        await _firestore!.collection('tasks').doc(id).delete();
      } catch (_) {
        // Fail silently
      }
    }
  }
}
