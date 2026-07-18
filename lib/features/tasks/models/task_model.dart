class SubTask {
  final String id;
  final String title;
  final bool isCompleted;

  SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  SubTask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory SubTask.fromMap(Map<dynamic, dynamic> map) {
    return SubTask(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }
}

enum TaskPriority { High, Medium, Low }

enum RecurringType { None, Daily, Weekly, Monthly }

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime? deadline;
  final String category;
  final bool isCompleted;
  final List<SubTask> subtasks;
  final RecurringType recurringType;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.priority,
    this.deadline,
    this.category = 'General',
    this.isCompleted = false,
    this.subtasks = const [],
    this.recurringType = RecurringType.None,
  });

  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? deadline,
    String? category,
    bool? isCompleted,
    List<SubTask>? subtasks,
    RecurringType? recurringType,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      deadline: deadline ?? this.deadline,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      subtasks: subtasks ?? this.subtasks,
      recurringType: recurringType ?? this.recurringType,
    );
  }

  factory TaskModel.fromMap(Map<dynamic, dynamic> map) {
    return TaskModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString().split('.').last == (map['priority'] ?? 'Medium'),
        orElse: () => TaskPriority.Medium,
      ),
      deadline: map['deadline'] != null ? DateTime.tryParse(map['deadline'].toString()) : null,
      category: map['category'] ?? 'General',
      isCompleted: map['isCompleted'] ?? false,
      subtasks: (map['subtasks'] as List? ?? [])
          .map((e) => SubTask.fromMap(e as Map))
          .toList(),
      recurringType: RecurringType.values.firstWhere(
        (e) => e.toString().split('.').last == (map['recurringType'] ?? 'None'),
        orElse: () => RecurringType.None,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'priority': priority.toString().split('.').last,
      'deadline': deadline?.toIso8601String(),
      'category': category,
      'isCompleted': isCompleted,
      'subtasks': subtasks.map((e) => e.toMap()).toList(),
      'recurringType': recurringType.toString().split('.').last,
    };
  }
}
