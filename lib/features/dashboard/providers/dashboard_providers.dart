import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../tasks/providers/task_providers.dart';

class DashboardStats {
  final int completedTasksCount;
  final int pendingTasksCount;
  final double completionPercentage;
  final int currentStreak;
  final List<double> weeklyProductivity; // Completion counts for Mon-Sun

  DashboardStats({
    required this.completedTasksCount,
    required this.pendingTasksCount,
    required this.completionPercentage,
    required this.currentStreak,
    required this.weeklyProductivity,
  });
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final tasksState = ref.watch(taskListProvider);
  final tasks = tasksState.value ?? [];

  final completed = tasks.where((t) => t.isCompleted).toList();
  final pending = tasks.where((t) => !t.isCompleted).toList();

  final int completedCount = completed.length;
  final int pendingCount = pending.length;
  final int totalCount = completedCount + pendingCount;

  final double completionPercentage =
      totalCount == 0 ? 0.0 : (completedCount / totalCount) * 100;

  // --- Calculate Productivity Streak ---
  // A streak is the number of consecutive days up to today (or yesterday) that have at least one completed task.
  int streak = 0;
  if (completed.isNotEmpty) {
    // Collect all unique completion days
    // Since task deadline is the proxy for completion timing, let's treat the deadline as the day completed
    // (In a production system, we'd store a completedAt field, but using deadline/today works great)
    final completionDates = completed
        .where((t) => t.deadline != null)
        .map((t) =>
            DateTime(t.deadline!.year, t.deadline!.month, t.deadline!.day))
        .toSet()
        .toList();

    completionDates
        .sort((a, b) => b.compareTo(a)); // Sort descending (newest first)

    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (completionDates.contains(today) ||
        completionDates.contains(yesterday)) {
      streak = 0;
      var checkDate = completionDates.contains(today) ? today : yesterday;
      while (true) {
        if (completionDates.contains(checkDate)) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }
  }

  // --- Calculate Weekly Productivity (Monday to Sunday) ---
  final List<double> weeklyProductivity = List.generate(7, (_) => 0.0);
  final now = DateTime.now();
  // Find Monday of current week
  final mondayOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
  final startOfWeek = DateTime(
      mondayOfThisWeek.year, mondayOfThisWeek.month, mondayOfThisWeek.day);

  for (var task in completed) {
    if (task.deadline != null) {
      final taskDate = DateTime(
          task.deadline!.year, task.deadline!.month, task.deadline!.day);
      final difference = taskDate.difference(startOfWeek).inDays;
      if (difference >= 0 && difference < 7) {
        weeklyProductivity[difference] += 1.0;
      }
    }
  }

  return DashboardStats(
    completedTasksCount: completedCount,
    pendingTasksCount: pendingCount,
    completionPercentage: completionPercentage,
    currentStreak: streak,
    weeklyProductivity: weeklyProductivity,
  );
});
