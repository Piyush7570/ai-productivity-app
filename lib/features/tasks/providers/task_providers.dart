import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/task_model.dart';
import '../repositories/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  FirebaseFirestore? firestore;
  try {
    firestore = FirebaseFirestore.instance;
  } catch (_) {}
  return TaskRepository(firestore: firestore);
});

class TaskListNotifier extends StateNotifier<AsyncValue<List<TaskModel>>> {
  final TaskRepository _repository;
  final String _userId;

  TaskListNotifier(this._repository, this._userId) : super(const AsyncValue.loading()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      final tasks = await _repository.getTasks(_userId);
      state = AsyncValue.data(tasks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addTask({
    required String title,
    required String description,
    required TaskPriority priority,
    DateTime? deadline,
    required String category,
    required List<SubTask> subtasks,
    required RecurringType recurringType,
  }) async {
    final list = state.value ?? [];
    final newTask = TaskModel(
      id: const Uuid().v4(),
      userId: _userId,
      title: title,
      description: description,
      priority: priority,
      deadline: deadline,
      category: category,
      subtasks: subtasks,
      recurringType: recurringType,
    );

    state = AsyncValue.data([...list, newTask]);

    try {
      await _repository.saveTask(newTask);
      _scheduleReminders(newTask);
    } catch (e, stack) {
      // Revert state if error
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateTask(TaskModel updatedTask) async {
    final list = state.value ?? [];
    state = AsyncValue.data(
      list.map((t) => t.id == updatedTask.id ? updatedTask : t).toList(),
    );

    try {
      await _repository.saveTask(updatedTask);
      _scheduleReminders(updatedTask);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleTaskCompletion(String id) async {
    final list = state.value ?? [];
    final taskIndex = list.indexWhere((t) => t.id == id);
    if (taskIndex == -1) return;

    final task = list[taskIndex];
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);

    state = AsyncValue.data(
      list.map((t) => t.id == id ? updatedTask : t).toList(),
    );

    try {
      await _repository.saveTask(updatedTask);
      if (updatedTask.isCompleted) {
        // Cancel notification if completed
        final notificationId = id.hashCode;
        await NotificationService().cancelNotification(notificationId);
      } else {
        _scheduleReminders(updatedTask);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleSubtask(String taskId, String subTaskId) async {
    final list = state.value ?? [];
    final taskIndex = list.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = list[taskIndex];
    final updatedSubtasks = task.subtasks.map((st) {
      if (st.id == subTaskId) {
        return st.copyWith(isCompleted: !st.isCompleted);
      }
      return st;
    }).toList();

    final updatedTask = task.copyWith(subtasks: updatedSubtasks);

    state = AsyncValue.data(
      list.map((t) => t.id == taskId ? updatedTask : t).toList(),
    );

    try {
      await _repository.saveTask(updatedTask);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteTask(String id) async {
    final list = state.value ?? [];
    state = AsyncValue.data(list.where((t) => t.id != id).toList());

    try {
      await _repository.deleteTask(id);
      await NotificationService().cancelNotification(id.hashCode);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _scheduleReminders(TaskModel task) {
    if (task.deadline == null || task.isCompleted) return;
    
    final int notificationId = task.id.hashCode;
    
    // Schedule alarm 1 hour before deadline
    final remindTime = task.deadline!.subtract(const Duration(hours: 1));
    if (remindTime.isAfter(DateTime.now())) {
      NotificationService().scheduleNotification(
        id: notificationId,
        title: 'Task Deadline Approaching',
        body: '"${task.title}" is due in 1 hour!',
        scheduledDate: remindTime,
      );
    }
  }
}

final taskListProvider =
    StateNotifierProvider<TaskListNotifier, AsyncValue<List<TaskModel>>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final user = ref.watch(authControllerProvider).value;
  final userId = user?.uid ?? 'guest';
  return TaskListNotifier(repository, userId);
});
