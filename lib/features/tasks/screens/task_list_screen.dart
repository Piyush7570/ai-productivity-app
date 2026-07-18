import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/services/gemini_service.dart';
import '../models/task_model.dart';
import '../providers/task_providers.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  String _selectedCategory = 'All';
  TaskPriority? _selectedPriority;
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasksState = ref.watch(taskListProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Add Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tasks',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Organize your daily targets',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  IconButton.filled(
                    onPressed: () => _showCreateTaskSheet(context),
                    icon: const Icon(Icons.add_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.brightness == Brightness.dark
                          ? AppColors.darkBg
                          : Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Filter Controls
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', _selectedCategory == 'All', (val) {
                      setState(() => _selectedCategory = 'All');
                    }),
                    _buildFilterChip('Work', _selectedCategory == 'Work',
                        (val) {
                      setState(() => _selectedCategory = 'Work');
                    }),
                    _buildFilterChip(
                        'Personal', _selectedCategory == 'Personal', (val) {
                      setState(() => _selectedCategory = 'Personal');
                    }),
                    _buildFilterChip('Study', _selectedCategory == 'Study',
                        (val) {
                      setState(() => _selectedCategory = 'Study');
                    }),
                    const SizedBox(width: 8),
                    Container(height: 24, width: 1, color: theme.dividerColor),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Completed',
                      _showCompleted,
                      (val) => setState(() => _showCompleted = !_showCompleted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tasks Content
              Expanded(
                child: tasksState.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) =>
                      Center(child: Text('Error loading tasks: $err')),
                  data: (tasks) {
                    // Filter tasks
                    final filteredTasks = tasks.where((task) {
                      final categoryMatch = _selectedCategory == 'All' ||
                          task.category == _selectedCategory;
                      final completionMatch =
                          task.isCompleted == _showCompleted;
                      return categoryMatch && completionMatch;
                    }).toList();

                    if (filteredTasks.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 64,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: 16),
                            Text(
                              'No tasks found',
                              style: GoogleFonts.outfit(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _showCompleted
                                  ? 'You haven\'t completed any tasks yet.'
                                  : 'Tap the + button to add a new task.',
                              style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        return _buildTaskItem(context, task);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      String label, bool isSelected, Function(bool) onSelected) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: onSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        showCheckmark: false,
        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.textTheme.bodyMedium?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, TaskModel task) {
    final theme = Theme.of(context);
    final priorityColor = task.priority == TaskPriority.High
        ? AppColors.priorityHigh
        : task.priority == TaskPriority.Medium
            ? AppColors.priorityMedium
            : AppColors.priorityLow;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Priority Circle
            Row(
              children: [
                Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) {
                    ref
                        .read(taskListProvider.notifier)
                        .toggleTaskCompletion(task.id);
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                Expanded(
                  child: Text(
                    task.title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.priority.name,
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 48.0),
                child: Text(
                  task.description,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],

            // Subtasks checklist
            if (task.subtasks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 48.0),
                child: Column(
                  children: task.subtasks.map((st) {
                    return Row(
                      children: [
                        Checkbox(
                          value: st.isCompleted,
                          onChanged: (_) {
                            ref
                                .read(taskListProvider.notifier)
                                .toggleSubtask(task.id, st.id);
                          },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        Expanded(
                          child: Text(
                            st.title,
                            style: TextStyle(
                              decoration: st.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 12),
            // Info Row: Deadline, Category, Recurrence, Delete Action
            Padding(
              padding: const EdgeInsets.only(left: 48.0),
              child: Row(
                children: [
                  if (task.deadline != null) ...[
                    Icon(Icons.calendar_month_outlined,
                        size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, h:mm a').format(task.deadline!),
                      style: TextStyle(
                          fontSize: 12, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Icon(Icons.folder_open_outlined,
                      size: 14, color: theme.textTheme.bodySmall?.color),
                  const SizedBox(width: 4),
                  Text(
                    task.category,
                    style: TextStyle(
                        fontSize: 12, color: theme.textTheme.bodySmall?.color),
                  ),
                  if (task.recurringType != RecurringType.None) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.replay_rounded,
                        size: 14, color: theme.colorScheme.secondary),
                    const SizedBox(width: 4),
                    Text(
                      task.recurringType.name,
                      style: TextStyle(
                          fontSize: 12, color: theme.colorScheme.secondary),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    onPressed: () =>
                        ref.read(taskListProvider.notifier).deleteTask(task.id),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: AppColors.error,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateTaskBottomSheet(),
    );
  }
}

class CreateTaskBottomSheet extends ConsumerStatefulWidget {
  const CreateTaskBottomSheet({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateTaskBottomSheet> createState() =>
      _CreateTaskBottomSheetState();
}

class _CreateTaskBottomSheetState extends ConsumerState<CreateTaskBottomSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subtaskController = TextEditingController();

  TaskPriority _priority = TaskPriority.Medium;
  RecurringType _recurringType = RecurringType.None;
  DateTime? _selectedDeadline;
  String _category = 'Work';
  final List<SubTask> _subtasks = [];
  bool _isAILoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  Future<void> _suggestPriority() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title first.')),
      );
      return;
    }

    if (!GeminiService().isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Gemini API is not configured. Please add your key in Settings.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isAILoading = true);
    try {
      final recommendedStr = await GeminiService().suggestPriority(
        title: title,
        description: description,
        deadline: _selectedDeadline,
      );

      final recommended = TaskPriority.values.firstWhere(
        (e) => e.name == recommendedStr,
        orElse: () => TaskPriority.Medium,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('AI Priority Suggestion'),
            content: Text(
                'AI suggests setting priority to "$recommendedStr" based on deadline & description.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => _priority = recommended);
                  Navigator.pop(ctx);
                },
                child: const Text('Accept'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI failure: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAILoading = false);
    }
  }

  void _addSubtask() {
    final title = _subtaskController.text.trim();
    if (title.isNotEmpty) {
      setState(() {
        _subtasks.add(SubTask(id: const Uuid().v4(), title: title));
        _subtaskController.clear();
      });
    }
  }

  Future<void> _pickDeadline() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDeadline = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? AppColors.darkBorder
              : AppColors.lightBorder,
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Create New Task',
            style:
                GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Title',
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Description
                  TextField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Row: Priority Suggestion & picker
                  Row(
                    children: [
                      Text('Priority: ',
                          style:
                              GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      ...TaskPriority.values.map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            label: Text(p.name),
                            selected: _priority == p,
                            onSelected: (selected) {
                              if (selected) setState(() => _priority = p);
                            },
                          ),
                        );
                      }).toList(),
                      const Spacer(),
                      // AI Suggester Chip
                      ActionChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _isAILoading
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5),
                                  )
                                : const Icon(Icons.bolt_rounded, size: 16),
                            const SizedBox(width: 6),
                            const Text('AI Suggest'),
                          ],
                        ),
                        onPressed: _isAILoading ? null : _suggestPriority,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Category & Recurrence
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration:
                              const InputDecoration(labelText: 'Category'),
                          items: ['Work', 'Personal', 'Study', 'General']
                              .map((c) =>
                                  DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _category = val ?? 'General'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<RecurringType>(
                          initialValue: _recurringType,
                          decoration:
                              const InputDecoration(labelText: 'Recurrence'),
                          items: RecurringType.values
                              .map((rt) => DropdownMenuItem(
                                  value: rt, child: Text(rt.name)))
                              .toList(),
                          onChanged: (val) => setState(
                              () => _recurringType = val ?? RecurringType.None),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pick Deadline Button
                  OutlinedButton.icon(
                    onPressed: _pickDeadline,
                    icon: const Icon(Icons.calendar_today_rounded),
                    label: Text(
                      _selectedDeadline == null
                          ? 'Set Deadline (Optional)'
                          : 'Due: ${DateFormat('MMM d, h:mm a').format(_selectedDeadline!)}',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subtasks Section
                  Text('Subtasks',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ..._subtasks.map((st) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          children: [
                            const Icon(Icons.subdirectory_arrow_right_rounded,
                                size: 16),
                            const SizedBox(width: 8),
                            Text(st.title),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                setState(() {
                                  _subtasks
                                      .removeWhere((item) => item.id == st.id);
                                });
                              },
                            ),
                          ],
                        ),
                      )),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subtaskController,
                          decoration: const InputDecoration(
                            labelText: 'Add Subtask...',
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addSubtask,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Save Button
          ElevatedButton(
            onPressed: () {
              if (_titleController.text.trim().isEmpty) return;

              ref.read(taskListProvider.notifier).addTask(
                    title: _titleController.text.trim(),
                    description: _descriptionController.text.trim(),
                    priority: _priority,
                    deadline: _selectedDeadline,
                    category: _category,
                    subtasks: _subtasks,
                    recurringType: _recurringType,
                  );
              Navigator.pop(context);
            },
            child: const Text('Save Task'),
          ),
        ],
      ),
    );
  }
}
